export const insertSampleData = async (pool) => {
  try {
    // Hash for password "123": $2a$10$ZM8H5mUHaHM9kzAGymTqVemtYqvEYKBXrUmx2hSwbSsx.TrVkQyiu
    const defaultPasswordHash = '$2a$10$ZM8H5mUHaHM9kzAGymTqVemtYqvEYKBXrUmx2hSwbSsx.TrVkQyiu';

    // Check if admin already exists
    const [adminExists] = await pool.query("SELECT COUNT(*) as count FROM users WHERE email = 'admin@gmail.com'");
    if (adminExists[0].count === 0) {
      await pool.query(`
        INSERT INTO users (email, password, full_name, phone_number, role, is_active, balance)
        VALUES ('admin@gmail.com', '${defaultPasswordHash}', 'Admin User', '0123456789', 'admin', true, 1000.00)
      `);
    }

    // Check if shippers exist
    const [shippersExist] = await pool.query("SELECT COUNT(*) as count FROM users WHERE email IN ('shipper1@gmail.com', 'shipper2@gmail.com')");
    if (shippersExist[0].count < 2) {
      await pool.query(`
        INSERT INTO users (email, password, full_name, phone_number, role, is_active, balance)
        VALUES 
          ('shipper1@gmail.com', '${defaultPasswordHash}', 'Shipper One', '0123456781', 'shipper', true, 500.00),
          ('shipper2@gmail.com', '${defaultPasswordHash}', 'Shipper Two', '0123456782', 'shipper', true, 500.00)
      `);
    }

    // Check if regular users exist
    const [usersExist] = await pool.query("SELECT COUNT(*) as count FROM users WHERE email IN ('user1@gmail.com', 'user2@gmail.com')");
    if (usersExist[0].count < 2) {
      await pool.query(`
        INSERT INTO users (email, password, full_name, phone_number, role, is_active, balance)
        VALUES 
          ('user1@gmail.com', '${defaultPasswordHash}', 'User One', '0123456783', 'user', true, 1000.00),
          ('user2@gmail.com', '${defaultPasswordHash}', 'User Two', '0123456784', 'user', true, 1000.00)
      `);
    }

    // Check and insert shipper profiles
    const [shippers] = await pool.query("SELECT id FROM users WHERE role = 'shipper'");
    
    for (const shipper of shippers) {
      const [profileExists] = await pool.query("SELECT COUNT(*) as count FROM shipper_profiles WHERE user_id = ?", [shipper.id]);
      if (profileExists[0].count === 0) {
        await pool.query(`
          INSERT INTO shipper_profiles (user_id, vehicle_type, license_plate, status)
          VALUES (?, 'motorcycle', 'ABC-123', 'approved')
        `, [shipper.id]);
      }
    }

    console.log('Sample data check completed');
  } catch (error) {
    console.error('Error handling sample data:', error);
    throw error;
  }
};