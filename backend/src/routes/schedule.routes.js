/**
 * Schedule Routes
 */
const express = require('express');
const { body, param, query } = require('express-validator');

const router = express.Router();
const { prisma } = require('../utils/database');
const { validate } = require('../middleware/validate');
const { authenticate } = require('../middleware/auth');
const { ApiError } = require('../middleware/errorHandler');

// ============ GET UPCOMING EVENTS ============

router.get('/upcoming',
  authenticate,
  async (req, res, next) => {
    try {
      const days = parseInt(req.query.days) || 7;
      const startDate = new Date();
      const endDate = new Date();
      endDate.setDate(endDate.getDate() + days);

      // Re-use the main logic by redirecting or calling internal function?
      // Easier to copy logic or make a shared service function.
      // For now, duplicate specific logic for safety and speed.

       const where = {
        userId: req.user.id,
        startTime: {
          gte: startDate,
          lte: endDate
        }
      };

      const events = await prisma.scheduleEvent.findMany({
        where,
        orderBy: { startTime: 'asc' }
      });
      
      // Also get course schedule for enrolled courses
      const enrollments = await prisma.enrollment.findMany({
        where: { userId: req.user.id, status: 'ENROLLED' },
        include: {
          course: {
            include: {
              scheduleSlots: true,
              instructors: {
                include: {
                  user: {
                    select: { name: true }
                  }
                }
              }
            }
          }
        }
      });

      const courseEvents = [];
      const today = new Date();
      // Calculate relevant dates within range
      
      // Simple logic: iterate days in range
      for (let i = 0; i < days; i++) {
        const loopDate = new Date(today);
        loopDate.setDate(today.getDate() + i);
        const dayName = ['SUNDAY', 'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY'][loopDate.getDay()];
        
        for (const enrollment of enrollments) {
          for (const slot of enrollment.course.scheduleSlots) {
             if (slot.dayOfWeek === dayName) {
                const [startHour, startMin] = slot.startTime.split(':').map(Number);
                const [endHour, endMin] = slot.endTime.split(':').map(Number);
                
                const startTime = new Date(loopDate);
                startTime.setHours(startHour, startMin, 0, 0);
                
                const endTime = new Date(loopDate);
                endTime.setHours(endHour, endMin, 0, 0);
                
                 const instructor = enrollment.course.instructors.find(ins => ins.isPrimary)?.user?.name ||
                                    enrollment.course.instructors[0]?.user?.name || 'TBA';

                 courseEvents.push({
                    id: `${enrollment.course.id}-${slot.id}-${loopDate.getTime()}`,
                    title: `${enrollment.course.code}: ${enrollment.course.name}`,
                    eventType: 'LECTURE',
                    startTime,
                    endTime,
                    location: slot.location,
                    instructor,
                    isRecurring: true,
                    courseId: enrollment.course.id
                 });
             }
          }
        }
      }
      
      // Determine what to return
      res.json({
        success: true,
        events: [
          ...events.map(e => ({
            id: e.id,
            title: e.title,
            description: e.description,
            eventType: e.eventType,
            startTime: e.startTime,
            endTime: e.endTime,
            location: e.location,
            isAllDay: e.isAllDay,
            isRecurring: e.isRecurring
          })),
          ...courseEvents
        ]
      });

    } catch (error) {
      next(error);
    }
  }
);


// ============ GET SCHEDULE EVENTS ============

