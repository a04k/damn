/**
 * Push Notification Service using Firebase Cloud Messaging
 */
const admin = require('firebase-admin');
const { prisma } = require('../utils/database');
const logger = require('../utils/logger');

// Initialize Firebase Admin SDK
let firebaseApp = null;

const initializeFirebase = () => {
  if (firebaseApp) return firebaseApp;

  try {
    if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL) {
      firebaseApp = admin.initializeApp({
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL
        })
      });
      logger.info('✅ Firebase Admin initialized');
    } else {
      logger.warn('⚠️ Firebase credentials not configured - push notifications disabled');
    }
  } catch (error) {
    logger.error('❌ Firebase initialization failed:', error);
  }

  return firebaseApp;
};

// Initialize on module load
initializeFirebase();

/**
 * Send push notification to a single user
 */
const sendToUser = async (userId, notification) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { fcmToken: true }
    });

    if (!user?.fcmToken) {
      logger.debug(`No FCM token for user ${userId}`);
      return { success: false, reason: 'no_token' };
    }

    return await sendToToken(user.fcmToken, notification);
  } catch (error) {
    logger.error('Error sending push to user:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Send push notification to a specific FCM token
 */
const sendToToken = async (token, notification) => {
  if (!firebaseApp) {
    logger.debug('Firebase not initialized, skipping push');
    return { success: false, reason: 'firebase_not_initialized' };
  }

  try {
    const message = {
      notification: {
        title: notification.title,
        body: notification.body
      },
      data: notification.data || {},
      token
    };

    const response = await admin.messaging().send(message);
    logger.debug(`Push sent successfully: ${response}`);
    return { success: true, messageId: response };
  } catch (error) {
    logger.error('FCM send error:', error);
    
    // Handle invalid token
    if (error.code === 'messaging/invalid-registration-token' ||
        error.code === 'messaging/registration-token-not-registered') {
      // Remove invalid token from database
      await prisma.user.updateMany({
        where: { fcmToken: token },
        data: { fcmToken: null }
      });
    }

    return { success: false, error: error.message };
  }
};

/**
 * Send push notification to multiple users
 */
const sendToUsers = async (userIds, notification) => {
  const users = await prisma.user.findMany({
    where: { 
      id: { in: userIds },
      fcmToken: { not: null }
    },
    select: { id: true, fcmToken: true }
  });

  const results = await Promise.all(
    users.map(user => sendToToken(user.fcmToken, notification))
  );

  return {
    total: userIds.length,
    sent: results.filter(r => r.success).length,
    failed: results.filter(r => !r.success).length
  };
};

/**
 * Send push notification to all students enrolled in a course
 */
const sendToCourseEnrollees = async (courseId, notification, excludeUserId = null) => {
  const enrollments = await prisma.enrollment.findMany({
    where: {
      courseId,
      status: 'ENROLLED',
      ...(excludeUserId && { userId: { not: excludeUserId } })
    },
    include: {
      user: {
        select: { id: true, fcmToken: true }
      }
    }
  });

  const tokens = enrollments
    .filter(e => e.user.fcmToken)
    .map(e => e.user.fcmToken);

  if (tokens.length === 0) {
    return { total: enrollments.length, sent: 0, failed: 0, reason: 'no_tokens' };
  }

  // Send notifications in batches of 500 (FCM limit)
  const batchSize = 500;
  let sent = 0;
  let failed = 0;

  for (let i = 0; i < tokens.length; i += batchSize) {
    const batch = tokens.slice(i, i + batchSize);
    
    if (firebaseApp) {
      try {
        const message = {
          notification: {
            title: notification.title,
            body: notification.body
          },
          data: notification.data || {},
          tokens: batch
        };

        const response = await admin.messaging().sendEachForMulticast(message);
        sent += response.successCount;
        failed += response.failureCount;
      } catch (error) {
        logger.error('Batch send error:', error);
        failed += batch.length;
      }
    } else {
      failed += batch.length;
    }
  }

  return { total: enrollments.length, sent, failed };
};

/**
 * Update user's FCM token
 */
const updateUserToken = async (userId, fcmToken) => {
  try {
    await prisma.user.update({
      where: { id: userId },
      data: { fcmToken }
    });
    return true;
  } catch (error) {
    logger.error('Error updating FCM token:', error);
    return false;
  }
};

/**
 * Create in-app notification record
 */
const createNotification = async ({
  userId,
  title,
  message,
  type = 'GENERAL',
  referenceType = null,
  referenceId = null,
  sendPush = true
}) => {
  try {
    // Create notification record
    const notification = await prisma.notification.create({
      data: {
        userId,
        title,
        message,
        type,
        referenceType,
        referenceId
      }
    });

    // Send push notification if enabled
    if (sendPush) {
      const pushResult = await sendToUser(userId, { title, body: message });
      if (pushResult.success) {
        await prisma.notification.update({
          where: { id: notification.id },
          data: { isPushed: true }
        });
      }
    }

    return notification;
  } catch (error) {
    logger.error('Error creating notification:', error);
    throw error;
  }
};

/**
 * Create notifications for all students in a course
 */
const notifyCourseStudents = async ({
  courseId,
  title,
  message,
  type = 'GENERAL',
  referenceType = null,
  referenceId = null,
  excludeUserId = null
}) => {
  try {
    // Get all enrolled students
    const enrollments = await prisma.enrollment.findMany({
      where: {
        courseId,
        status: 'ENROLLED',
        ...(excludeUserId && { userId: { not: excludeUserId } })
      },
      select: { userId: true }
    });

    const userIds = enrollments.map(e => e.userId);

    if (userIds.length === 0) {
      return { notified: 0 };
    }

    // Create notifications in bulk
    await prisma.notification.createMany({
      data: userIds.map(userId => ({
        userId,
        title,
        message,
        type,
        referenceType,
        referenceId
      }))
    });

    // Send push notifications
    const pushResult = await sendToCourseEnrollees(courseId, { title, body: message }, excludeUserId);

    logger.info(`📢 Notified ${userIds.length} students about: ${title}`);

    return { notified: userIds.length, pushResult };
  } catch (error) {
    logger.error('Error notifying course students:', error);
    throw error;
  }
};

module.exports = {
  sendToUser,
  sendToUsers,
  sendToToken,
  sendToCourseEnrollees,
  updateUserToken,
  createNotification,
  notifyCourseStudents
};
