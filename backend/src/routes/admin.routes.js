/**
 * Admin Routes
 * Full admin panel functionality for managing users, courses, and system
 */
const express = require('express');
const bcrypt = require('bcryptjs');
const { body, param, query } = require('express-validator');

const router = express.Router();
const { prisma } = require('../utils/database');
const { validate } = require('../middleware/validate');
const { authenticate, requireAdmin } = require('../middleware/auth');
const { ApiError } = require('../middleware/errorHandler');
const logger = require('../utils/logger');

// All admin routes require authentication and admin role
router.use(authenticate);
router.use(requireAdmin);

// ============ DASHBOARD STATS ============

router.get('/stats', async (req, res, next) => {
  try {
    const [
      totalUsers,
      totalStudents,
      totalProfessors,
      totalCourses,
      totalEnrollments,
      totalTasks,
      recentUsers
    ] = await Promise.all([
      prisma.user.count(),
      prisma.user.count({ where: { role: 'STUDENT' } }),
      prisma.user.count({ where: { role: 'PROFESSOR' } }),
      prisma.course.count({ where: { isActive: true } }),
      prisma.enrollment.count({ where: { status: 'ENROLLED' } }),
      prisma.task.count(),
      prisma.user.count({
        where: {
          createdAt: { gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) }
        }
      })
    ]);

    res.json({
      success: true,
      stats: {
        users: {
          total: totalUsers,
          students: totalStudents,
          professors: totalProfessors,
          recentSignups: recentUsers
        },
        courses: {
          total: totalCourses,
          totalEnrollments
        },
        tasks: totalTasks
      }
    });
  } catch (error) {
    next(error);
  }
});

// ============ USER MANAGEMENT ============

