# Exam System Implementation Plan

This document outlines a comprehensive plan to implement a robust Exam and Grading system within the College Guide App. The goal is to allow professors to create rich exams, students to take them securely, and provide advanced grading capabilities, while maintaining compatibility with the current Assignment system.

## Phase 1: Data Modeling & Extensibility (Immediate)

**Objective**: Update the database schema to support complex exam structures without breaking existing assignments.

### Schema Updates
We will leverage `JSON` fields for flexibility in creating various question types (MCQ, Written, True/False) without creating excessive relational tables.

1.  **Users Model**
    *   No major changes needed.

2.  **Task Model (Assignments & Exams)**
    *   Add `questions`: `Json` field to store the array of questions.
    *   Add `settings`: `Json` field for exam specifics (duration, allowBacktracking, shuffleQuestions).
    *   Add `published`: `Boolean` to control visibility before the start time.

3.  **TaskSubmission Model**
    *   Add `answers`: `Json` field to map Question IDs to User Answers.
    *   Add `startedAt`: `DateTime` to track when a student began the exam (for timer enforcement).
    *   Add `snapshots`: `Json` (Optional) for proctoring logs (tab switches, etc.).

### Question Data Structure (JSON)
```json
{
  "id": "uuid",
  "type": "MCQ" | "TEXT" | "TRUE_FALSE",
  "text": "What is 2+2?",
  "points": 5,
  "options": ["3", "4", "5"], // For MCQ
  "correctAnswer": "4" // For Auto-grading
}
```

## Phase 2: Professor Exam Builder (Frontend)

**Objective**: Create an intuitive interface for professors to design exams.

1.  **Exam Creation Wizard**
    *   Basic Info: Title, Description, Date, Duration.
    *   Question Editor:
        *   Dynamic list of questions.
        *   Dropdown to select type (MCQ, Essay, File Upload).
        *   Input fields for Question Text and Options.
        *   "Set Correct Answer" toggle for auto-grading.
    *   Settings:
        *   "Shuffle Questions" toggle.
        *   "Show Results Immediately" toggle.

## Phase 3: Student Exam Interface

**Objective**: A secure and stable environment for taking exams.

1.  **Exam Lobby**
    *   Shows instructions, duration, and "Start Exam" button.
    *   Button only active at `startDate`.

2.  **Exam Runner**
    *   **Timer**: Floating countdown. Auto-submit when time expires.
    *   **State Persistence**: Save answers locally (SQLite/Hive) and sync to backend frequently to prevent data loss on crash.
    *   **Navigation**: "Next/Prev" buttons (if backtracking allowed).
    *   **Submission**: "Submit Exam" button with confirmation.

## Phase 4: Grading System & Dashboard

**Objective**: Streamline the grading process for both Assignments and Exams.

1.  **Grading Dashboard (Professor)**
    *   **Overview**: List of all submissions with status (Graded, Pending, Late).
    *   **Auto-Grading**: System automatically calculates scores for MCQ/True-False questions upon submission.
    *   **Manual Grading Interface**:
        *   Split view: Student's Answer (left) vs Grading Panel (right).
        *   For Assignments: File viewer (PDF/Image).
        *   For Exams: Question-by-question view.
    *   **Feedback**: Text input for overall comments or per-question annotations.

2.  **Gradebook (Student)**
    *   A consolidated "Grades" screen showing all scores.
    *   Detailed view showing breakdown of points and professor feedback.

## Phase 5: Backend Logic

1.  **Auto-Grader Service**
    *   Triggered on `TaskSubmission` creation.
    *   Compares `answers` JSON with `questions` correct answers.
    *   Updates `points` and sets status to `GRADED` (if fully auto-gradable) or `PENDING` (if manual review needed).

2.  **Security**
    *   Server-side validation of submission time vs. Exam duration.
    *   Late submission handling logic.

---

## Migration Steps (Current Task)

1.  **Update Prisma Schema**: Add `questions` and `answers` JSON fields.
2.  **Update Dart Models**: Reflect new fields in `Task` and `TaskSubmission`.
3.  **Implement Grading Dashboard**: Build the UI to list submissions and grade them manually (starts with Assignments, extensible to Exam answers).
