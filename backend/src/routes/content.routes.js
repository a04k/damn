/**
 * Content Routes (Professor content creation)
 */
const express = require('express');
const { body, param } = require('express-validator');

const router = express.Router();
const { prisma } = require('../utils/database');
const { validate } = require('../middleware/validate');
const { authenticate, requireProfessor } = require('../middleware/auth');
const { ApiError } = require('../middleware/errorHandler');
const { notifyCourseStudents } = require('../services/notification.service');
const logger = require('../utils/logger');

// ============ CREATE LECTURE/CONTENT ============

router.post('/',
  authenticate,
  requireProfessor,
  [
    body('courseId').notEmpty().withMessage('Course ID is required'),
    body('title').trim().notEmpty().withMessage('Title is required'),
    body('contentType').isIn(['LECTURE', 'MATERIAL', 'VIDEO', 'DOCUMENT', 'LINK']),
    body('description').optional().isString(),
    body('fileUrl').optional().isString(),
    body('attachments').optional().isArray(),
    body('weekNumber').optional().isInt({ min: 1 }),
    validate
  ],
  async (req, res, next) => {
    try {
      const { courseId, title, description, contentType, fileUrl, weekNumber, attachments } = req.body;

      // Verify professor teaches this course
      const isInstructor = await prisma.courseInstructor.findFirst({
        where: {
          courseId,
          userId: req.user.id
        }
      });

      if (!isInstructor && req.user.role !== 'ADMIN') {
        throw new ApiError(403, 'You do not teach this course');
      }

      // Get max order index for the week
      const lastContent = await prisma.courseContent.findFirst({
        where: { courseId, weekNumber: weekNumber || null },
        orderBy: { orderIndex: 'desc' }
      });

      const orderIndex = (lastContent?.orderIndex || 0) + 1;

      // Create content
      const content = await prisma.courseContent.create({
        data: {
          courseId,
          title,
          description,
          contentType,
          fileUrl,
          attachments,
          weekNumber,
          orderIndex,
          createdById: req.user.id
        }
      });

      // Get course details for notification
      const course = await prisma.course.findUnique({
        where: { id: courseId },
        select: { name: true, code: true }
      });

      // Notify students
      await notifyCourseStudents({
        courseId,
        title: `New ${contentType.toLowerCase()}: ${title}`,
        message: `${course.code}: ${description || title}`,
        type: 'ANNOUNCEMENT',
        referenceType: 'CONTENT',
        referenceId: content.id,
        excludeUserId: req.user.id
      });

      // Also create an announcement
      await prisma.announcement.create({
        data: {
          courseId,
          title: `New ${contentType.toLowerCase()}: ${title}`,
          message: description || `New content available for ${course.name}`,
          type: 'LECTURE',
          createdById: req.user.id
        }
      });

      logger.info(`✅ Content created: ${title} for ${course.code}`);

      res.status(201).json({
        success: true,
        content: {
          id: content.id,
          title: content.title,
          type: content.contentType,
          weekNumber: content.weekNumber
        }
      });
    } catch (error) {
      next(error);
    }
  }
);

// ============ CREATE ASSIGNMENT ============

router.post('/assignment',
  authenticate,
  requireProfessor,
  [
    body('courseId').notEmpty(),
    body('title').trim().notEmpty(),
    body('description').optional().isString(),
    body('dueDate').isISO8601(),
    body('points').optional().isInt({ min: 0 }).default(100),
    body('attachments').optional().isArray(),
    validate
  ],
  async (req, res, next) => {
    try {
      const { courseId, title, description, dueDate, points = 100, attachments } = req.body;

      // Verify instructor
      const isInstructor = await prisma.courseInstructor.findFirst({
        where: { courseId, userId: req.user.id }
      });

      if (!isInstructor && req.user.role !== 'ADMIN') {
        throw new ApiError(403, 'You do not teach this course');
      }

      // Get course
      const course = await prisma.course.findUnique({
        where: { id: courseId },
        select: { name: true, code: true }
      });

      if (!course) {
        throw new ApiError(404, 'Course not found');
      }

      // Create task
      const task = await prisma.task.create({
        data: {
          title,
          description,
          taskType: 'ASSIGNMENT',
          priority: 'MEDIUM',
          dueDate: new Date(dueDate),
          maxPoints: points,
          attachments,
          courseId,
          createdById: req.user.id
        }
      });

      // Notify students
      const formattedDate = new Date(dueDate).toLocaleDateString();
      await notifyCourseStudents({
        courseId,
        title: `New Assignment: ${title}`,
        message: `${course.code} - Due: ${formattedDate}`,
        type: 'ASSIGNMENT',
        referenceType: 'TASK',
        referenceId: task.id,
        excludeUserId: req.user.id
      });

      // Create announcement
      await prisma.announcement.create({
        data: {
          courseId,
          title: `New Assignment: ${title}`,
          message: `Due: ${formattedDate}. ${description || ''}`,
          type: 'ASSIGNMENT',
          createdById: req.user.id
        }
      });

      logger.info(`✅ Assignment created: ${title} for ${course.code}`);

      res.status(201).json({
        success: true,
        task: {
          id: task.id,
          title: task.title,
          dueDate: task.dueDate,
          maxPoints: task.maxPoints
        }
      });
    } catch (error) {
      next(error);
    }
  }
);

