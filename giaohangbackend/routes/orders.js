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

export default router;