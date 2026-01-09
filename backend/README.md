# College Guide - Backend API

Production-ready backend for the College Guide mobile application, featuring a modern database schema with Prisma ORM, push notifications, and comprehensive admin functionality.

## 🚀 Tech Stack

- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Database**: MySQL with Prisma ORM
- **Authentication**: JWT with bcrypt
- **Email**: Nodemailer (SMTP)
- **Push Notifications**: Firebase Cloud Messaging (FCM)
- **Logging**: Winston

## 📁 Project Structure

```
backend/
├── prisma/
│   ├── schema.prisma    # Database schema with relations
│   └── seed.js          # Database seeding script
├── src/
│   ├── index.js         # Main server entry point
│   ├── middleware/
│   │   ├── auth.js      # JWT authentication
│   │   ├── errorHandler.js
│   │   └── validate.js  # Request validation
│   ├── routes/
│   │   ├── admin.routes.js
│   │   ├── announcement.routes.js
│   │   ├── auth.routes.js
│   │   ├── content.routes.js
│   │   ├── course.routes.js
│   │   ├── notification.routes.js
│   │   ├── schedule.routes.js
│   │   ├── task.routes.js
│   │   └── user.routes.js
│   ├── services/
│   │   ├── email.service.js
│   │   └── notification.service.js
│   └── utils/
│       ├── database.js
│       └── logger.js
├── admin/
│   └── index.html       # Admin panel web interface
├── .env.example         # Environment variables template
└── package.json
```

## 🗄️ Database Schema

The Prisma schema includes proper relations:

- **User** - Students, Professors, and Admins
- **Course** - With category, credit hours, schedules
- **Enrollment** - Many-to-many: User ↔ Course
- **CourseInstructor** - Many-to-many: Professor ↔ Course
- **CourseContent** - Lectures, materials, videos
- **Task** - Assignments, exams, quizzes
- **Announcement** - Course and general announcements
- **Notification** - In-app notifications with push support
- **ScheduleEvent** - Personal calendar events
- **CourseSchedule** - Weekly recurring course slots

## 🛠️ Setup

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Configure Environment

Copy `.env.example` to `.env` and configure:

```env
# Database (MySQL)
DATABASE_URL="mysql://user:password@localhost:3306/college_guide"

# Server
PORT=3000
NODE_ENV=development

# JWT
JWT_SECRET=your-super-secret-key
JWT_EXPIRES_IN=7d

# Email (Gmail SMTP)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password

# Firebase (Push Notifications)
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@project.iam.gserviceaccount.com

# Admin
ADMIN_EMAIL=admin@college.edu
ADMIN_PASSWORD=admin123
```

### 3. Setup Database

```bash
# Generate Prisma Client
npm run prisma:generate

# Push schema to database
npm run prisma:push

# Seed with sample data
npm run prisma:seed
```

### 4. Run Server

```bash
# Development
npm run dev

# Production
npm start
```

## 📡 API Endpoints

### Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | Login |
| POST | `/api/auth/verify` | Verify email |
| POST | `/api/auth/forgot-password` | Request password reset |
| POST | `/api/auth/reset-password` | Reset password |
| GET | `/api/auth/me` | Get current user |
| POST | `/api/auth/fcm-token` | Update push notification token |

### Users

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/users/:email` | Get user by email |
| PUT | `/api/users/:email` | Update user profile |
| POST | `/api/users/complete-onboarding` | Complete course selection |

### Courses

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/courses` | List all courses |
| GET | `/api/courses/:id` | Get course details |
| GET | `/api/courses/:id/content` | Get course content |
| GET | `/api/courses/:id/tasks` | Get course tasks |
| GET | `/api/courses/:id/students` | Get enrolled students (Prof) |
| GET | `/api/courses/professor/:email` | Get professor's courses |
| POST | `/api/courses/:id/enroll` | Enroll in course |
| DELETE | `/api/courses/:id/enroll` | Drop course |

### Content (Professor Only)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/content` | Create lecture/content |
| POST | `/api/content/assignment` | Create assignment |
| POST | `/api/content/exam` | Create exam |
| PUT | `/api/content/:id` | Update content |
| DELETE | `/api/content/:id` | Delete content |

### Tasks

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/tasks` | Get all tasks |
| GET | `/api/tasks/pending` | Get pending tasks |
| POST | `/api/tasks` | Create personal task |
| PUT | `/api/tasks/:id` | Update task |
| POST | `/api/tasks/:id/complete` | Mark task complete |

### Notifications

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/notifications` | Get notifications |
| PUT | `/api/notifications/:id/read` | Mark as read |
| PUT | `/api/notifications/read-all` | Mark all as read |

### Admin Panel

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/admin/stats` | Get dashboard stats |
| GET | `/api/admin/users` | List all users |
| POST | `/api/admin/users` | Create user |
| PUT | `/api/admin/users/:id` | Update user |
| DELETE | `/api/admin/users/:id` | Delete user |
| GET | `/api/admin/courses` | List all courses |
| POST | `/api/admin/courses` | Create course |
| PUT | `/api/admin/courses/:id` | Update course |
| DELETE | `/api/admin/courses/:id` | Delete course |
| POST | `/api/admin/courses/:id/instructors` | Assign instructor |
| GET | `/api/admin/professors` | List all professors |

## 🔔 Push Notifications

Push notifications are sent automatically when:

- Professor adds new content → Students get notified
- Professor creates assignment → Students get notified with due date
- Professor schedules exam → Students get notified
- Professor posts announcement → Enrolled students notified

### Firebase Setup

1. Create a Firebase project
2. Enable Cloud Messaging
3. Download service account JSON
4. Add credentials to `.env`

## 🎛️ Admin Panel

Access the admin panel at `http://localhost:3000/admin/` (after adding static file serving).

Features:
- Dashboard with statistics
- User management (CRUD)
- Course management
- Instructor assignment
- Announcements

## 🔐 Role-Based Access

| Role | Permissions |
|------|-------------|
| STUDENT | View content, enroll in courses, manage tasks |
| PROFESSOR | All student + create content, manage students |
| ADMIN | Full access to all resources |

## 📝 Test Accounts

After seeding:

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@college.edu | admin123 |
| Professor | dr.ahmed@college.edu | professor123 |
| Student | student@college.edu | student123 |

## 🧪 Development

```bash
# View database with Prisma Studio
npm run prisma:studio

# Reset database
npm run db:reset
```

## 📦 Deployment Checklist

- [ ] Set `NODE_ENV=production`
- [ ] Configure secure `JWT_SECRET`
- [ ] Set up SSL/HTTPS
- [ ] Configure production database
- [ ] Set up Firebase credentials
- [ ] Configure email SMTP
- [ ] Set up proper logging
- [ ] Configure rate limiting
