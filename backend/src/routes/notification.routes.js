/**
 * Notification Routes
 */
const express = require('express');
const { body, param } = require('express-validator');

const router = express.Router();
const { prisma } = require('../utils/database');
const { validate } = require('../middleware/validate');
const { authenticate } = require('../middleware/auth');
const { ApiError } = require('../middleware/errorHandler');

// ============ GET USER NOTIFICATIONS ============

router.get('/',
  authenticate,
  async (req, res, next) => {
    try {
      const { unreadOnly, limit = 50 } = req.query;

      const notifications = await prisma.notification.findMany({
        where: {
          userId: req.user.id,
          ...(unreadOnly === 'true' && { isRead: false })
        },
        orderBy: { createdAt: 'desc' },
        take: parseInt(limit)
      });

      // Get unread count
      const unreadCount = await prisma.notification.count({
        where: {
          userId: req.user.id,
          isRead: false
        }
      });

      res.json({
        success: true,
        notifications: notifications.map(n => ({
          id: n.id,
          title: n.title,
          message: n.message,
          type: n.type,
          referenceType: n.referenceType,
          referenceId: n.referenceId,
          isRead: n.isRead,
          createdAt: n.createdAt,
          readAt: n.readAt
        })),
        unreadCount
      });
    } catch (error) {
      next(error);
    }
  }
);

// ============ GET UNREAD COUNT ============

router.get('/unread-count',
  authenticate,
  async (req, res, next) => {
    try {
      const count = await prisma.notification.count({
        where: {
          userId: req.user.id,
          isRead: false
        }
      });

      res.json({
        success: true,
        count
      });
    } catch (error) {
      next(error);
    }
  }
);

// ============ MARK AS READ ============

router.put('/:id/read',
  authenticate,
  async (req, res, next) => {
    try {
      const { id } = req.params;

      const notification = await prisma.notification.findFirst({
        where: {
          id,
          userId: req.user.id
        }
      });

      if (!notification) {
        throw new ApiError(404, 'Notification not found');
      }

      await prisma.notification.update({
        where: { id },
        data: {
          isRead: true,
          readAt: new Date()
        }
      });

      res.json({
        success: true,
        message: 'Marked as read'
      });
    } catch (error) {
      next(error);
    }
  }
);

// ============ MARK ALL AS READ ============

router.put('/read-all',
  authenticate,
  async (req, res, next) => {
    try {
      const result = await prisma.notification.updateMany({
        where: {
          userId: req.user.id,
          isRead: false
        },
        data: {
          isRead: true,
          readAt: new Date()
        }
      });

      res.json({
        success: true,
        message: 'All notifications marked as read',
        count: result.count
      });
    } catch (error) {
      next(error);
    }
  }
);

// ============ DELETE NOTIFICATION ============

router.delete('/:id',
  authenticate,
  async (req, res, next) => {
    try {
      const { id } = req.params;

      const notification = await prisma.notification.findFirst({
        where: {
          id,
          userId: req.user.id
        }
      });

      if (!notification) {
        throw new ApiError(404, 'Notification not found');
      }

      await prisma.notification.delete({
        where: { id }
      });

      res.json({
        success: true,
        message: 'Notification deleted'
      });
    } catch (error) {
      next(error);
    }
  }
);

// ============ DELETE ALL READ NOTIFICATIONS ============

router.delete('/clear-read',
  authenticate,
  async (req, res, next) => {
    try {
      const result = await prisma.notification.deleteMany({
        where: {
          userId: req.user.id,
          isRead: true
        }
      });

      res.json({
        success: true,
        message: 'Read notifications cleared',
        count: result.count
      });
    } catch (error) {
      next(error);
    }
  }
);

module.exports = router;
