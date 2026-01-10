const fs = require('fs');
const path = require('path');

const envPath = path.join(__dirname, '.env');

try {
    if (fs.existsSync(envPath)) {
        let content = fs.readFileSync(envPath, 'utf8');
        const original = content;

        // Insert newline before environment keys if they are stuck to previous line
        const keys = [
            'EMAILJS_PUBLIC_KEY', 'EMAILJS_PRIVATE_KEY',
            'EMAILJS_SERVICE_ID', 'EMAILJS_TEMPLATE_ID',
            'EMAIL_HOST', 'EMAIL_PORT', 'EMAIL_USER', 'EMAIL_PASS'
        ];

        keys.forEach(key => {
            // Look for key that isn't preceded by newline or start of string
            // We explicitly replace "anything+key=" with "anything\nkey="
            const regex = new RegExp(`([^\\n\\r])(${key}=)`, 'g');
            content = content.replace(regex, '$1\n$2');
        });

        if (content !== original) {
            fs.writeFileSync(envPath, content);
            console.log('✅ .env file formatting fixed (added missing newlines).');
        } else {
            console.log('ℹ️ .env formatting appears correct (or keys missing).');
        }
    } else {
        console.log('❌ .env file not found.');
    }
} catch (e) {
    console.error('Error fixing .env:', e);
}
