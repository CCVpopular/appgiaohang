import express from 'express';
import pool from '../index.js';
import CryptoJS from 'crypto-js';

const router = express.Router();

// Add ZaloPay configuration 
const config = {
  app_id: "2554",
  key1: "sdngKKJmqEMzvh5QQcdD2A9XBSKUNaYn",
  key2: "trMrHtvjo6myautxDUiAcYsVtaeQ8nhf",
  endpoint: "https://sb-openapi.zalopay.vn/v2/create"
};

// Add new endpoint to generate ZaloPay token
router.post('/create-zalopay-order', async (req, res) => {
  try {
    const { amount } = req.body;
    const embed_data = {};
    const items = [{}];
    const transID = Math.floor(Math.random() * 1000000);
    const order = {
      app_id: config.app_id,
      app_trans_id: `${moment().format('YYMMDD')}_${transID}`, // Format: 230812_123456
      app_user: "user123",
      app_time: Date.now(), // milliseconds
      item: JSON.stringify(items),
      embed_data: JSON.stringify(embed_data),
      amount: amount,
      description: `GiaoHang - Payment for the order #${transID}`,
      bank_code: "zalopayapp",
    };

    // appid|app_trans_id|appuser|amount|apptime|embeddata|item
    const data = config.app_id + "|" + order.app_trans_id + "|" + order.app_user + "|" + order.amount + "|" + order.app_time + "|" + order.embed_data + "|" + order.item;
    order.mac = CryptoJS.HmacSHA256(data, config.key1).toString();

    const response = await fetch(config.endpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(order)
    });

    const result = await response.json();
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

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