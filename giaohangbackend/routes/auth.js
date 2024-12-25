import express from 'express';
import bcrypt from 'bcrypt';
import cors from 'cors';
import pool from '../index.js';
import { sendOTP } from '../utils/emailService.js';

const router = express.Router();

// Store OTPs temporarily (in production, use Redis or similar)
const otpStore = new Map();

router.post('/send-otp', async (req, res) => {
  try {
    const { email } = req.body;
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Store OTP with 5 minute expiry
    otpStore.set(email, {
      otp,
      expiry: Date.now() + 5 * 60 * 1000
    });
    
    await sendOTP(email, otp);
    res.json({ message: 'OTP sent successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.post('/verify-otp', async (req, res) => {
  try {
    const { email, otp } = req.body;
    const storedOTPData = otpStore.get(email);
    
    if (!storedOTPData || storedOTPData.otp !== otp) {
      return res.status(400).json({ error: 'Invalid OTP' });
    }
    
    if (Date.now() > storedOTPData.expiry) {
      otpStore.delete(email);
      return res.status(400).json({ error: 'OTP expired' });
    }
    
    otpStore.delete(email);
    res.json({ message: 'OTP verified successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Modify the existing register endpoint
router.post('/register', async (req, res) => {
  try {
    const { email, password, fullName, phoneNumber, otp } = req.body;
    
    // Verify OTP
    const storedOTPData = otpStore.get(email);
    if (!storedOTPData || storedOTPData.otp !== otp) {
      return res.status(400).json({ error: 'Invalid or expired OTP' });
    }
    
    const hashedPassword = await bcrypt.hash(password, 10);
    
    const [result] = await pool.query(
      'INSERT INTO users (email, password, full_name, phone_number) VALUES (?, ?, ?, ?)',
      [email, hashedPassword, fullName, phoneNumber]
    );
    
    otpStore.delete(email); // Clear OTP after successful registration
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

// Update the route path to match the frontend request
router.post('/password/reset', async (req, res) => {
  try {
    console.log('Received reset password request:', req.body); // Debug log
    const { email, otp, newPassword } = req.body;
    
    // Validate input
    if (!email || !otp || !newPassword) {
      console.log('Missing required fields:', { email, otp, newPassword }); // Debug log
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Verify OTP
    const storedOTPData = otpStore.get(email);
    console.log('Stored OTP data:', storedOTPData); // Debug log
    
    if (!storedOTPData || storedOTPData.otp !== otp) {
      return res.status(400).json({ error: 'Invalid or expired OTP' });
    }

    // Check if user exists
    const [users] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
    if (users.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    
    const [result] = await pool.query(
      'UPDATE users SET password = ? WHERE email = ?',
      [hashedPassword, email]
    );

    if (result.affectedRows === 0) {
      throw new Error('Failed to update password');
    }
    
    otpStore.delete(email);
    console.log('Password reset successful'); // Debug log
    res.json({ message: 'Password reset successfully' });
  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({ error: error.message || 'Internal server error' });
  }
});

router.post('/change-password', async (req, res) => {
  try {
    console.log('Received change password request');
    const { userId, currentPassword, newPassword } = req.body;
    
    if (!userId || !currentPassword || !newPassword) {
      console.log('Missing required fields');
      return res.status(400).json({ error: 'Missing required fields' });
    }

    console.log('Fetching user with ID:', userId);
    const [users] = await pool.query('SELECT * FROM users WHERE id = ?', [userId]);
    
    if (users.length === 0) {
      console.log('User not found');
      return res.status(404).json({ error: 'User not found' });
    }
    
    const user = users[0];
    const validPassword = await bcrypt.compare(currentPassword, user.password);
    
    if (!validPassword) {
      console.log('Invalid current password');
      return res.status(401).json({ error: 'Current password is incorrect' });
    }
    
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    console.log('Updating password for user:', userId);
    
    const [result] = await pool.query(
      'UPDATE users SET password = ? WHERE id = ?',
      [hashedPassword, userId]
    );

    if (result.affectedRows === 0) {
      console.log('Password update failed');
      return res.status(500).json({ error: 'Failed to update password' });
    }
    
    console.log('Password changed successfully');
    res.json({ message: 'Password changed successfully' });
  } catch (error) {
    console.error('Error changing password:', error);
    res.status(500).json({ error: error.message || 'Internal server error' });
  }
});

export default router;