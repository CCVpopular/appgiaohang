import mysql from 'mysql2/promise';
import express from 'express';
import cors from 'cors';
import { createTables } from './database/tables.js';
import authRoutes from './routes/auth.js';

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
app.use(cors());
app.use(express.json());

// Add routes
app.use('/auth', authRoutes);

// Start server
const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

export default pool;
