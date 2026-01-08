# Project Implementation Plan & Roadmap

This document outlines the roadmap for upcoming features, refactors, and data integration for the College Guide App.

## 1. Local Task Storage (Priority: High)
**Objective:** Ensure "My Tasks" (Personal Tasks) are reliable and available offline, decoupling them from backend transient failures.

**Strategy:**
- Use `shared_preferences` to store personal tasks locally on the device (SQLite/Isar could be an alternative, but SharedPreferences is sufficient for simple lists).
- **Key:** `user_personal_tasks` (JSON payload).

**Implementation Steps:**
1.  **Modify `DataService`:** 
    - `getTasks()`: Fetch from API (for Assignments/Exams) AND fetch from Local Storage (for Personal Tasks), then merge.
    - `createTask()`: If `type == 'PERSONAL'`, save to Local Storage. Do NOT send to backend (or send as background sync only).
    - `updateTask()`, `deleteTask()`: Handle local updates for personal tasks.
    - Remove reliance on `POST /tasks` for personal items to avoid 500 errors or connectivity issues.

## 2. Professor View Enhancements
**Objective:** Empower professors to manage courses and assignments effectively.

**Features Needed:**
1.  **Assignment Creation UI:**
    - New screen `CreateAssignmentScreen` for professors.
    - Fields: Title, Description, Due Date, Max Points, Related Course (Select from their teaching list).
    - Backend: Uses existing `POST /tasks` (with `taskType: ASSIGNMENT`).
2.  **Submissions & Grading:**
    - View student submissions for an assignment.
    - Enter grades and feedback.
3.  **Course Management:**
    - Edit Course content/syllabus.
    - Upload Materials (PDF/Links).

## 3. Data Integration (Real Data)
**Source:** `std guide.pdf` (Student Guide).

**Objective:** Populate the database with the real Faculty > Department > Program structure and Course Catalog.

**Scope:**
1.  **Hierarchy:**
    - **Faculty**: Faculty of Science (and others if applicable).
    - **Departments**: Math, Physics, Chemistry, Bio, etc.
    - **Programs**: Computer Science, Statistics, Microbiology, etc.
2.  **Courses:**
    - Extract real Course Codes (e.g., COMP101), Names, Credit Hours, and Prerequisites.
3.  **Migration:**
    - Create a script (or manual seed) to populate `Faculty`, `Department`, `Program`, and `Course` tables.
    - Map existing "Mock" users to these real programs.

## 4. Known Issues & Backlog
1.  **Assignment Status Sync:**
    - *Issue:* Student `AssignmentsScreen` shows assignments as "Pending" even after submission because the list relies on the global Task status, not the user's `TaskSubmission` status.
    - *Fix:* Update `GET /tasks` or separate `GET /my-assignments` to join `TaskSubmission` and return the *student's* specific status.
2.  **Calendar Visualization:**
    - *Issue:* Verify `TableCalendar` markers (dots) appear consistently for both Tasks and Lectures.
3.  **Notifications:**
    - *Feature:* Implement FCM (Firebase Cloud Messaging) for real-time announcements.

## 5. Backend Refinement
1.  **Schema Alignment:**
    - Ensure `Prisma` schema fully supports Personal Tasks (`status` field added) and Course Assignments (`TaskSubmission` relation).
2.  **Cleanup:**
    - Remove legacy routes/fields (like the removed `assigneeId`) permanently from codebase.

---
*Created: 2026-01-08*
