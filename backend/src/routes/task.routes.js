/**
 * Task Routes
 */
const express = require('express');
const { body, param, query } = require('express-validator');

const router = express.Router();
const { prisma } = require('../utils/database');
const { validate } = require('../middleware/validate');
const { authenticate } = require('../middleware/auth');
const { ApiError } = require('../middleware/errorHandler');
const logger = require('../utils/logger');

// ============ GET ALL TASKS ============

router.get('/',
  authenticate,
  async (req, res, next) => {
    try {
      const { status, type, courseId, upcoming } = req.query;

      // Build where clause
      const where = {
        OR: [

          // Tasks from enrolled courses
          {
            course: {
              enrollments: {
                some: { userId: req.user.id, status: 'ENROLLED' }
              }
            }
          },
          // Tasks created by user (Personal or Professor Assignments)
          { createdById: req.user.id }
        ],
        ...(status && { status }),
        ...(type && { taskType: type }),
        ...(courseId && { courseId }),
        ...(upcoming === 'true' && {
          dueDate: { gte: new Date() },
          status: { not: 'COMPLETED' }
        })
      };

      const tasks = await prisma.task.findMany({
        where,
        include: {
          course: {
            select: { id: true, code: true, name: true }
          },
          createdBy: {
            select: { name: true }
          },
          submissions: {
            where: { studentId: req.user.id },
            select: { status: true, fileUrl: true, submittedAt: true }
          }
        },
        orderBy: [
          { dueDate: 'asc' },
          { priority: 'desc' }
        ]
      });

      res.json({
        success: true,
        tasks: tasks.map(t => ({
          id: t.id,
          title: t.title,
          description: t.description,
          type: t.taskType,
          priority: t.priority,
          // If user has a submission, use that status. Otherwise use task status (or PENDING if null)
          status: t.submissions?.[0]?.status || t.status || 'PENDING',
          dueDate: t.dueDate,
          maxPoints: t.maxPoints,
          attachments: t.attachments,
          course: t.course ? {
            id: t.course.id,
            code: t.course.code,
            name: t.course.name
          } : null,
          createdBy: t.createdBy.name,
          createdAt: t.createdAt,
          completedAt: t.completedAt,
          submission: t.submissions?.[0] || null
        }))
      });
    } catch (error) {
      next(error);
    }
  }
);

// ============ GET PENDING TASKS ============

router.get('/pending',
  authenticate,
  async (req, res, next) => {
    try {
      const tasks = await prisma.task.findMany({
        where: {
          status: { in: ['PENDING', 'IN_PROGRESS'] },
          OR: [

            {
              course: {
                enrollments: {
                  some: { userId: req.user.id, status: 'ENROLLED' }
                }
              }
            },
            { createdById: req.user.id }
          ]
        },
        include: {
          course: {
            select: { code: true, name: true }
          }
        },
        orderBy: { dueDate: 'asc' },
        take: 20
      });

      res.json({
        success: true,
        tasks: tasks.map(t => ({
          id: t.id,
          title: t.title,
          type: t.taskType,
          priority: t.priority,
          status: t.status,
          dueDate: t.dueDate,
          maxPoints: t.maxPoints,
          attachments: t.attachments,
          courseName: t.course?.name || null,
          courseCode: t.course?.code || null
        }))
      });
    } catch (error) {
      next(error);
    }
  }
);

// ============ GET SINGLE TASK ============

router.get('/:id',
  authenticate,
  async (req, res, next) => {
    try {
      const { id } = req.params;

      const task = await prisma.task.findUnique({
        where: { id },
        include: {
          course: {
            select: { id: true, code: true, name: true }
          },
          createdBy: {
            select: { name: true, email: true }
          },
          submissions: {
            where: { studentId: req.user.id }
          },

        }
      });

      if (!task) {
        throw new ApiError(404, 'Task not found');
      }

      res.json({
        success: true,
        task
      });
    } catch (error) {
      next(error);
    }
  }
);

// ============ CREATE PERSONAL TASK ============

router.post('/',
  authenticate,
  [
    body('title').trim().notEmpty().withMessage('Title is required'),
    body('description').optional().isString(),
    body('priority').optional().isIn(['LOW', 'MEDIUM', 'HIGH', 'URGENT']),
    body('dueDate').optional().isISO8601(),
    body('points').optional().isInt({ min: 0 }),
    validate
  ],
  async (req, res, next) => {
    try {
      const { title, description, priority = 'MEDIUM', dueDate, points } = req.body;

      const task = await prisma.task.create({
        data: {
          title,
          description,
          taskType: 'PERSONAL',
          priority,
          dueDate: dueDate ? new Date(dueDate) : null,
          points,
          createdById: req.user.id,

        }
      });

      logger.info(`✅ Personal task created: ${title}`);

      res.status(201).json({
        success: true,
        task
      });
    } catch (error) {
      next(error);
    }
  }
);

// ============ UPDATE TASK ============

