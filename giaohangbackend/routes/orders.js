import express from 'express';
import pool from '../index.js';

const router = express.Router();

router.post('/', async (req, res) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const { userId, address, latitude, longitude, items, totalAmount, paymentMethod, note } = req.body;

    // Create order with coordinates
    const [orderResult] = await connection.query(
      'INSERT INTO orders (user_id, address, latitude, longitude, total_amount, payment_method, note) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [userId, address, latitude, longitude, totalAmount, paymentMethod, note]
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
      WHERE o.status = 'confirmed'
      GROUP BY o.id
      ORDER BY o.created_at DESC`
    );
    
    console.log('Fetched confirmed orders:', orders);
    res.json(orders);
  } catch (error) {
    console.error('Error fetching confirmed orders:', error);
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
    
    console.log('Fetched pending orders:', orders); // Add logging
    res.json(orders);
  } catch (error) {
    console.error('Error fetching pending orders:', error);
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

    console.log('Store orders query result:', orders);
    
    res.json(orders || []);
  } catch (error) {
    console.error('Error fetching store orders:', error);
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

export default router;