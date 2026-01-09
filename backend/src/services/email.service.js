/**
 * Email Service using Nodemailer
 */
const nodemailer = require('nodemailer');
const logger = require('../utils/logger');

// Create transporter
const createTransporter = () => {
  return nodemailer.createTransport({
    host: process.env.EMAIL_HOST || 'smtp.gmail.com',
    port: parseInt(process.env.EMAIL_PORT) || 587,
    secure: false,
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS
    }
  });
};

let transporter = null;

/**
 * Get or create email transporter
 */
const getTransporter = () => {
  if (!transporter) {
    transporter = createTransporter();
  }
  return transporter;
};

/**
 * Send email
 */
const sendEmail = async ({ to, subject, text, html }) => {
  try {
    const info = await getTransporter().sendMail({
      from: `"College Guide" <${process.env.EMAIL_USER}>`,
      to,
      subject,
      text,
      html
    });

    logger.info(`📧 Email sent to ${to}: ${info.messageId}`);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    logger.error('Email send error:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Send verification code email
 */
const sendVerificationEmail = async (email, code, type = 'registration') => {
  const subjects = {
    registration: 'Verify Your Email - College Guide',
    password_reset: 'Reset Your Password - College Guide',
    email_change: 'Confirm Email Change - College Guide'
  };

  const messages = {
    registration: `Welcome to College Guide! Your verification code is: ${code}. This code expires in 15 minutes.`,
    password_reset: `Your password reset code is: ${code}. This code expires in 15 minutes.`,
    email_change: `Your email change confirmation code is: ${code}. This code expires in 15 minutes.`
  };

  return sendEmail({
    to: email,
    subject: subjects[type] || 'Verification Code - College Guide',
    text: messages[type] || `Your verification code is: ${code}`,
    html: `
      <!DOCTYPE html>
      <html>
        <head>
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }
            .container { max-width: 600px; margin: 0 auto; padding: 40px 20px; }
            .header { background: linear-gradient(135deg, #002147, #003A5D); padding: 30px; border-radius: 12px 12px 0 0; text-align: center; }
            .header h1 { color: #FDC800; margin: 0; font-size: 24px; }
            .content { background: #f8f9fa; padding: 30px; border-radius: 0 0 12px 12px; }
            .code { font-size: 36px; font-weight: bold; color: #002147; text-align: center; letter-spacing: 8px; padding: 20px; background: white; border-radius: 8px; margin: 20px 0; }
            .footer { text-align: center; color: #6b7280; font-size: 12px; margin-top: 20px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>College Guide</h1>
            </div>
            <div class="content">
              <p>Hello,</p>
              <p>${messages[type] || `Your verification code is:`}</p>
              <div class="code">${code}</div>
              <p>This code will expire in <strong>15 minutes</strong>.</p>
              <p>If you didn't request this, please ignore this email.</p>
            </div>
            <div class="footer">
              <p>© ${new Date().getFullYear()} College Guide. All rights reserved.</p>
            </div>
          </div>
        </body>
      </html>
    `
  });
};

/**
 * Send welcome email after registration
 */
const sendWelcomeEmail = async (email, name) => {
  return sendEmail({
    to: email,
    subject: 'Welcome to College Guide!',
    text: `Welcome ${name}! Your account has been created successfully. Start exploring your courses and schedule today.`,
    html: `
      <!DOCTYPE html>
      <html>
        <head>
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }
            .container { max-width: 600px; margin: 0 auto; padding: 40px 20px; }
            .header { background: linear-gradient(135deg, #002147, #003A5D); padding: 30px; border-radius: 12px 12px 0 0; text-align: center; }
            .header h1 { color: #FDC800; margin: 0; font-size: 24px; }
            .content { background: #f8f9fa; padding: 30px; border-radius: 0 0 12px 12px; }
            .footer { text-align: center; color: #6b7280; font-size: 12px; margin-top: 20px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>Welcome to College Guide!</h1>
            </div>
            <div class="content">
              <p>Hi ${name},</p>
              <p>Your account has been successfully created. You're now ready to:</p>
              <ul>
                <li>📚 Browse and enroll in courses</li>
                <li>📅 Manage your schedule</li>
                <li>📝 Track assignments and exams</li>
                <li>🔔 Get real-time notifications</li>
              </ul>
              <p>Get started by logging in to the app!</p>
            </div>
            <div class="footer">
              <p>© ${new Date().getFullYear()} College Guide. All rights reserved.</p>
            </div>
          </div>
        </body>
      </html>
    `
  });
};

module.exports = {
  sendEmail,
  sendVerificationEmail,
  sendWelcomeEmail
};
