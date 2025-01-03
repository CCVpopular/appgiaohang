import mysql from 'mysql2/promise';
import express from 'express';
import cors from 'cors';
import { createTables } from './database/tables.js';
import authRoutes from './routes/auth.js';
import storesRoutes from './routes/stores.js';
import foodsRoutes from './routes/foods.js';
import addressesRoutes from './routes/addresses.js';
import ordersRoutes from './routes/orders.js';
import usersRoutes from './routes/users.js';
import { Server } from 'socket.io';
import { createServer } from 'http';

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

// Register routes in correct order - users route should come before auth
app.use('/users', usersRoutes);
app.use('/auth', authRoutes);
app.use('/stores', storesRoutes);
app.use('/foods', foodsRoutes);
app.use('/addresses', addressesRoutes);
app.use('/orders', ordersRoutes);

// Update error handling middleware to exclude status-related errors
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
const server = createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

io.on('connection', (socket) => {
  socket.on('join-delivery-room', (connectionString) => {
    socket.join(connectionString);
    console.log(connectionString);
  });

  socket.on('shipper-location', (data) => {
    io.to(data.connectionString).emit('location-update', {
      latitude: data.latitude,
      longitude: data.longitude,
    });
    // console.log(data.connectionString);
    // console.log(data.latitude , data.longitude);
  });
});

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

export default pool;
