import express from 'express';
import pool from '../index.js';

const router = express.Router();

// Create new food item
router.post('/', async (req, res) => {
  try {
    const { name, description, price, storeId } = req.body;
    const [result] = await pool.query(
      'INSERT INTO foods (name, description, price, store_id) VALUES (?, ?, ?, ?)',
      [name, description, price, storeId]
    );
    res.status(201).json({ 
      id: result.insertId,
      name,
      description,
      price,
      storeId
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get foods by store ID
router.get('/store/:storeId', async (req, res) => {
  try {
    const [foods] = await pool.query(
      'SELECT * FROM foods WHERE store_id = ?',
      [req.params.storeId]
    );
    res.json(foods);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update food item
router.put('/:id', async (req, res) => {
  try {
    const { name, description, price } = req.body;
    await pool.query(
      'UPDATE foods SET name = ?, description = ?, price = ? WHERE id = ?',
      [name, description, price, req.params.id]
    );
    res.json({ id: req.params.id, name, description, price });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete food item
router.delete('/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM foods WHERE id = ?', [req.params.id]);
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

export default router;