// ============ CREATE EXAM ============

router.post('/exam',
  authenticate,
  requireProfessor,
  [
    body('courseId').notEmpty(),
    body('title').trim().notEmpty(),
    body('description').optional().isString(),
    body('examDate').isISO8601(),
    body('points').optional().isInt({ min: 0 }).default(100),
    body('attachments').optional().isArray(),
    validate
  ],
  async (req, res, next) => {
    try {
      const { courseId, title, description, examDate, points = 100 } = req.body;

      // Verify instructor
      const isInstructor = await prisma.courseInstructor.findFirst({
        where: { courseId, userId: req.user.id }
      });

      if (!isInstructor && req.user.role !== 'ADMIN') {
        throw new ApiError(403, 'You do not teach this course');
      }

      // Get course
      const course = await prisma.course.findUnique({
        where: { id: courseId },
        select: { name: true, code: true }
      });

      if (!course) {
        throw new ApiError(404, 'Course not found');
      }

      // Create task
      const task = await prisma.task.create({
        data: {
          title,
          description,
          taskType: 'EXAM',
          priority: 'HIGH',
          dueDate: new Date(examDate),
          maxPoints: points,
          attachments,
          courseId,
          createdById: req.user.id
        }
      });

      // Notify students
      const formattedDate = new Date(examDate).toLocaleDateString();
      await notifyCourseStudents({
        courseId,
        title: `Exam Scheduled: ${title}`,
        message: `${course.code} - Date: ${formattedDate}`,
        type: 'EXAM',
        referenceType: 'TASK',
        referenceId: task.id,
        excludeUserId: req.user.id
      });

      // Create announcement
      await prisma.announcement.create({
        data: {
          courseId,
          title: `Exam Scheduled: ${title}`,
          message: `Date: ${formattedDate}. ${description || ''}`,
          type: 'EXAM',
          createdById: req.user.id
        }
      });

      logger.info(`✅ Exam created: ${title} for ${course.code}`);

      res.status(201).json({
        success: true,
        task: {
          id: task.id,
          title: task.title,
          examDate: task.dueDate,
          maxPoints: task.maxPoints
        }
      });
    } catch (error) {
      next(error);
    }
  }
);

// ============ UPDATE CONTENT ============

router.put('/:id',
  authenticate,
  requireProfessor,
  [
    param('id').notEmpty(),
    body('title').optional().trim().notEmpty(),
    body('description').optional().isString(),
    body('fileUrl').optional().isString(),
    body('isPublished').optional().isBoolean(),
    validate
  ],
  async (req, res, next) => {
    try {
      const { id } = req.params;
      const { title, description, fileUrl, isPublished } = req.body;

      // Find content and verify ownership
      const content = await prisma.courseContent.findUnique({
        where: { id },
        include: {
          course: {
            include: {
              instructors: {
                where: { userId: req.user.id }
              }
            }
          }
        }
      });

      if (!content) {
        throw new ApiError(404, 'Content not found');
      }

      if (content.course.instructors.length === 0 && req.user.role !== 'ADMIN') {
        throw new ApiError(403, 'You cannot edit this content');
      }

      const updated = await prisma.courseContent.update({
        where: { id },
        data: {
          ...(title && { title }),
          ...(description !== undefined && { description }),
          ...(fileUrl !== undefined && { fileUrl }),
          ...(isPublished !== undefined && { isPublished })
        }
      });

      res.json({
        success: true,
        content: updated
      });
    } catch (error) {
      next(error);
    }
  }
);

// ============ DELETE CONTENT ============

router.delete('/:id',
  authenticate,
  requireProfessor,
  async (req, res, next) => {
    try {
      const { id } = req.params;

      // Find content and verify ownership
      const content = await prisma.courseContent.findUnique({
        where: { id },
        include: {
          course: {
            include: {
              instructors: {
                where: { userId: req.user.id }
              }
            }
          }
        }
      });

      if (!content) {
        throw new ApiError(404, 'Content not found');
      }

      if (content.course.instructors.length === 0 && req.user.role !== 'ADMIN') {
        throw new ApiError(403, 'You cannot delete this content');
      }

      await prisma.courseContent.delete({
        where: { id }
      });

      res.json({
        success: true,
        message: 'Content deleted'
      });
    } catch (error) {
      next(error);
    }
  }
);

module.exports = router;
