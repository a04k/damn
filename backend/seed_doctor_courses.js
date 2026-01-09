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

async function seedDoctorCourses() {
    const connection = await pool.getConnection();

    try {
        console.log('🌱 Seeding doctor-course relationships...\n');

        // First, let's find all professors in the system
        const [professors] = await connection.execute(
            "SELECT email, name FROM users WHERE mode = 'professor'"
        );

        console.log(`Found ${professors.length} professors:`);
        professors.forEach(p => console.log(`  - ${p.name} (${p.email})`));

        // Get all courses
        const [courses] = await connection.execute('SELECT id, code, name FROM courses');
        console.log(`\nFound ${courses.length} courses\n`);

        if (professors.length === 0) {
            console.log('No professors found. Creating a sample professor...');

            // Create a professor account if none exists
            await connection.execute(`
                INSERT INTO users (id, name, email, password, mode, is_verified, is_onboarding_complete)
                VALUES (?, ?, ?, ?, 'professor', TRUE, TRUE)
                ON DUPLICATE KEY UPDATE mode = 'professor'
            `, ['prof1', 'Dr. Ahmed', 'professor@university.edu', 'prof123']);

            professors.push({ email: 'professor@university.edu', name: 'Dr. Ahmed' });
            console.log('Created professor: professor@university.edu (password: prof123)\n');
        }

        // Clear existing doctor-course assignments
        await connection.execute('DELETE FROM doctor_courses');
        console.log('Cleared existing doctor-course assignments\n');

        // Assign courses to professors
        // Distribute courses among professors
        let courseIndex = 0;
        const assignmentsPerProfessor = Math.ceil(courses.length / professors.length);

        for (const professor of professors) {
            const professorCourses = courses.slice(courseIndex, courseIndex + assignmentsPerProfessor);

            for (let i = 0; i < professorCourses.length; i++) {
                const course = professorCourses[i];
                const isPrimary = i === 0; // First course is primary

                await connection.execute(`
                    INSERT INTO doctor_courses (doctor_email, course_id, is_primary)
                    VALUES (?, ?, ?)
                `, [professor.email, course.id, isPrimary]);

                console.log(`  Assigned ${course.code} to ${professor.name} ${isPrimary ? '(primary)' : ''}`);
            }

            courseIndex += assignmentsPerProfessor;
        }

        // Also check if any user emails look like professors and assign them courses
        const [potentialProfs] = await connection.execute(`
            SELECT email, name FROM users 
            WHERE (email LIKE '%doctor%' OR email LIKE '%prof%' OR email LIKE '%dr.%')
            AND mode != 'professor'
        `);

        if (potentialProfs.length > 0) {
            console.log('\n📝 Found potential professors (updating mode):');
            for (const prof of potentialProfs) {
                await connection.execute(
                    "UPDATE users SET mode = 'professor' WHERE email = ?",
                    [prof.email]
                );
                console.log(`  Updated ${prof.email} to professor mode`);

                // Assign first 5 courses to this professor
                for (let i = 0; i < Math.min(5, courses.length); i++) {
                    await connection.execute(`
                        INSERT INTO doctor_courses (doctor_email, course_id, is_primary)
                        VALUES (?, ?, ?)
                        ON DUPLICATE KEY UPDATE is_primary = is_primary
                    `, [prof.email, courses[i].id, i === 0]);
                }
            }
        }

        console.log('\n✅ Doctor-course seeding complete!');

        // Show summary
        const [summary] = await connection.execute(`
            SELECT dc.doctor_email, COUNT(*) as course_count 
            FROM doctor_courses dc 
            GROUP BY dc.doctor_email
        `);

        console.log('\n📊 Summary:');
        summary.forEach(s => {
            console.log(`  ${s.doctor_email}: ${s.course_count} courses`);
        });

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        connection.release();
        await pool.end();
    }
}

seedDoctorCourses();
