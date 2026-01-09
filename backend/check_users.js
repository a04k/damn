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

async function checkUsers() {
    try {
        const [users] = await pool.execute('SELECT email, is_onboarding_complete, enrolled_courses, major, department FROM users');

        console.log('=== USER ONBOARDING STATUS ===\n');

        if (users.length === 0) {
            console.log('No users found in database.');
        } else {
            users.forEach(user => {
                console.log(`Email: ${user.email}`);
                console.log(`  is_onboarding_complete: ${user.is_onboarding_complete} (type: ${typeof user.is_onboarding_complete})`);
                console.log(`  enrolled_courses: ${user.enrolled_courses || 'none'}`);
                console.log(`  major: ${user.major || 'not set'}`);
                console.log(`  department: ${user.department || 'not set'}`);
                console.log('');
            });
        }

        console.log('=== END ===');
    } catch (error) {
        console.error('Error:', error);
    } finally {
        await pool.end();
    }
}

checkUsers();
