# College Guide - Backend Refactor Summary

## Database Schema (Prisma ORM)

### Organizational Hierarchy
```
Faculty (e.g., Engineering, Science, Business)
├── Department (e.g., CS, EE, Math, Physics)
│   ├── Program (e.g., Computer Science BSc, Software Engineering BSc)
│   │   └── Student (enrolled in program)
│   ├── Course (belongs to department)
│   └── Professor (assigned to department)
```

### Entity Relationships

```
User (id, email, password, name, role)
├── role: STUDENT | PROFESSOR | ADMIN
├── departmentId → Department (belongs to)
├── programId → Program (for students only)
├── enrollments → Enrollment[] (student courses)
├── teachingCourses → CourseInstructor[] (professor courses)
├── tasksCreated → Task[] (created assignments/exams)
├── taskSubmissions → TaskSubmission[] (student work)
├── notifications → Notification[]
└── scheduleEvents → ScheduleEvent[]

Course (id, code, name, category, creditHours)
├── departmentId → Department
├── instructors → CourseInstructor[] (professors)
├── enrollments → Enrollment[] (students)
├── content → CourseContent[] (lectures, materials)
├── tasks → Task[] (assignments, exams)
├── scheduleSlots → CourseSchedule[] (weekly timetable)
└── announcements → Announcement[]

Task (id, title, taskType, priority, dueDate, maxPoints)
├── taskType: ASSIGNMENT | EXAM | QUIZ | PROJECT | LAB
├── courseId → Course (optional, can be personal)
├── createdById → User (professor)
└── submissions → TaskSubmission[] (student work)

TaskSubmission (id, status, submittedAt, points, feedback)
├── taskId → Task
├── studentId → User
└── status: PENDING | SUBMITTED | LATE | GRADED | RETURNED
```

### New API Endpoints

#### Admin Panel
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/admin/faculties` | List all faculties |
| POST | `/api/admin/faculties` | Create faculty |
| GET | `/api/admin/departments` | List departments |
| POST | `/api/admin/departments` | Create department |
| DELETE | `/api/admin/departments/:id` | Delete department |
| GET | `/api/admin/programs` | List programs |
| POST | `/api/admin/programs` | Create program |
| DELETE | `/api/admin/programs/:id` | Delete program |

### Test Accounts

After running `npm run prisma:seed`:

| Role | Email | Password | Info |
|------|-------|----------|------|
| Admin | admin@college.edu | admin123 | Full access |
| Professor | dr.ahmed@college.edu | professor123 | CS Dept, teaches CS101/CS201/CS402 |
| Professor | dr.sara@college.edu | professor123 | Math Dept, teaches MATH101 |
| Professor | dr.khalid@college.edu | professor123 | CS Dept, teaches CS301/CS401 |
| Student | student@college.edu | student123 | CS Program, Level 3, GPA 3.45 |
| Student | mona@college.edu | student123 | SE Program, Level 2, GPA 3.78 |

### Files Created/Updated

**Backend:**
- `prisma/schema.prisma` - Complete normalized schema
- `prisma/seed.js` - Sample data with proper relations  
- `src/routes/admin.routes.js` - Faculty/Department/Program management
- `src/routes/*.routes.js` - All API routes updated

**Flutter:**
- `lib/repositories/api_service.dart` - New unified API client
- `lib/screens/professor_dashboard.dart` - Professor UI
- `lib/screens/adaptive_dashboard.dart` - Role-based routing

### Setup Commands

```bash
cd backend
npm install
cp .env.example .env
npm run prisma:generate
npm run prisma:push
npm run prisma:seed
npm run dev
```

### Access Points

- **API**: http://localhost:3000/api
- **Admin Panel**: http://localhost:3000/admin/
- **Health Check**: http://localhost:3000/api/health
