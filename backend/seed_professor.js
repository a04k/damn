const mysql = require('mysql2/promise');
require('dotenv').config();

const pool = mysql.createPool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    ssl: { rejectUnauthorized: false }
});

async function seedProfessor() {
    try {
        const email = 'doctor@university.edu';
        const password = 'password123';

        // Check if exists
        const [existing] = await pool.execute('SELECT * FROM users WHERE email = ?', [email]);
        if (existing.length > 0) {
            console.log('👨‍🏫 Professor account already exists.');
            process.exit(0);
        }

        const id = 'PROF' + Date.now();
        const avator = `https://ui-avatars.com/api/?name=Dr+Smith&background=random`;

        await pool.execute(`
            INSERT INTO users (id, name, email, password, avatar, mode, is_onboarding_complete, department)
            VALUES (?, 'Dr. Smith', ?, ?, ?, 'professor', TRUE, 'Computer Science')
        `, [id, email, password, avator]);

        console.log('✅ Professor account created!');
        console.log(`📧 Email: ${email}`);
        console.log(`🔑 Password: ${password}`);
    } catch (error) {
        console.error('❌ Error seeding professor:', error);
    } finally {
        pool.end();
    }
}

seedProfessor();
