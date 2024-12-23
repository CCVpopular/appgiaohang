import express from 'express';
import bcrypt from 'bcrypt';
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

export default router;