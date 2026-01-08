/**
 * User Routes
 */
const express = require('express');
const { body, param } = require('express-validator');

const router = express.Router();
const { prisma } = require('../utils/database');
const { validate } = require('../middleware/validate');
const { authenticate } = require('../middleware/auth');
const { ApiError } = require('../middleware/errorHandler');
const logger = require('../utils/logger');

/**
 * Format user for response
 */
const formatUserResponse = (user) => ({
  id: user.id,
  email: user.email,
  name: user.name,
  avatar: user.avatar,
  role: user.role.toLowerCase(),
  studentId: user.studentId,
  major: user.major,
  department: user.department,
  program: user.program,
  gpa: user.gpa,
  level: user.level,
  isVerified: user.isVerified,
  isOnboardingComplete: user.isOnboardingComplete,
  enrolledCourses: user.enrollments?.map(e => e.courseId) || [],
  mode: user.role === 'PROFESSOR' ? 'professor' : 'student'
});

// ============ GET USER BY EMAIL ============

router.get('/:email',
  authenticate,
  [
    param('email').isEmail(),
    validate
  ],
  async (req, res, next) => {
    try {
      const { email } = req.params;

      // Users can only view their own profile (unless admin)
      if (req.user.email !== email && req.user.role !== 'ADMIN') {
        throw new ApiError(403, 'Access denied');
      }

      const user = await prisma.user.findUnique({
        where: { email },
        include: {
          enrollments: {
            include: {
              course: {
                select: { id: true, code: true, name: true }
              }
            }
          }
        }
      });

      if (!user) {
        throw new ApiError(404, 'User not found');
      }

      res.json({
        success: true,
        user: formatUserResponse(user)
      });
    } catch (error) {
      next(error);
    }
  }
);

// ============ UPDATE USER PROFILE ============

router.put('/:email',
  authenticate,
  [
    param('email').isEmail(),
    body('name').optional().trim().notEmpty(),
    body('avatar').optional().isString(),
    body('major').optional().isString(),
    body('department').optional().isString(),
    body('program').optional().isString(),
    body('gpa').optional().isFloat({ min: 0, max: 4 }),
    body('level').optional().isInt({ min: 1, max: 10 }),
    validate
  ],
  async (req, res, next) => {
    try {
      const { email } = req.params;

      // Users can only update their own profile
      if (req.user.email !== email && req.user.role !== 'ADMIN') {
        throw new ApiError(403, 'Access denied');
      }

      const { name, avatar, major, department, program, gpa, level, isOnboardingComplete, enrolledCourses } = req.body;

      // Update user
      const updatedUser = await prisma.user.update({
        where: { email },
        data: {
          ...(name && { name }),
          ...(avatar !== undefined && { avatar }),
          ...(major !== undefined && { major }),
          ...(department !== undefined && { department }),
          ...(program !== undefined && { program }),
          ...(gpa !== undefined && { gpa }),
          ...(level !== undefined && { level }),
          ...(isOnboardingComplete !== undefined && { isOnboardingComplete })
        },
        include: {
          enrollments: {
            select: { courseId: true }
          }
        }
      });

      // Handle course enrollment if provided
      if (enrolledCourses && Array.isArray(enrolledCourses)) {
        // Get current enrollments
        const currentEnrollments = await prisma.enrollment.findMany({
          where: { userId: updatedUser.id },
          select: { courseId: true }
        });

        const currentCourseIds = currentEnrollments.map(e => e.courseId);
        const newCourseIds = enrolledCourses;

        // Courses to add
        const toAdd = newCourseIds.filter(id => !currentCourseIds.includes(id));
        // Courses to remove
        const toRemove = currentCourseIds.filter(id => !newCourseIds.includes(id));

        // Add new enrollments
        if (toAdd.length > 0) {
          await prisma.enrollment.createMany({
            data: toAdd.map(courseId => ({
              userId: updatedUser.id,
              courseId,
              status: 'ENROLLED'
            })),
            skipDuplicates: true
          });
        }

        // Remove old enrollments
        if (toRemove.length > 0) {
          await prisma.enrollment.deleteMany({
            where: {
              userId: updatedUser.id,
              courseId: { in: toRemove }
            }
          });
        }
      }

      // Fetch updated user with enrollments
      const finalUser = await prisma.user.findUnique({
        where: { id: updatedUser.id },
        include: {
          enrollments: {
            select: { courseId: true }
          }
        }
      });

      logger.info(`✅ User updated: ${email}`);

      res.json({
        success: true,
        user: formatUserResponse(finalUser)
      });
    } catch (error) {
      next(error);
    }
  }
);

// ============ COMPLETE ONBOARDING ============

router.post('/complete-onboarding',
  authenticate,
  [
    body('enrolledCourses').isArray({ min: 1 }).withMessage('At least one course required'),
    validate
  ],
  async (req, res, next) => {
    try {
      const { enrolledCourses } = req.body;

      // Verify courses exist
      const courses = await prisma.course.findMany({
        where: { id: { in: enrolledCourses } }
      });

      if (courses.length !== enrolledCourses.length) {
        throw new ApiError(400, 'Some courses are invalid');
      }

      // Create enrollments
      await prisma.enrollment.createMany({
        data: enrolledCourses.map(courseId => ({
          userId: req.user.id,
          courseId,
          status: 'ENROLLED'
        })),
        skipDuplicates: true
      });

      // Mark onboarding as complete
      const updatedUser = await prisma.user.update({
        where: { id: req.user.id },
        data: { isOnboardingComplete: true },
        include: {
          enrollments: {
            select: { courseId: true }
          }
        }
      });

      logger.info(`✅ Onboarding completed: ${req.user.email}`);

      res.json({
        success: true,
        user: formatUserResponse(updatedUser)
      });
    } catch (error) {
      next(error);
    }
  }
);

// ============ GET USER ENROLLMENTS ============

router.get('/:email/enrollments',
  authenticate,
  async (req, res, next) => {
    try {
      const { email } = req.params;

      if (req.user.email !== email && req.user.role !== 'ADMIN') {
        throw new ApiError(403, 'Access denied');
      }

      const user = await prisma.user.findUnique({
        where: { email },
        select: { id: true }
      });

      if (!user) {
        throw new ApiError(404, 'User not found');
      }

      const enrollments = await prisma.enrollment.findMany({
        where: { userId: user.id },
        include: {
          course: {
            include: {
              instructors: {
                include: {
                  user: {
                    select: { name: true, email: true }
                  }
                }
              }
            }
          }
        }
      });

      res.json({
        success: true,
        enrollments: enrollments.map(e => ({
          id: e.id,
          status: e.status,
          enrolledAt: e.enrolledAt,
          grade: e.grade,
          course: {
            id: e.course.id,
            code: e.course.code,
            name: e.course.name,
            category: e.course.category,
            creditHours: e.course.creditHours,
            professors: e.course.instructors.map(i => i.user.name)
          }
        }))
      });
    } catch (error) {
      next(error);
    }
  }
);

module.exports = router;
