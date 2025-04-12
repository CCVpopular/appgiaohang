export const insertSampleData = async (pool) => {
  try {
    // Insert admin user
    await pool.query(`
      INSERT INTO users (email, password, full_name, phone_number, role, is_active, balance)
      VALUES ('admin@gmail.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Admin User', '0123456789', 'admin', true, 1000.00)
    `);

    // Insert shipper users
    await pool.query(`
      INSERT INTO users (email, password, full_name, phone_number, role, is_active, balance)
      VALUES 
        ('shipper1@gmail.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Shipper One', '0123456781', 'shipper', true, 500.00),
        ('shipper2@gmail.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Shipper Two', '0123456782', 'shipper', true, 500.00)
    `);

    // Insert regular users
    await pool.query(`
      INSERT INTO users (email, password, full_name, phone_number, role, is_active, balance)
      VALUES 
        ('user1@gmail.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'User One', '0123456783', 'user', true, 1000.00),
        ('user2@gmail.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'User Two', '0123456784', 'user', true, 1000.00)
    `);

    // Insert shipper profiles
    const [shippers] = await pool.query("SELECT id FROM users WHERE role = 'shipper'");
    
    for (const shipper of shippers) {
      await pool.query(`
        INSERT INTO shipper_profiles (user_id, vehicle_type, license_plate, status)
        VALUES (?, 'motorcycle', 'ABC-123', 'approved')
      `, [shipper.id]);
    }

    console.log('Sample data inserted successfully');
  } catch (error) {
    console.error('Error inserting sample data:', error);
    throw error;
  }
}; 