import mysql from 'mysql2/promise';
import express from 'express';
import cors from 'cors';
import { createTables } from './database/tables.js';
import authRoutes from './routes/auth.js';
import storesRoutes from './routes/stores.js';  // Add this import

//Cau hinh ket noi database
const dbConfig = {
  host: 'localhost',
  user: 'root',
  password: '', 
  database: 'giaohang_db'
};

const initializeDatabase = async () => {
  try {
    // First connect without database to create it if needed
    const connection = await mysql.createConnection({
      host: dbConfig.host,
      user: dbConfig.user,
      password: dbConfig.password
    });

    await connection.query(`CREATE DATABASE IF NOT EXISTS ${dbConfig.database}`);
    await connection.end();

    // Create connection pool with database selected
    const pool = mysql.createPool(dbConfig);
    
    // Test connection
    const [rows] = await pool.query('SELECT 1');
    console.log('Database connected successfully');
    
    // Initialize tables
    await createTables(pool);
    
    return pool;
  } catch (error) {
    console.error('Database connection failed:', error);
    throw error;
  }
};

// Initialize connection pool
const pool = await initializeDatabase();

const app = express();

// Configure CORS
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Accept']
}));

app.use(express.json());

// Add logging middleware to debug routes
app.use((req, res, next) => {
  console.log(`${req.method} ${req.url}`);
  next();
});

// Ensure auth routes are properly registered
app.use('/auth', authRoutes);
app.use('/stores', storesRoutes);

// Update error handling middleware to include more details
app.use((err, req, res, next) => {
  console.error('Error:', {
    method: req.method,
    url: req.url,
    error: err
  });
  
  if (err.code === 'ER_DUP_ENTRY') {
    return res.status(400).json({ 
      error: 'Email already registered' 
    });
  }
  
  res.status(500).json({ 
    error: err.message || 'Something went wrong!' 
  });
});

// Add 404 handler
app.use((req, res) => {
  console.log('404 for:', req.method, req.url);
  res.status(404).json({ error: 'Not found' });
});

// Start server
const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

export default pool;
