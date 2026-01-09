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

async function resetProfessorSystem() {
    const connection = await pool.getConnection();

    try {
        console.log('🔄 Resetting Professor System...\n');

        // 1. Delete all professor accounts
        console.log('1️⃣ Deleting old professor accounts...');
        await connection.execute("DELETE FROM users WHERE mode = 'professor'");
        console.log('   ✅ Deleted\n');

        // 2. Clear doctor_courses table
        console.log('2️⃣ Clearing doctor-course assignments...');
        try {
            await connection.execute('DELETE FROM doctor_courses');
            console.log('   ✅ Cleared\n');
        } catch (e) {
            console.log('   ⚠️ Table may not exist yet\n');
        }

        // 3. Clear notifications
        console.log('3️⃣ Clearing notifications...');
        try {
            await connection.execute('DELETE FROM notifications');
            console.log('   ✅ Cleared\n');
        } catch (e) {
            console.log('   ⚠️ Table may not exist yet\n');
        }

        // 4. Clear course content
        console.log('4️⃣ Clearing course content...');
        try {
            await connection.execute('DELETE FROM course_content');
            console.log('   ✅ Cleared\n');
        } catch (e) {
            console.log('   ⚠️ Table may not exist yet\n');
        }

        // 5. Create new professor account
        console.log('5️⃣ Creating new professor account...');
        const profId = 'prof_' + Date.now();
        await connection.execute(`
            INSERT INTO users (id, name, email, password, mode, is_verified, is_onboarding_complete)
            VALUES (?, 'Dr. Ahmed Mohamed', 'dr.ahmed@university.edu', 'prof123', 'professor', TRUE, TRUE)
        `, [profId]);
        console.log('   ✅ Created: dr.ahmed@university.edu / prof123\n');

        // 6. Get all courses
        const [courses] = await connection.execute('SELECT id, code, name FROM courses LIMIT 10');
        console.log(`6️⃣ Found ${courses.length} courses to assign\n`);

        // 7. Assign first 10 courses to professor
        console.log('7️⃣ Assigning courses to professor...');
        for (const course of courses) {
            try {
                await connection.execute(`
                    INSERT INTO doctor_courses (doctor_email, course_id, is_primary)
                    VALUES ('dr.ahmed@university.edu', ?, FALSE)
                `, [course.id]);
                console.log(`   ✅ ${course.code} - ${course.name}`);
            } catch (e) {
                // Ignore duplicates
            }
        }

        console.log('\n========================================');
        console.log('✅ PROFESSOR SYSTEM RESET COMPLETE');
        console.log('========================================');
        console.log('\n📝 Professor Login Credentials:');
        console.log('   Email: dr.ahmed@university.edu');
        console.log('   Password: prof123');
        console.log(`\n📚 Courses Assigned: ${courses.length}`);
        console.log('========================================\n');

    } catch (error) {
        console.error('❌ Error:', error.message);
    } finally {
        connection.release();
        await pool.end();
    }
}

resetProfessorSystem();
