import express from 'express';
import bcrypt from 'bcrypt';
import cors from 'cors';
import pool from '../index.js';

const router = express.Router();

router.post('/register', async (req, res) => {
  try {
    const { email, password, fullName, phoneNumber } = req.body;
    const hashedPassword = await bcrypt.hash(password, 10);
    
    const [result] = await pool.query(
      'INSERT INTO users (email, password, full_name, phone_number) VALUES (?, ?, ?, ?)',
      [email, hashedPassword, fullName, phoneNumber]
    );
    
    res.status(201).json({ message: 'User registered successfully', userId: result.insertId });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const [users] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
    
    if (users.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    const user = users[0];
    const validPassword = await bcrypt.compare(password, user.password);
    
    if (!validPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    res.json({ 
      id: user.id,
      email: user.email,
      fullName: user.full_name,
      role: user.role
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});


//Hàm lấy ra thông tin user dựa vào id
router.get('/user/:id', async (req, res) => {
  try {
    const { id } = req.params; // Lấy id từ URL
    const [users] = await pool.query('SELECT * FROM users WHERE id = ?', [id]);

    if (users.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const user = users[0];
    // Chỉ trả về các thông tin cần thiết (ẩn mật khẩu)
    res.json({
      id: user.id,
      email: user.email,
      fullName: user.full_name,
      phoneNumber: user.phone_number,
      role: user.role,
      createdAt: user.created_at,
      updatedAt: user.updated_at,
    });
  } catch (error) {
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

router.put('/user/:id', cors(), async (req, res) => {
  try {
    console.log('PUT request received:', {
      url: req.url,
      params: req.params,
      body: req.body
    });

    const { id } = req.params;
    const { fullName, phoneNumber } = req.body;
    
    if (!fullName || !phoneNumber) {
      return res.status(400).json({ error: 'Full name and phone number are required' });
    }

    const [result] = await pool.query(
      'UPDATE users SET full_name = ?, phone_number = ? WHERE id = ?',
      [fullName, phoneNumber, id]
    );

    console.log('Update result:', result);

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ message: 'Profile updated successfully' });
  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({ error: error.message || 'Internal Server Error' });
  }
});

export default router;