// Get all users with pagination and filtering
router.get('/users', async (req, res, next) => {
  try {
    const { 
      search, 
      role, 
      isActive,
      page = 1, 
      limit = 20,
      sortBy = 'createdAt',
      sortOrder = 'desc'
    } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const where = {
      ...(search && {
        OR: [
          { name: { contains: search } },
          { email: { contains: search } },
          { studentId: { contains: search } }
        ]
      }),
      ...(role && { role: role.toUpperCase() }),
      ...(isActive !== undefined && { isActive: isActive === 'true' })
    };

    const [users, total] = await Promise.all([
      prisma.user.findMany({
        where,
        select: {
          id: true,
          email: true,
          name: true,
          avatar: true,
          role: true,
          studentId: true,
          gpa: true,
          level: true,
          department: {
            select: { id: true, code: true, name: true }
          },
          program: {
            select: { id: true, code: true, name: true }
          },
          isVerified: true,
          isActive: true,
          isOnboardingComplete: true,
          createdAt: true,
          lastLoginAt: true,
          _count: {
            select: {
              enrollments: true,
              teachingCourses: true
            }
          }
        },
        orderBy: { [sortBy]: sortOrder },
        skip,
        take: parseInt(limit)
      }),
      prisma.user.count({ where })
    ]);

    res.json({
      success: true,
      users: users.map(u => ({
        ...u,
        enrollmentCount: u._count.enrollments,
        teachingCount: u._count.teachingCourses
      })),
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    next(error);
  }
});

// Get single user details
router.get('/users/:id', async (req, res, next) => {
  try {
    const { id } = req.params;

    const user = await prisma.user.findUnique({
      where: { id },
      include: {
        enrollments: {
          include: {
            course: {
              select: { id: true, code: true, name: true }
            }
          }
        },
        teachingCourses: {
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

    // Remove password from response
    const { password, ...userWithoutPassword } = user;

    res.json({
      success: true,
      user: userWithoutPassword
    });
  } catch (error) {
    next(error);
  }
});

// Create new user
router.post('/users',
  [
    body('email').isEmail().normalizeEmail(),
    body('password').isLength({ min: 6 }),
    body('name').trim().notEmpty(),
    body('role').isIn(['STUDENT', 'PROFESSOR', 'ADMIN']),
    validate
  ],
  async (req, res, next) => {
    try {
      const { email, password, name, role, studentId, departmentId, programId, level, gpa } = req.body;

      // Check existing
      const existing = await prisma.user.findUnique({ where: { email } });
      if (existing) {
        throw new ApiError(409, 'User with this email already exists');
      }

      const hashedPassword = await bcrypt.hash(password, 12);

      const user = await prisma.user.create({
        data: {
          email,
          password: hashedPassword,
          name,
          role,
          studentId: role === 'STUDENT' ? (studentId || `${Date.now().toString().slice(-8)}`) : null,
          departmentId,
          programId: role === 'STUDENT' ? programId : null,
          level,
          gpa,
          isVerified: true, // Admin-created users are verified
          isOnboardingComplete: role !== 'STUDENT' // Non-students don't need onboarding
        },
        include: {
          department: { select: { id: true, code: true, name: true } },
          program: { select: { id: true, code: true, name: true } }
        }
      });

      logger.info(`✅ Admin created user: ${email} (${role})`);

      const { password: _, ...userWithoutPassword } = user;
      res.status(201).json({
        success: true,
        user: userWithoutPassword
      });
    } catch (error) {
      next(error);
    }
  }
);

// Update user
router.put('/users/:id',
  [
    param('id').notEmpty(),
    body('name').optional().trim().notEmpty(),
    body('role').optional().isIn(['STUDENT', 'PROFESSOR', 'ADMIN']),
    body('isActive').optional().isBoolean(),
    body('isVerified').optional().isBoolean(),
    validate
  ],
  async (req, res, next) => {
    try {
      const { id } = req.params;
      const { name, role, isActive, isVerified, departmentId, programId, level, gpa } = req.body;

      const user = await prisma.user.update({
        where: { id },
        data: {
          ...(name && { name }),
          ...(role && { role }),
          ...(isActive !== undefined && { isActive }),
          ...(isVerified !== undefined && { isVerified }),
          ...(departmentId !== undefined && { departmentId }),
          ...(programId !== undefined && { programId }),
          ...(level !== undefined && { level }),
          ...(gpa !== undefined && { gpa })
        },
        include: {
          department: { select: { id: true, code: true, name: true } },
          program: { select: { id: true, code: true, name: true } }
        }
      });

      logger.info(`✅ Admin updated user: ${user.email}`);

      const { password, ...userWithoutPassword } = user;
      res.json({
        success: true,
        user: userWithoutPassword
      });
    } catch (error) {
      next(error);
    }
  }
);

// Reset user password
router.post('/users/:id/reset-password',
  [
    param('id').notEmpty(),
    body('newPassword').isLength({ min: 6 }),
    validate
  ],
  async (req, res, next) => {
    try {
      const { id } = req.params;
      const { newPassword } = req.body;

      const hashedPassword = await bcrypt.hash(newPassword, 12);

      await prisma.user.update({
        where: { id },
        data: { password: hashedPassword }
      });

      logger.info(`✅ Admin reset password for user: ${id}`);

      res.json({
        success: true,
        message: 'Password reset successfully'
      });
    } catch (error) {
      next(error);
    }
  }
);

// Delete user
router.delete('/users/:id', async (req, res, next) => {
  try {
    const { id } = req.params;

    // Prevent self-deletion
    if (id === req.user.id) {
      throw new ApiError(400, 'Cannot delete your own account');
    }

    const user = await prisma.user.findUnique({ where: { id } });
    if (!user) {
      throw new ApiError(404, 'User not found');
    }

    await prisma.user.delete({ where: { id } });

    logger.info(`✅ Admin deleted user: ${user.email}`);

    res.json({
      success: true,
      message: 'User deleted successfully'
    });
  } catch (error) {
    next(error);
  }
});

// ============ COURSE MANAGEMENT ============

// Get all courses
router.get('/courses', async (req, res, next) => {
  try {
    const { search, category, isActive, page = 1, limit = 20 } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const where = {
      ...(search && {
        OR: [
          { name: { contains: search } },
          { code: { contains: search } }
        ]
      }),
      ...(category && { category: category.toUpperCase() }),
      ...(isActive !== undefined && { isActive: isActive === 'true' })
    };

    const [courses, total] = await Promise.all([
      prisma.course.findMany({
        where,
        include: {
          instructors: {
            include: {
              user: {
                select: { id: true, name: true, email: true }
              }
            }
          },
          _count: {
            select: { enrollments: true, content: true, tasks: true }
          }
        },
        orderBy: { code: 'asc' },
        skip,
        take: parseInt(limit)
      }),
      prisma.course.count({ where })
    ]);

    res.json({
      success: true,
      courses: courses.map(c => ({
        id: c.id,
        code: c.code,
        name: c.name,
        category: c.category,
        creditHours: c.creditHours,
        isActive: c.isActive,
        instructors: c.instructors.map(i => ({
          id: i.user.id,
          name: i.user.name,
          email: i.user.email,
          isPrimary: i.isPrimary
        })),
        stats: {
          enrollments: c._count.enrollments,
          content: c._count.content,
          tasks: c._count.tasks
        }
      })),
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    next(error);
  }
});

// Create course
router.post('/courses',
  [
    body('code').trim().notEmpty().withMessage('Course code is required'),
    body('name').trim().notEmpty().withMessage('Course name is required'),
    body('category').isIn(['COMP', 'MATH', 'CHEM', 'PHYS', 'HIST', 'ENG', 'GENERAL']),
    body('creditHours').optional().isInt({ min: 1, max: 6 }),
    body('description').optional().isString(),
    validate
  ],
  async (req, res, next) => {
    try {
      const { code, name, category, creditHours = 3, description, semester, year } = req.body;

      // Check existing
      const existing = await prisma.course.findUnique({ where: { code } });
      if (existing) {
        throw new ApiError(409, 'Course with this code already exists');
      }

      const course = await prisma.course.create({
        data: {
          code,
          name,
          category,
          creditHours,
          description,
          semester,
          year
        }
      });

      logger.info(`✅ Admin created course: ${code}`);

      res.status(201).json({
        success: true,
        course
      });
    } catch (error) {
      next(error);
    }
  }
);

// Update course
router.put('/courses/:id',
  [
    param('id').notEmpty(),
    body('name').optional().trim().notEmpty(),
    body('category').optional().isIn(['COMP', 'MATH', 'CHEM', 'PHYS', 'HIST', 'ENG', 'GENERAL']),
    body('creditHours').optional().isInt({ min: 1, max: 6 }),
    body('isActive').optional().isBoolean(),
    validate
  ],
  async (req, res, next) => {
    try {
      const { id } = req.params;
      const { name, category, creditHours, description, isActive, semester, year } = req.body;

      const course = await prisma.course.update({
        where: { id },
        data: {
          ...(name && { name }),
          ...(category && { category }),
          ...(creditHours && { creditHours }),
          ...(description !== undefined && { description }),
          ...(isActive !== undefined && { isActive }),
          ...(semester !== undefined && { semester }),
          ...(year !== undefined && { year })
        }
      });

      logger.info(`✅ Admin updated course: ${course.code}`);

      res.json({
        success: true,
        course
      });
    } catch (error) {
      next(error);
    }
  }
);

// Delete course
router.delete('/courses/:id', async (req, res, next) => {
  try {
    const { id } = req.params;

    const course = await prisma.course.findUnique({ where: { id } });
    if (!course) {
      throw new ApiError(404, 'Course not found');
    }

    await prisma.course.delete({ where: { id } });

    logger.info(`✅ Admin deleted course: ${course.code}`);

    res.json({
      success: true,
      message: 'Course deleted successfully'
    });
  } catch (error) {
    next(error);
  }
});

// ============ INSTRUCTOR ASSIGNMENT ============

// Assign professor to course
router.post('/courses/:courseId/instructors',
  [
    param('courseId').notEmpty(),
    body('userId').notEmpty().withMessage('User ID is required'),
    body('isPrimary').optional().isBoolean(),
    validate
  ],
  async (req, res, next) => {
    try {
      const { courseId } = req.params;
      const { userId, isPrimary = false } = req.body;

      // Verify course exists
      const course = await prisma.course.findUnique({ where: { id: courseId } });
      if (!course) {
        throw new ApiError(404, 'Course not found');
      }

      // Verify user is a professor
      const user = await prisma.user.findUnique({ where: { id: userId } });
      if (!user || user.role !== 'PROFESSOR') {
        throw new ApiError(400, 'User must be a professor');
      }

      // Create assignment
      await prisma.courseInstructor.upsert({
        where: {
          userId_courseId: { userId, courseId }
        },
        update: { isPrimary },
        create: { userId, courseId, isPrimary }
      });

      logger.info(`✅ Assigned ${user.email} to course ${course.code}`);

      res.json({
        success: true,
        message: 'Instructor assigned successfully'
      });
    } catch (error) {
      next(error);
    }
  }
);

// Remove instructor from course
router.delete('/courses/:courseId/instructors/:userId', async (req, res, next) => {
  try {
    const { courseId, userId } = req.params;

    await prisma.courseInstructor.delete({
      where: {
        userId_courseId: { userId, courseId }
      }
    });

    logger.info(`✅ Removed instructor ${userId} from course ${courseId}`);

    res.json({
      success: true,
      message: 'Instructor removed successfully'
    });
  } catch (error) {
    next(error);
  }
});

// ============ COURSE SCHEDULE ============

// Add schedule slot to course
router.post('/courses/:courseId/schedule',
  [
    param('courseId').notEmpty(),
    body('dayOfWeek').isIn(['SUNDAY', 'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY']),
    body('startTime').matches(/^\d{2}:\d{2}$/),
    body('endTime').matches(/^\d{2}:\d{2}$/),
    body('location').optional().isString(),
    validate
  ],
  async (req, res, next) => {
    try {
      const { courseId } = req.params;
      const { dayOfWeek, startTime, endTime, location } = req.body;

      const schedule = await prisma.courseSchedule.create({
        data: {
          courseId,
          dayOfWeek,
          startTime,
          endTime,
          location
        }
      });

      res.status(201).json({
        success: true,
        schedule
      });
    } catch (error) {
      next(error);
    }
  }
);

// Delete schedule slot
router.delete('/courses/:courseId/schedule/:scheduleId', async (req, res, next) => {
  try {
    const { scheduleId } = req.params;

    await prisma.courseSchedule.delete({
      where: { id: parseInt(scheduleId) }
    });

    res.json({
      success: true,
      message: 'Schedule slot removed'
    });
  } catch (error) {
    next(error);
  }
});

// ============ PROFESSORS LIST ============
// ============ PROFESSOR MANAGEMENT ============

// Get all professors with filtering, search, and detailed info
router.get('/professors', async (req, res, next) => {
  try {
    const { search, departmentId, page = 1, limit = 20 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const where = {
      role: 'PROFESSOR',
      ...(search && {
        OR: [
          { name: { contains: search } },
          { email: { contains: search } }
        ]
      }),
      ...(departmentId && { departmentId })
    };

    const [professors, total] = await Promise.all([
      prisma.user.findMany({
        where,
        select: {
          id: true,
          name: true,
          nameAr: true,
          email: true,
          phone: true,
          avatar: true,
          isActive: true,
          createdAt: true,
          department: {
            select: { id: true, code: true, name: true }
          },
          programsTeaching: {
            include: {
              program: {
                select: { id: true, code: true, name: true }
              }
            }
          },
          teachingCourses: {
            include: {
              course: {
                select: { id: true, code: true, name: true }
              }
            }
          },
          _count: {
            select: { 
              teachingCourses: true,
              programsTeaching: true,
              announcementsCreated: true,
              tasksCreated: true
            }
          }
        },
        orderBy: { name: 'asc' },
        skip,
        take: parseInt(limit)
      }),
      prisma.user.count({ where })
    ]);

    res.json({
      success: true,
      professors: professors.map(p => ({
        id: p.id,
        name: p.name,
        nameAr: p.nameAr,
        email: p.email,
        phone: p.phone,
        avatar: p.avatar,
        isActive: p.isActive,
        createdAt: p.createdAt,
        department: p.department,
        programs: p.programsTeaching.map(pt => pt.program),
        courses: p.teachingCourses.map(tc => ({
          ...tc.course,
          isPrimary: tc.isPrimary
        })),
        stats: {
          courses: p._count.teachingCourses,
          programs: p._count.programsTeaching,
          announcements: p._count.announcementsCreated,
          tasks: p._count.tasksCreated
        }
      })),
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    next(error);
  }
});

// Get single professor details
router.get('/professors/:id', async (req, res, next) => {
  try {
    const { id } = req.params;

    const professor = await prisma.user.findFirst({
      where: { id, role: 'PROFESSOR' },
      include: {
        department: true,
        programsTeaching: {
          include: {
            program: {
              include: { department: { select: { name: true } } }
            }
          }
        },
        teachingCourses: {
          include: {
            course: {
              select: { id: true, code: true, name: true, creditHours: true }
            }
          }
        }
      }
    });

    if (!professor) {
      throw new ApiError(404, 'Professor not found');
    }

    const { password, ...professorData } = professor;
    res.json({ success: true, professor: professorData });
  } catch (error) {
    next(error);
  }
});

// Update professor's department
router.put('/professors/:id/department',
  [
    param('id').notEmpty(),
    body('departmentId').notEmpty().withMessage('Department ID is required'),
    validate
  ],
  async (req, res, next) => {
    try {
      const { id } = req.params;
      const { departmentId } = req.body;

      // Verify department exists
      const dept = await prisma.department.findUnique({ where: { id: departmentId } });
      if (!dept) {
        throw new ApiError(404, 'Department not found');
      }

      const professor = await prisma.user.update({
        where: { id },
        data: { departmentId },
        include: {
          department: { select: { id: true, code: true, name: true } }
        }
      });

      logger.info(`✅ Professor ${professor.email} moved to department ${dept.name}`);

      res.json({
        success: true,
        message: `Professor assigned to ${dept.name}`,
        professor: {
          id: professor.id,
          name: professor.name,
          department: professor.department
        }
      });
    } catch (error) {
      next(error);
    }
  }
);

// Assign professor to a program (for teaching)
router.post('/professors/:id/programs',
  [
    param('id').notEmpty(),
    body('programId').notEmpty().withMessage('Program ID is required'),
    validate
  ],
  async (req, res, next) => {
    try {
      const { id } = req.params;
      const { programId } = req.body;

      // Verify professor exists
      const professor = await prisma.user.findFirst({ where: { id, role: 'PROFESSOR' } });
      if (!professor) {
        throw new ApiError(404, 'Professor not found');
      }

      // Verify program exists
      const program = await prisma.program.findUnique({ 
        where: { id: programId },
        include: { department: true }
      });
      if (!program) {
        throw new ApiError(404, 'Program not found');
      }

      await prisma.programInstructor.upsert({
        where: { professorId_programId: { professorId: id, programId } },
        update: {},
        create: { professorId: id, programId }
      });

      logger.info(`✅ Professor ${professor.email} can now teach in ${program.name}`);

      res.json({
        success: true,
        message: `Professor can now teach in ${program.name} program`
      });
    } catch (error) {
      next(error);
    }
  }
);

// Remove professor from a program
router.delete('/professors/:id/programs/:programId', async (req, res, next) => {
  try {
    const { id, programId } = req.params;

    await prisma.programInstructor.delete({
      where: { professorId_programId: { professorId: id, programId } }
    });

    res.json({ success: true, message: 'Professor removed from program' });
  } catch (error) {
    next(error);
  }
});

// Get professor's assigned courses (the ones they can select from when adding content)
router.get('/professors/:id/courses', async (req, res, next) => {
  try {
    const { id } = req.params;

    const courses = await prisma.courseInstructor.findMany({
      where: { userId: id },
      include: {
        course: {
          include: {
            _count: { select: { enrollments: true, content: true, tasks: true } }
          }
        }
      }
    });

    res.json({
      success: true,
      courses: courses.map(c => ({
        id: c.course.id,
        code: c.course.code,
        name: c.course.name,
        isPrimary: c.isPrimary,
        stats: {
          students: c.course._count.enrollments,
          content: c.course._count.content,
          tasks: c.course._count.tasks
        }
      }))
    });
  } catch (error) {
    next(error);
  }
});

// Deactivate professor
router.put('/professors/:id/deactivate', async (req, res, next) => {
  try {
    const { id } = req.params;

    await prisma.user.update({
      where: { id },
      data: { isActive: false }
    });

    logger.info(`✅ Professor ${id} deactivated`);
    res.json({ success: true, message: 'Professor deactivated' });
  } catch (error) {
    next(error);
  }
});

// Activate professor
router.put('/professors/:id/activate', async (req, res, next) => {
  try {
    const { id } = req.params;

    await prisma.user.update({
      where: { id },
      data: { isActive: true }
    });

    logger.info(`✅ Professor ${id} activated`);
    res.json({ success: true, message: 'Professor activated' });
  } catch (error) {
    next(error);
  }
});

// ============ FACULTIES ============

router.get('/faculties', async (req, res, next) => {
  try {
    const faculties = await prisma.faculty.findMany({
      include: {
        departments: {
          select: { id: true, code: true, name: true }
        },
        _count: {
          select: { departments: true }
        }
      },
      orderBy: { name: 'asc' }
    });

    res.json({
      success: true,
      faculties: faculties.map(f => ({
        id: f.id,
        code: f.code,
        name: f.name,
        description: f.description,
        departments: f.departments,
        departmentCount: f._count.departments
      }))
    });
  } catch (error) {
    next(error);
  }
});

router.post('/faculties',
  [
    body('code').trim().notEmpty(),
    body('name').trim().notEmpty(),
    validate
  ],
  async (req, res, next) => {
    try {
      const { code, name, description } = req.body;

      const faculty = await prisma.faculty.create({
        data: { code, name, description }
      });

      res.status(201).json({ success: true, faculty });
    } catch (error) {
      next(error);
    }
  }
);

// ============ DEPARTMENTS ============

router.get('/departments', async (req, res, next) => {
  try {
    const { facultyId } = req.query;

    const departments = await prisma.department.findMany({
      where: facultyId ? { facultyId } : undefined,
      include: {
        faculty: {
          select: { id: true, code: true, name: true }
        },
        programs: {
          select: { id: true, code: true, name: true }
        },
        _count: {
          select: { users: true, courses: true, programs: true }
        }
      },
      orderBy: { name: 'asc' }
    });

    res.json({
      success: true,
      departments: departments.map(d => ({
        id: d.id,
        code: d.code,
        name: d.name,
        description: d.description,
        faculty: d.faculty,
        programs: d.programs,
        stats: {
          users: d._count.users,
          courses: d._count.courses,
          programs: d._count.programs
        }
      }))
    });
  } catch (error) {
    next(error);
  }
});

router.post('/departments',
  [
    body('code').trim().notEmpty(),
    body('name').trim().notEmpty(),
    body('facultyId').notEmpty(),
    validate
  ],
  async (req, res, next) => {
    try {
      const { code, name, description, facultyId } = req.body;

      const department = await prisma.department.create({
        data: { code, name, description, facultyId }
      });

      res.status(201).json({ success: true, department });
    } catch (error) {
      next(error);
    }
  }
);

router.delete('/departments/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    await prisma.department.delete({ where: { id } });
    res.json({ success: true, message: 'Department deleted' });
  } catch (error) {
    next(error);
  }
});

// ============ PROGRAMS ============

router.get('/programs', async (req, res, next) => {
  try {
    const { departmentId } = req.query;

    const programs = await prisma.program.findMany({
      where: departmentId ? { departmentId } : undefined,
      include: {
        department: {
          select: { id: true, code: true, name: true }
        },
        _count: {
          select: { students: true }
        }
      },
      orderBy: { name: 'asc' }
    });

    res.json({
      success: true,
      programs: programs.map(p => ({
        id: p.id,
        code: p.code,
        name: p.name,
        degree: p.degree,
        creditHours: p.creditHours,
        department: p.department,
        studentCount: p._count.students
      }))
    });
  } catch (error) {
    next(error);
  }
});

router.post('/programs',
  [
    body('code').trim().notEmpty(),
    body('name').trim().notEmpty(),
    body('departmentId').notEmpty(),
    body('degree').isIn(['ASSOCIATE', 'BACHELOR', 'MASTER', 'DOCTORATE']),
    body('creditHours').isInt({ min: 60, max: 200 }),
    validate
  ],
  async (req, res, next) => {
    try {
      const { code, name, departmentId, degree, creditHours } = req.body;

      const program = await prisma.program.create({
        data: { code, name, departmentId, degree, creditHours }
      });

      res.status(201).json({ success: true, program });
    } catch (error) {
      next(error);
    }
  }
);

router.delete('/programs/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    await prisma.program.delete({ where: { id } });
    res.json({ success: true, message: 'Program deleted' });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
