# Implementation Plan: Assignment Submission & Grading System

This document outlines the steps to restrict submission access, link submission to task completion, and implement a full grading system for professors.

## Phase 1: Access Control & Logical Refinements

### 1.1 Access Control (Backend)
- [ ] Update `POST /api/tasks/:id/submit` and `POST /api/tasks/:id/unsubmit`.
- [ ] Add a check: `if (req.user.role !== 'STUDENT') throw new ApiError(403, 'Only students can submit assignments');`.

### 1.2 Professor-Specific UI (Frontend)
- [ ] In `AssignmentDetailScreen`, fetch the user's role.
- [ ] **Hide** the "Your Work" (Submission Form) for professors.
- [ ] **Show** a "View Submissions" button for professors that leads to the Grading Page.

### 1.3 Linked Submission & Completion
- [ ] **Backend**: Modify `POST /api/tasks/:id/submit` to automatically set `task.status = 'COMPLETED'` and `task.completedAt = new Date()`.
- [ ] **Backend**: Modify `POST /api/tasks/:id/unsubmit` to revert `task.status = 'PENDING'` (or 'OVERDUE') and `task.completedAt = null`.
- [ ] **Frontend (Task List)**: 
    - In `Task.dart`, update `Checkbox.onChanged`:
        - If unchecking a completed assignment: Trigger the `unsubmitTask` API call with a confirmation dialog.
        - Tapping the task title must always open `AssignmentDetailScreen`, even if marked done.

---

## Phase 2: Comments & Feedback System

### 2.1 Backend Enhancements
- [ ] Verify `TaskSubmission` model has `feedback` (String) and `grade` (Float/String) fields.
- [ ] Create `PATCH /api/tasks/submissions/:submissionId/grade` endpoint:
    - Inputs: `points`, `grade`, `feedback`.
    - Restriction: Only the professor of the course (or Admin) can access this.

---

## Phase 3: Professor Grading Workspace

### 3.1 Home Screen "To-Grade" Widget
- [ ] Create a `GradingOverviewWidget`.
- [ ] Logic: Only visible to users with the `PROFESSOR` role.
- [ ] Display: Count of "Pending Submissions" (assignments submitted but not yet graded).

### 3.2 Grading Dashboard Hierarchy
- [ ] **Course List**: Professor selects which class to grade.
- [ ] **Task List**: Selects specific Assignment, Exam, or Lab.
- [ ] **Submission List**:
    - Display all enrolled students.
    - Status indicators: `Submitted`, `Missing`, `Graded`, `Late`.
- [ ] **Grading Detail View**:
    - Display submitted file (PDF/Image viewer).
    - Display student notes.
    - Form to input: Points, Grade, and Feedback.
    - "Release Grade" button to notify the student.

---

## Technical Considerations
- **Syncing**: Use `ref.invalidate(tasksProvider)` on the frontend after any submission, unsubmission, or grading action.
- **Data Consistency**: Ensure that when a task is "Unsubmitted", the actual completion record in the `tasks` table is correctly synced with the deletion in `task_submissions`.
- **UI/UX**: Use clear visual cues (green for graded, orange for pending) in the professor's dashboard.
