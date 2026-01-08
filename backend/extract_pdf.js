const fs = require('fs');
const path = require('path');
const pdfParse = require('pdf-parse');

const pdfPath = path.join(__dirname, '..', 'std guide.pdf');

async function extractPdf() {
    try {
        const dataBuffer = fs.readFileSync(pdfPath);
        const data = await pdfParse(dataBuffer);

        console.log('=== PDF TEXT CONTENT ===\n');
        console.log(data.text);
        console.log('\n=== END OF PDF ===');

        // Save to file for easier reading
        fs.writeFileSync(path.join(__dirname, 'pdf_content.txt'), data.text);
        console.log('\nSaved to backend/pdf_content.txt');
    } catch (error) {
        console.error('Error extracting PDF:', error);
    }
}

extractPdf();
