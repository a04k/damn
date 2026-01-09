/**
 * Upload Routes (Cloudflare R2)
 */
const express = require('express');
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const multer = require('multer');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// R2 Configuration
const s3 = new S3Client({
  region: 'auto',
  endpoint: process.env.R2_ENDPOINT,
  credentials: {
    accessKeyId: process.env.R2_ACCESS_KEY_ID,
    secretAccessKey: process.env.R2_SECRET_ACCESS_KEY
  }
});

const R2_PUBLIC_URL = process.env.R2_PUBLIC_URL;
const BUCKET_NAME = process.env.R2_BUCKET_NAME || 'college-guide';

// Configure Multer (Memory Storage)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 50 * 1024 * 1024 // 50MB limit
  },
  fileFilter: (req, file, cb) => {
    // Allow images, pdfs, docs, videos
    const allowedTypes = /jpeg|jpg|png|gif|pdf|doc|docx|ppt|pptx|mp4|webm/;
    // Check mime type and ext
    // Simple regex check on mimetype
    if (allowedTypes.test(file.mimetype) || allowedTypes.test(file.originalname.toLowerCase())) {
        return cb(null, true);
    }
    cb(new Error('Invalid file type'));
  }
});

// Route: Upload single file to R2
router.post('/', authenticate, upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: 'No file uploaded' });
    }

    let key;
    const type = req.query.type;

    if (type === 'profile') {
      // Profile picture: profilepictures/{userId}-{timestamp}.ext
      const ext = req.file.originalname.split('.').pop() || 'jpg';
      key = `profilepictures/${req.user.id}-${Date.now()}.${ext}`;
    } else {
      // General upload: uploads/{timestamp}-{cleanName}
      const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
      const cleanName = req.file.originalname.replace(/[^a-zA-Z0-9.]/g, '_');
      key = `uploads/${uniqueSuffix}-${cleanName}`;
    }

    // Upload to R2
    const command = new PutObjectCommand({
      Bucket: BUCKET_NAME,
      Key: key,
      Body: req.file.buffer,
      ContentType: req.file.mimetype
    });

    await s3.send(command);

    const fileUrl = `${R2_PUBLIC_URL}/${key}`;

    res.json({
      success: true,
      fileUrl: fileUrl,
      fileName: req.file.originalname,
      mimeType: req.file.mimetype,
      size: req.file.size
    });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ success: false, message: 'File upload failed' });
  }
});

module.exports = router;
