export const createTables = async (pool) => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id INT PRIMARY KEY AUTO_INCREMENT,
        password VARCHAR(255) NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        full_name VARCHAR(100),
        phone_number VARCHAR(15),
        role ENUM('admin', 'user', 'shipper') DEFAULT 'user',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    `);
    
    await pool.query(`
      CREATE TABLE IF NOT EXISTS food_stores (
        id INT PRIMARY KEY AUTO_INCREMENT,
        name VARCHAR(100) NOT NULL,
        address VARCHAR(255) NOT NULL,
        owner_id INT,
        phone_number VARCHAR(15),
        status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (owner_id) REFERENCES users(id)
      )
    `);
    
    await pool.query(`
      CREATE TABLE IF NOT EXISTS foods (
        id INT PRIMARY KEY AUTO_INCREMENT,
        name VARCHAR(100) NOT NULL,
        description TEXT,
        price DECIMAL(10,2) NOT NULL,
        store_id INT,
        is_available BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (store_id) REFERENCES food_stores(id)
      )
    `);
    console.log('Tables created successfully');
  } catch (error) {
    console.error('Error creating tables:', error);
    throw error;
  }
};