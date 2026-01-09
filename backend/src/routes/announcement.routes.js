/**
 * Announcement Routes
 */
const express = require('express');
const { body, param, query } = require('express-validator');

const router = express.Router();
const { prisma } = require('../utils/database');
const { validate } = require('../middleware/validate');
const { authenticate, requireProfessor } = require('../middleware/auth');
const { ApiError } = require('../middleware/errorHandler');
const { notifyCourseStudents } = require('../services/notification.service');
const logger = require('../utils/logger');

// ============ GET ANNOUNCEMENTS ============

router.get('/',
  authenticate,
  async (req, res, next) => {
    try {
      const { courseId, limit = 50 } = req.query;

      let where = {};

      if (courseId) {
        // Get announcements for specific course
        where.courseId = courseId;
      } else {
        // Get announcements for user's enrolled courses + general announcements
        const enrollments = await prisma.enrollment.findMany({
          where: { userId: req.user.id, status: 'ENROLLED' },
          select: { courseId: true }
        });

        const courseIds = enrollments.map(e => e.courseId);

        where = {
          OR: [
            { courseId: { in: courseIds } },
            { courseId: null }
          ]
        };
      }

      const announcements = await prisma.announcement.findMany({
        where,
        include: {
          course: {
            select: { code: true, name: true }
          },
          createdBy: {
            select: { name: true }
          }
        },
        orderBy: [
          { isPinned: 'desc' },
          { createdAt: 'desc' }
        ],
        take: parseInt(limit)
      });

      res.json({
        success: true,
        announcements: announcements.map(a => ({
          id: a.id,
          title: a.title,
          message: a.message,
          type: a.type,
          isPinned: a.isPinned,
          course: a.course ? {
            code: a.course.code,
            name: a.course.name
          } : null,
          createdBy: a.createdBy.name,
          createdAt: a.createdAt,
          expiresAt: a.expiresAt
        }))
      });
    } catch (error) {
      next(error);
    }
  }
);

// ============ GET SINGLE ANNOUNCEMENT ============

router.get('/:id',
  authenticate,
  async (req, res, next) => {
    try {
      const { id } = req.params;

      const announcement = await prisma.announcement.findUnique({
        where: { id },
        include: {
          course: {
            select: { code: true, name: true }
          },
          createdBy: {
            select: { name: true, email: true }
          }
        }
      });

      if (!announcement) {
        throw new ApiError(404, 'Announcement not found');
      }

      res.json({
        success: true,
        announcement
      });
    } catch (error) {
      next(error);
    }
  }
);

// ============ CREATE ANNOUNCEMENT ============

router.post('/',
  authenticate,
  requireProfessor,
  [
    body('title').trim().notEmpty().withMessage('Title is required'),
    body('message').trim().notEmpty().withMessage('Message is required'),
    body('courseId').optional().isString(),
    body('type').optional().isIn(['GENERAL', 'ASSIGNMENT', 'EXAM', 'LECTURE', 'URGENT', 'MAINTENANCE']),
    body('isPinned').optional().isBoolean(),
    body('expiresAt').optional().isISO8601(),
    validate
  ],
  async (req, res, next) => {
    try {
      const { title, message, courseId, type = 'GENERAL', isPinned = false, expiresAt } = req.body;

      // If course-specific, verify professor teaches it
      if (courseId) {
        const isInstructor = await prisma.courseInstructor.findFirst({
          where: { courseId, userId: req.user.id }
        });

        if (!isInstructor && req.user.role !== 'ADMIN') {
          throw new ApiError(403, 'You do not teach this course');
        }
      }

      // Create announcement
      const announcement = await prisma.announcement.create({
        data: {
          title,
          message,
          courseId,
          type,
          isPinned,
          expiresAt: expiresAt ? new Date(expiresAt) : null,
          createdById: req.user.id
        },
        include: {
          course: {
            select: { code: true, name: true }
          }
        }
      });

      // Notify students if course-specific
      if (courseId) {
        await notifyCourseStudents({
          courseId,
          title: `📢 ${title}`,
          message: message.substring(0, 200),
          type: 'ANNOUNCEMENT',
          referenceType: 'ANNOUNCEMENT',
          referenceId: announcement.id,
          excludeUserId: req.user.id
        });
      }

      logger.info(`✅ Announcement created: ${title}`);

      res.status(201).json({
        success: true,
        announcement
      });
    } catch (error) {
      next(error);
    }
  }
);

// ============ UPDATE ANNOUNCEMENT ============

router.put('/:id',
  authenticate,
  requireProfessor,
  [
    param('id').notEmpty(),
    body('title').optional().trim().notEmpty(),
    body('message').optional().trim().notEmpty(),
    body('isPinned').optional().isBoolean(),
    validate
  ],
  async (req, res, next) => {
    try {
      const { id } = req.params;
      const { title, message, isPinned } = req.body;

      // Find and verify ownership
      const announcement = await prisma.announcement.findUnique({
        where: { id }
      });

      if (!announcement) {
        throw new ApiError(404, 'Announcement not found');
      }

      if (announcement.createdById !== req.user.id && req.user.role !== 'ADMIN') {
        throw new ApiError(403, 'Cannot edit this announcement');
      }

      const updated = await prisma.announcement.update({
        where: { id },
        data: {
          ...(title && { title }),
          ...(message && { message }),
          ...(isPinned !== undefined && { isPinned })
        }
      });

      res.json({
        success: true,
        announcement: updated
      });
    } catch (error) {
      next(error);
    }
  }
);

// ============ DELETE ANNOUNCEMENT ============

router.delete('/:id',
  authenticate,
  requireProfessor,
  async (req, res, next) => {
    try {
      const { id } = req.params;

      const announcement = await prisma.announcement.findUnique({
        where: { id }
      });

      if (!announcement) {
        throw new ApiError(404, 'Announcement not found');
      }

      if (announcement.createdById !== req.user.id && req.user.role !== 'ADMIN') {
        throw new ApiError(403, 'Cannot delete this announcement');
      }

      await prisma.announcement.delete({
        where: { id }
      });

      res.json({
        success: true,
        message: 'Announcement deleted'
      });
    } catch (error) {
      next(error);
    }
  }
);

module.exports = router;