router.put('/:id',
  authenticate,
  [
    param('id').notEmpty(),
    body('title').optional().trim().notEmpty(),
    body('description').optional().isString(),
    body('priority').optional().isIn(['LOW', 'MEDIUM', 'HIGH', 'URGENT']),
    body('status').optional().isIn(['PENDING', 'IN_PROGRESS', 'COMPLETED', 'OVERDUE']),
    body('dueDate').optional().isISO8601(),
    validate
  ],
  async (req, res, next) => {
    try {
      const { id } = req.params;
      const { title, description, priority, status, dueDate } = req.body;

      // Find task
      const task = await prisma.task.findUnique({
        where: { id }
      });

      if (!task) {
        throw new ApiError(404, 'Task not found');
      }

      // Only allow editing own tasks or if admin/professor
      const canEdit = task.createdById === req.user.id || 
                      req.user.role === 'ADMIN';

      if (!canEdit) {
        throw new ApiError(403, 'Cannot edit this task');
      }

      const updated = await prisma.task.update({
        where: { id },
        data: {
          ...(title && { title }),
          ...(description !== undefined && { description }),
          ...(priority && { priority }),
          ...(status && { 
            status,
            ...(status === 'COMPLETED' && { completedAt: new Date() })
          }),
          ...(dueDate && { dueDate: new Date(dueDate) })
        }
      });

      res.json({
        success: true,
        task: updated
      });
    } catch (error) {
      next(error);
    }
  }
);

// ============ MARK TASK COMPLETE ============

router.post('/:id/complete',
  authenticate,
  async (req, res, next) => {
    try {
      const { id } = req.params;

      const task = await prisma.task.findUnique({
        where: { id },
        include: {
          submissions: {
            where: { studentId: req.user.id }
          }
        }
      });

      if (!task) {
        throw new ApiError(404, 'Task not found');
      }

      // Check if assignment needs submission
      if (task.taskType === 'ASSIGNMENT' && (!task.submissions || task.submissions.length === 0)) {
        throw new ApiError(400, 'Assignments must be submitted before marking as complete');
      }

      const updated = await prisma.task.update({
        where: { id },
        data: {
          status: 'COMPLETED',
          completedAt: new Date()
        }
      });

      res.json({
        success: true,
        task: updated
      });
    } catch (error) {
      next(error);
    }
  }
);

// ============ SUBMIT ASSIGNMENT ============

router.post('/:id/submit',
  authenticate,
  [
    body('fileUrl').optional().isURL(),
    body('notes').optional().isString(),
    validate
  ],
  async (req, res, next) => {
    try {
      const { id } = req.params;
      const { fileUrl, notes } = req.body;

      const task = await prisma.task.findUnique({
        where: { id }
      });

      if (!task) {
        throw new ApiError(404, 'Task not found');
      }

      // Create or update submission
      const submission = await prisma.taskSubmission.upsert({
        where: {
          taskId_studentId: {
            taskId: id,
            studentId: req.user.id
          }
        },
        update: {
          fileUrl,
          notes,
          status: 'SUBMITTED',
          submittedAt: new Date()
        },
        create: {
          taskId: id,
          studentId: req.user.id,
          fileUrl,
          notes,
          status: 'SUBMITTED',
          submittedAt: new Date()
        }
      });

      logger.info(`✅ Assignment submitted: ${req.user.email} -> ${task.title}`);

      res.json({
        success: true,
        submission
      });
    } catch (error) {
      next(error);
    }
  }
);

// ============ UNSUBMIT ASSIGNMENT ============

router.post('/:id/unsubmit',
  authenticate,
  async (req, res, next) => {
    try {
      const { id } = req.params;

      // Check if submission exists
      const submission = await prisma.taskSubmission.findUnique({
        where: {
          taskId_studentId: {
            taskId: id,
            studentId: req.user.id
          }
        }
      });

      if (!submission) {
        throw new ApiError(404, 'No submission found for this task');
      }

      // Delete submission
      await prisma.taskSubmission.delete({
        where: {
          id: submission.id
        }
      });

      // If the task was marked as completed, we might want to reset it?
      // For now, let's just delete the submission. 
      // The status will fall back to the task's status (PENDING).

      logger.info(`✅ Assignment unsubmitted: ${req.user.email} -> Task ID ${id}`);

      res.json({
        success: true,
        message: 'Submission removed'
      });
    } catch (error) {
      next(error);
    }
  }
);

// ============ DELETE TASK ============

router.delete('/:id',
  authenticate,
  async (req, res, next) => {
    try {
      const { id } = req.params;

      const task = await prisma.task.findUnique({
        where: { id }
      });

      if (!task) {
        throw new ApiError(404, 'Task not found');
      }

      // Only allow deleting own personal tasks or if admin
      const canDelete = (task.createdById === req.user.id && task.taskType === 'PERSONAL') ||
                        req.user.role === 'ADMIN';

      if (!canDelete) {
        throw new ApiError(403, 'Cannot delete this task');
      }

      await prisma.task.delete({
        where: { id }
      });

      res.json({
        success: true,
        message: 'Task deleted'
      });
    } catch (error) {
      next(error);
    }
  }
);

module.exports = router;
