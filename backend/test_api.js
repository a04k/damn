const http = require('http');

// Get the first argument as email or use a default
const email = process.argv[2] || 'test@test.com';

const options = {
    hostname: 'localhost',
    port: 3000,
    path: `/api/users/${encodeURIComponent(email)}`,
    method: 'GET'
};

const req = http.request(options, (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
        try {
            const parsed = JSON.parse(data);
            console.log('API Response:');
            console.log(JSON.stringify(parsed, null, 2));

            if (parsed.user) {
                console.log('\n=== KEY FIELDS ===');
                console.log('isOnboardingComplete:', parsed.user.isOnboardingComplete, '(type:', typeof parsed.user.isOnboardingComplete + ')');
                console.log('enrolledCourses:', parsed.user.enrolledCourses);
            }
        } catch (e) {
            console.log('Raw response:', data);
        }
    });
});

req.on('error', (e) => {
    console.error('Error:', e.message);
});

req.end();
