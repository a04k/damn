import PyPDF2
import os

pdf_path = os.path.join(os.path.dirname(__file__), '..', 'std guide.pdf')
output_path = os.path.join(os.path.dirname(__file__), 'pdf_content.txt')

try:
    with open(pdf_path, 'rb') as file:
        reader = PyPDF2.PdfReader(file)
        text = ''
        for page in reader.pages:
            text += page.extract_text() + '\n\n--- PAGE BREAK ---\n\n'
        
        with open(output_path, 'w', encoding='utf-8') as out:
            out.write(text)
        
        print(text)
        print(f'\n\nSaved to {output_path}')
except Exception as e:
    print(f'Error: {e}')
