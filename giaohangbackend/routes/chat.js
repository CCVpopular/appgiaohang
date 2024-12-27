import express from 'express';
import pool from '../index.js';

const router = express.Router();

// Send a message
router.post('/send', async (req, res) => {
  try {
    const { orderId, senderId, receiverId, message } = req.body;
    
    const [result] = await pool.query(
      `INSERT INTO chat_messages (order_id, sender_id, receiver_id, message) 
       VALUES (?, ?, ?, ?)`,
      [orderId, senderId, receiverId, message]
    );
    
    res.status(201).json({
      success: true,
      messageId: result.insertId
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get chat messages for an order
router.get('/order/:orderId', async (req, res) => {
  try {
    const [messages] = await pool.query(
      `SELECT 
        cm.*,
        u.full_name as sender_name
       FROM chat_messages cm
       JOIN users u ON cm.sender_id = u.id
       WHERE cm.order_id = ?
       ORDER BY cm.created_at ASC`,
      [req.params.orderId]
    );
    
    res.json(messages);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Mark messages as read
router.put('/read', async (req, res) => {
  try {
    const { orderId, userId } = req.body;
    
    await pool.query(
      `UPDATE chat_messages 
       SET is_read = true 
       WHERE order_id = ? AND receiver_id = ? AND is_read = false`,
      [orderId, userId]
    );
    
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

export default router;
