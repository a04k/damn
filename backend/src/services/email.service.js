/**
 * Email Service using Nodemailer (Production Ready)
 */
const nodemailer = require('nodemailer');
const logger = require('../utils/logger');
require('dotenv').config();

// ===============================
// Create Nodemailer Transporter
// ===============================
const transporter = nodemailer.createTransport({
  host: process.env.EMAIL_HOST,
  port: Number(process.env.EMAIL_PORT),
  secure: false, // true for 465, false for 587
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

// Verify transporter on startup
transporter.verify((error) => {
  if (error) {
    logger.error('❌ Email transporter error:', error);
  } else {
    logger.info('✅ Email transporter is ready');
  }
});

// ===============================
// Base Send Email Function
// ===============================
const sendEmail = async ({ to, subject, text, html }) => {
  if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
    logger.error('❌ Email configuration missing');
    return { success: false, error: 'Email configuration missing' };
  }

  try {
    const info = await transporter.sendMail({
      from: `"College Guide" <${process.env.EMAIL_USER}>`,
      to,
      subject,
      text,
      html,
    });

    logger.info(`✅ Email sent to ${to} (${info.messageId})`);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    logger.error('❌ Email send failed:', error);
    return { success: false, error: error.message };
  }
};

// ===============================
// Send Verification Email
// ===============================
const sendVerificationEmail = async (email, code, type = 'registration') => {
  const subjects = {
    registration: 'Verify Your Email - College Guide',
    password_reset: 'Reset Your Password - College Guide',
    email_change: 'Confirm Email Change - College Guide',
  };

  const messages = {
    registration: `Welcome to College Guide! Your verification code is: ${code}.`,
    password_reset: `Your password reset code is: ${code}.`,
    email_change: `Your email change verification code is: ${code}.`,
  };

  return sendEmail({
    to: email,
    subject: subjects[type] || 'Verification Code - College Guide',
    text: `${messages[type]} This code expires in 15 minutes.`,
    html: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8" />
  <style>
    body {
      font-family: Arial, sans-serif;
      background-color: #f3f4f6;
      padding: 20px;
    }
    .container {
      max-width: 600px;
      margin: auto;
      background: #ffffff;
      border-radius: 10px;
      overflow: hidden;
    }
    .header {
      background: #002147;
      padding: 25px;
      text-align: center;
      color: #FDC800;
      font-size: 22px;
      font-weight: bold;
    }
    .content {
      padding: 30px;
      color: #111827;
    }
    .code {
      font-size: 32px;
      font-weight: bold;
      letter-spacing: 6px;
      text-align: center;
      margin: 25px 0;
      color: #002147;
    }
    .footer {
      font-size: 12px;
      text-align: center;
      color: #6b7280;
      padding: 20px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">College Guide</div>
    <div class="content">
      <p>Hello,</p>
      <p>${messages[type]}</p>
      <div class="code">${code}</div>
      <p>This code will expire in <strong>15 minutes</strong>.</p>
      <p>If you did not request this, please ignore this email.</p>
    </div>
    <div class="footer">
      © ${new Date().getFullYear()} College Guide. All rights reserved.
    </div>
  </div>
</body>
</html>
`,
  });
};

// ===============================
// Send Welcome Email
// ===============================
const sendWelcomeEmail = async (email, name) => {
  return sendEmail({
    to: email,
    subject: 'Welcome to College Guide 🎓',
    text: `Welcome ${name}! Your account has been created successfully.`,
    html: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8" />
</head>
<body style="font-family: Arial; background:#f3f4f6; padding:20px;">
  <div style="max-width:600px; background:#fff; margin:auto; padding:30px; border-radius:10px;">
    <h2 style="color:#002147;">Welcome ${name} 🎉</h2>
    <p>Your account has been created successfully.</p>
    <ul>
      <li>📚 Browse courses</li>
      <li>📅 Manage your schedule</li>
      <li>📝 Track assignments</li>
      <li>🔔 Get notifications</li>
    </ul>
    <p>We’re happy to have you with us!</p>
    <p style="font-size:12px;color:#6b7280;">
      © ${new Date().getFullYear()} College Guide
    </p>
  </div>
</body>
</html>
`,
  });
};

module.exports = {
  sendEmail,
  sendVerificationEmail,
  sendWelcomeEmail,
};
