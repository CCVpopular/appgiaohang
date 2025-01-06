import express from 'express';
import pool from '../index.js';

const router = express.Router();

// Get earnings summary for shipper
router.get('/shipper/:id', async (req, res) => {
  try {
    const shipperId = req.params.id;
    const today = new Date().toISOString().split('T')[0];
    const weekStart = new Date();
    weekStart.setDate(weekStart.getDate() - weekStart.getDay());
    const monthStart = new Date();
    monthStart.setDate(1);

    // Get earnings with only shipping fee (80%)
    const [totalResult] = await pool.query(
      `SELECT 
        SUM(o.shipping_fee * 0.8) as total
       FROM orders o 
       WHERE o.shipper_id = ? AND o.status = 'completed'`,
      [shipperId]
    );

    // Get today's earnings
    const [todayResult] = await pool.query(
      `SELECT 
        SUM(o.shipping_fee * 0.8) as total
       FROM orders o 
       WHERE o.shipper_id = ? 
       AND o.status = 'completed' 
       AND DATE(o.updated_at) = ?`,
      [shipperId, today]
    );

    // Get this week's earnings
    const [weekResult] = await pool.query(
      `SELECT 
        SUM(o.shipping_fee * 0.8) as total
       FROM orders o 
       WHERE o.shipper_id = ? 
       AND o.status = 'completed' 
       AND o.updated_at >= ?`,
      [shipperId, weekStart]
    );

    // Get this month's earnings
    const [monthResult] = await pool.query(
      `SELECT 
        SUM(o.shipping_fee * 0.8) as total
       FROM orders o 
       WHERE o.shipper_id = ? 
       AND o.status = 'completed' 
       AND o.updated_at >= ?`,
      [shipperId, monthStart]
    );

    // Get earnings history
    const [history] = await pool.query(
      `SELECT 
        o.id as orderId,
        o.updated_at as orderDate,
        o.shipping_fee,
        (o.shipping_fee * 0.8) as earnings
       FROM orders o
       WHERE o.shipper_id = ? 
       AND o.status = 'completed'
       ORDER BY o.updated_at DESC
       LIMIT 50`,
      [shipperId]
    );

    res.json({
      totalEarnings: totalResult[0].total || 0,
      todayEarnings: todayResult[0].total || 0,
      weekEarnings: weekResult[0].total || 0,
      monthEarnings: monthResult[0].total || 0,
      history: history.map(item => ({
        orderId: item.orderId,
        amount: item.earnings,
        shippingFee: item.shipping_fee * 0.8,
        date: item.orderDate,
      }))
    });
  } catch (error) {
    console.error('Earnings error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Add transaction for completed delivery
router.post('/delivery-complete', async (req, res) => {
  try {
    const { shipperId, orderId, amount } = req.body;

    await pool.query(
      'INSERT INTO transactions (user_id, amount, type, description, reference_id) VALUES (?, ?, "order_earning", "Earnings from delivery", ?)',
      [shipperId, amount, orderId]
    );

    res.json({ message: 'Earnings recorded successfully' });
  } catch (error) {
    console.error('Record earnings error:', error);
    res.status(500).json({ error: error.message });
  }
});

export default router;