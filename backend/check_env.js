require('dotenv').config();

console.log('--- Environment Check ---');
console.log(`Current Directory: ${process.cwd()}`);
console.log(`EMAILJS_PUBLIC_KEY: ${process.env.EMAILJS_PUBLIC_KEY ? '✅ Found (' + process.env.EMAILJS_PUBLIC_KEY.substring(0, 4) + '...)' : '❌ Missing'}`);
console.log(`EMAILJS_PRIVATE_KEY: ${process.env.EMAILJS_PRIVATE_KEY ? '✅ Found' : '❌ Missing'}`);
console.log(`EMAIL_USER: ${process.env.EMAIL_USER ? '✅ Found' : '❌ Missing'}`);
console.log(`EMAIL_PASS: ${process.env.EMAIL_PASS ? '✅ Found' : '❌ Missing'}`);
console.log('-------------------------');
