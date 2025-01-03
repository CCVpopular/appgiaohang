import express from 'express';
import pool from '../index.js';

const router = express.Router();

router.post('/', async (req, res) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    
    const { 
      userId, 
      address, 
      latitude, 
      longitude,
      store_address,
      store_latitude,
      store_longitude,
      items, 
      totalAmount, 
      paymentMethod, 
      note 
    } = req.body;

    // Validate required fields
    if (!userId || !address || !items || !totalAmount || !paymentMethod) {
      throw new Error('Missing required fields');
    }

    // Create order with all coordinates
    const [orderResult] = await connection.query(
      `INSERT INTO orders (
        user_id, address, latitude, longitude,
        store_address, store_latitude, store_longitude,
        total_amount, payment_method, note
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        userId, address, latitude || null, longitude || null,
        store_address, store_latitude || null, store_longitude || null,
        totalAmount, paymentMethod, note || null
      ]
    );

    const orderId = orderResult.insertId;

    // Create order items
    for (const item of items) {
      await connection.query(
        'INSERT INTO order_items (order_id, food_id, quantity, price, store_id) VALUES (?, ?, ?, ?, ?)',
        [orderId, item.foodId, item.quantity, item.price, item.storeId]
      );
    }

    await connection.commit();
    res.status(201).json({ 
      message: 'Order created successfully', 
      orderId 
    });

  } catch (error) {
    await connection.rollback();
    res.status(500).json({ error: error.message });
  } finally {
    connection.release();
  }
});

router.get('/user/:userId', async (req, res) => {
  try {
    const [orders] = await pool.query(
      `SELECT o.*, 
        JSON_ARRAYAGG(
          JSON_OBJECT(
            'foodId', oi.food_id,
            'quantity', oi.quantity,
            'price', oi.price,
            'storeId', oi.store_id
          )
        ) as items
      FROM orders o
      LEFT JOIN order_items oi ON o.id = oi.order_id
      WHERE o.user_id = ?
      GROUP BY o.id
      ORDER BY o.created_at DESC`,
      [req.params.userId]
    );
    
    res.json(orders);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get confirmed orders for shippers (Move this before other specific routes)
router.get('/confirmed', async (req, res) => {
  try {
    const [orders] = await pool.query(
      `SELECT 
        o.*,
        u.full_name as customer_name,
        u.phone_number as customer_phone,
        JSON_ARRAYAGG(
          JSON_OBJECT(
            'quantity', oi.quantity,
            'price', oi.price,
            'food_id', f.id,
            'food_name', f.name,
            'store_id', fs.id,
            'store_name', fs.name
          )
        ) as items
      FROM orders o
      INNER JOIN users u ON o.user_id = u.id
      INNER JOIN order_items oi ON o.id = oi.order_id
      INNER JOIN foods f ON oi.food_id = f.id
      INNER JOIN food_stores fs ON oi.store_id = fs.id
      WHERE o.status = 'confirmed'
      GROUP BY o.id
      ORDER BY o.created_at DESC`
    );
    
    res.json(orders);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get pending orders - make sure this is properly exposed
router.get('/pending', async (req, res) => {
  try {
    const [orders] = await pool.query(
      `SELECT o.*, 
        JSON_ARRAYAGG(
          JSON_OBJECT(
            'foodId', oi.food_id,
            'quantity', oi.quantity,
            'price', oi.price,
            'storeId', oi.store_id
          )
        ) as items
      FROM orders o
      LEFT JOIN order_items oi ON o.id = oi.order_id
      WHERE o.status = 'pending'
      GROUP BY o.id
      ORDER BY o.created_at DESC`
    );
    
    res.json(orders);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get store orders
router.get('/store/:storeId', async (req, res) => {
  try {
    const [orders] = await pool.query(
      `SELECT o.*, 
        JSON_ARRAYAGG(
          JSON_OBJECT(
            'foodId', oi.food_id,
            'quantity', oi.quantity,
            'price', oi.price,
            'storeId', oi.store_id
          )
        ) as items
      FROM orders o
      INNER JOIN order_items oi ON o.id = oi.order_id
      WHERE oi.store_id = ?
      GROUP BY o.id, o.user_id, o.address, o.total_amount, o.status,
               o.payment_method, o.note, o.created_at, o.updated_at
      ORDER BY o.created_at DESC`,
      [req.params.storeId]
    );
    
    res.json(orders || []);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Store reviews order
router.put('/:orderId/review', async (req, res) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const { status } = req.body;
    const orderId = req.params.orderId;

    // Update order status based on store's decision
    const newStatus = status === 'accepted' ? 'confirmed' : 'cancelled';
    
    await connection.query(
      'UPDATE orders SET status = ? WHERE id = ?',
      [newStatus, orderId]
    );

    if (status === 'accepted') {
      // Create notification for shippers only if accepted
      await connection.query(
        'INSERT INTO shipper_notifications (order_id, status) VALUES (?, "pending")',
        [orderId]
      );
    }

    await connection.commit();
    res.json({ 
      message: 'Order review updated successfully',
      newStatus: newStatus 
    });
  } catch (error) {
    await connection.rollback();
    res.status(500).json({ error: error.message });
  } finally {
    connection.release();
  }
});

// Accept order by shipper
router.post('/:orderId/accept', async (req, res) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const { shipperId } = req.body;
    const orderId = req.params.orderId;

    // First check if shipper exists and has correct role
    const [shipperCheck] = await connection.query(
      'SELECT id, role FROM users WHERE id = ?',
      [shipperId]
    );

    if (!shipperCheck.length) {
      throw new Error('Shipper not found');
    }

    if (shipperCheck[0].role !== 'shipper') {
      // If user exists but doesn't have shipper role, update it
      await connection.query(
        'UPDATE users SET role = "shipper" WHERE id = ?',
        [shipperId]
      );
    }

    // Check if order exists and is available
    const [orderCheck] = await connection.query(
      'SELECT id, status FROM orders WHERE id = ?',
      [orderId]
    );

    if (!orderCheck.length) {
      throw new Error('Order not found');
    }

    if (orderCheck[0].status !== 'confirmed') {
      throw new Error(`Order cannot be accepted. Current status: ${orderCheck[0].status}`);
    }

    // Update order status and assign shipper
    await connection.query(
      `UPDATE orders 
       SET status = "preparing", 
           shipper_id = ?,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = ?`,
      [shipperId, orderId]
    );

    await connection.commit();
    res.json({ 
      success: true,
      message: 'Order accepted successfully',
      orderId: orderId 
    });

  } catch (error) {
    await connection.rollback();
    res.status(400).json({ 
      success: false,
      error: error.message 
    });
  } finally {
    connection.release();
  }
});

// Start delivery route
router.put('/:orderId/start-delivery', async (req, res) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const orderId = req.params.orderId;
    const { shipperId } = req.body;

    // Validate request
    if (!shipperId) {
      throw new Error('Shipper ID is required');
    }

    // Check if order exists and belongs to this shipper
    const [orderCheck] = await connection.query(
      'SELECT id, status, shipper_id FROM orders WHERE id = ?',
      [orderId]
    );

    if (!orderCheck.length) {
      throw new Error('Order not found');
    }

    if (orderCheck[0].shipper_id != shipperId) {
      throw new Error('Unauthorized: Order belongs to different shipper');
    }

    if (orderCheck[0].status !== 'preparing') {
      throw new Error(`Cannot start delivery. Current status: ${orderCheck[0].status}`);
    }

    // Update order status to delivering
    await connection.query(
      'UPDATE orders SET status = "delivering" WHERE id = ? AND shipper_id = ?',
      [orderId, shipperId]
    );

    await connection.commit();
    res.json({ 
      success: true,
      message: 'Delivery started successfully'
    });

  } catch (error) {
    await connection.rollback();
    res.status(400).json({ 
      success: false,
      error: error.message 
    });
  } finally {
    connection.release();
  }
});

// Complete delivery route
router.put('/:orderId/complete-delivery', async (req, res) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const orderId = req.params.orderId;
    const { shipperId } = req.body;

    // Validate request
    if (!shipperId) {
      throw new Error('Shipper ID is required');
    }

    // Check if order exists and belongs to this shipper
    const [orderCheck] = await connection.query(
      'SELECT id, status, shipper_id FROM orders WHERE id = ?',
      [orderId]
    );

    if (!orderCheck.length) {
      throw new Error('Order not found');
    }

    if (orderCheck[0].shipper_id != shipperId) {
      throw new Error('Unauthorized: Order belongs to different shipper');
    }

    if (orderCheck[0].status !== 'delivering') {
      throw new Error(`Cannot complete delivery. Current status: ${orderCheck[0].status}`);
    }

    // Update order status to completed
    await connection.query(
      'UPDATE orders SET status = "completed" WHERE id = ? AND shipper_id = ?',
      [orderId, shipperId]
    );

    await connection.commit();
    res.json({ 
      success: true,
      message: 'Delivery completed successfully'
    });

  } catch (error) {
    await connection.rollback();
    res.status(400).json({ 
      success: false,
      error: error.message 
    });
  } finally {
    connection.release();
  }
});

// Get shipper's active deliveries
router.get('/shipper/:shipperId/active', async (req, res) => {
  try {
    const [orders] = await pool.query(
      `SELECT 
        o.*,
        u.full_name as customer_name,
        u.phone_number as customer_phone,
        JSON_ARRAYAGG(
          JSON_OBJECT(
            'quantity', oi.quantity,
            'price', oi.price,
            'food_name', f.name,
            'store_name', fs.name,
            'store_address', fs.address,
            'store_phone', fs.phone_number
          )
        ) as items
      FROM orders o
      INNER JOIN users u ON o.user_id = u.id
      INNER JOIN order_items oi ON o.id = oi.order_id
      INNER JOIN foods f ON oi.food_id = f.id
      INNER JOIN food_stores fs ON oi.store_id = fs.id
      WHERE o.shipper_id = ? 
      AND o.status IN ('preparing', 'delivering')
      GROUP BY o.id
      ORDER BY o.created_at DESC`,
      [req.params.shipperId]
    );
    
    res.json(orders);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

export default router;