router.get('/',
  authenticate,
  async (req, res, next) => {
    try {
      const { startDate, endDate, type } = req.query;

      // Build where clause
      const where = {
        userId: req.user.id,
        ...(type && { eventType: type }),
        ...(startDate && endDate && {
          startTime: {
            gte: new Date(startDate),
            lte: new Date(endDate)
          }
        })
      };

      const events = await prisma.scheduleEvent.findMany({
        where,
        orderBy: { startTime: 'asc' }
      });

      // Also get course schedule for enrolled courses
      const enrollments = await prisma.enrollment.findMany({
        where: { userId: req.user.id, status: 'ENROLLED' },
        include: {
          course: {
            include: {
              scheduleSlots: true,
              instructors: {
                include: {
                  user: {
                    select: { name: true }
                  }
                }
              }
            }
          }
        }
      });

      // Convert recurring course schedules to events for the requested range
      const courseEvents = [];
      
      // Default to wider range (-30 to +60 days) to ensure calendar population
      const start = startDate ? new Date(startDate) : new Date(new Date().setDate(new Date().getDate() - 30));
      const end = endDate ? new Date(endDate) : new Date(new Date().setDate(new Date().getDate() + 60));
      
      const daysMap = ['SUNDAY', 'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY'];

      // logger.info(`Generating schedule for ${req.user.email} from ${start.toISOString()} to ${end.toISOString()}`);
      console.log(`Generating schedule for ${req.user.email} from ${start.toISOString()} to ${end.toISOString()}`);
      console.log(`Found ${enrollments.length} enrollments`);

      // Loop through each day in the range
      for (let d = new Date(start); d <= end; d.setDate(d.getDate() + 1)) {
          const currentDayName = daysMap[d.getDay()];
          
          for (const enrollment of enrollments) {
              for (const slot of enrollment.course.scheduleSlots) {
                  if (slot.dayOfWeek === currentDayName) {
                      const [startHour, startMin] = slot.startTime.split(':').map(Number);
                      const [endHour, endMin] = slot.endTime.split(':').map(Number);
                      
                      const startTime = new Date(d);
                      startTime.setHours(startHour, startMin, 0, 0);
                      
                      const endTime = new Date(d);
                      endTime.setHours(endHour, endMin, 0, 0);
                      
                      const instructor = enrollment.course.instructors.find(i => i.isPrimary)?.user?.name ||
                                        enrollment.course.instructors[0]?.user?.name || 'TBA';

                      courseEvents.push({
                          id: `${enrollment.course.id}-${slot.id}-${d.getTime()}`,
                          title: `${enrollment.course.code}: ${enrollment.course.name}`,
                          eventType: 'LECTURE',
                          startTime,
                          endTime,
                          location: slot.location,
                          instructor,
                          isRecurring: true,
                          courseId: enrollment.course.id
                      });
                  }
              }
          }
      }

      // Also add upcoming exams/assignments from tasks
      const upcomingTasks = await prisma.task.findMany({
        where: {
          taskType: { in: ['EXAM', 'ASSIGNMENT'] },
          dueDate: { gte: new Date() },
          course: {
            enrollments: {
              some: { userId: req.user.id, status: 'ENROLLED' }
            }
          }
        },
        include: {
          course: {
            select: { code: true, name: true }
          }
        },
        orderBy: { dueDate: 'asc' },
        take: 20
      });

      const taskEvents = upcomingTasks.map(task => ({
        id: `task-${task.id}`,
        title: `${task.taskType === 'EXAM' ? '📝 Exam' : '📋 Due'}: ${task.title}`,
        eventType: task.taskType === 'EXAM' ? 'EXAM' : 'ASSIGNMENT_DUE',
        startTime: task.dueDate,
        endTime: task.dueDate,
        isAllDay: task.taskType !== 'EXAM',
        courseCode: task.course?.code,
        taskId: task.id
      }));

      res.json({
        success: true,
        events: [
          ...events.map(e => ({
            id: e.id,
            title: e.title,
            description: e.description,
            eventType: e.eventType,
            startTime: e.startTime,
            endTime: e.endTime,
            location: e.location,
            isAllDay: e.isAllDay,
            isRecurring: e.isRecurring
          })),
          ...courseEvents,
          ...taskEvents
        ]
      });
    } catch (error) {
      next(error);
    }
  }
);

// ============ CREATE PERSONAL EVENT ============

router.post('/',
  authenticate,
  [
    body('title').trim().notEmpty().withMessage('Title is required'),
    body('startTime').isISO8601().withMessage('Start time is required'),
    body('endTime').isISO8601().withMessage('End time is required'),
    body('eventType').optional().isIn(['LECTURE', 'EXAM', 'ASSIGNMENT_DUE', 'MEETING', 'OFFICE_HOURS', 'PERSONAL']),
    body('location').optional().isString(),
    body('description').optional().isString(),
    body('isAllDay').optional().isBoolean(),
    validate
  ],
  async (req, res, next) => {
    try {
      const { title, startTime, endTime, eventType = 'PERSONAL', location, description, isAllDay } = req.body;

      // Validate times
      const start = new Date(startTime);
      const end = new Date(endTime);

      if (end <= start) {
        throw new ApiError(400, 'End time must be after start time');
      }

      const event = await prisma.scheduleEvent.create({
        data: {
          title,
          startTime: start,
          endTime: end,
          eventType,
          location,
          description,
          isAllDay: isAllDay || false,
          userId: req.user.id
        }
      });

      res.status(201).json({
        success: true,
        event
      });
    } catch (error) {
      next(error);
    }
  }
);

// ============ UPDATE EVENT ============

router.put('/:id',
  authenticate,
  [
    param('id').notEmpty(),
    body('title').optional().trim().notEmpty(),
    body('startTime').optional().isISO8601(),
    body('endTime').optional().isISO8601(),
    body('location').optional().isString(),
    body('description').optional().isString(),
    validate
  ],
  async (req, res, next) => {
    try {
      const { id } = req.params;
      const { title, startTime, endTime, location, description } = req.body;

      const event = await prisma.scheduleEvent.findFirst({
        where: { id, userId: req.user.id }
      });

      if (!event) {
        throw new ApiError(404, 'Event not found');
      }

      const updated = await prisma.scheduleEvent.update({
        where: { id },
        data: {
          ...(title && { title }),
          ...(startTime && { startTime: new Date(startTime) }),
          ...(endTime && { endTime: new Date(endTime) }),
          ...(location !== undefined && { location }),
          ...(description !== undefined && { description })
        }
      });

      res.json({
        success: true,
        event: updated
      });
    } catch (error) {
      next(error);
    }
  }
);

// ============ DELETE EVENT ============

router.delete('/:id',
  authenticate,
  async (req, res, next) => {
    try {
      const { id } = req.params;

      const event = await prisma.scheduleEvent.findFirst({
        where: { id, userId: req.user.id }
      });

      if (!event) {
        throw new ApiError(404, 'Event not found');
      }

      await prisma.scheduleEvent.delete({
        where: { id }
      });

      res.json({
        success: true,
        message: 'Event deleted'
      });
    } catch (error) {
      next(error);
    }
  }
);

module.exports = router;
