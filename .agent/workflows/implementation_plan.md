---
description: Implementation plan for College Guide App fixes and features
---

# Implementation Plan: College Guide App Fixes & Features

## ✅ COMPLETED Fixes & Improvements

### 1. Robust Application Routing ✅
- **Files:** `lib/main.dart`, `lib/screens/dashboard_shell.dart`, `lib/widgets/custom_bottom_navigation.dart`
- **Changes:**
    - Simplified `/home` route by removing path parameters.
    - Centralized redirection logic in `main.dart` with state-aware checks (`isOnboardingComplete`, `isAuthenticated`).
    - Fixed back buttons in `Tasks`, `Schedule`, `Notifications`, `Navigate`, and `AddContent` screens.
    - Established clear routing standards in `.agent/workflows/routing_workflow.md`.

### 2. High-Performance Task Management ✅
- **Files:** `lib/screens/TaskPages/Task.dart`, `backend/server.js`
- **Changes:**
    - Implemented **Optimistic UI** for Task adding, toggling, and deletion.
    - Tasks appear/disappear instantly; synchronization happens in the background.
    - UI no longer blocks with a loading spinner during API calls.
    - Automatic rollback if API synchronization fails.

### 3. Verification & Password Reset Stability ✅
- **Files:** `backend/server.js`, `lib/screens/auth/verification_page.dart`
- **Changes:**
    - Fixed "Verification Expired" bug by removing redundant timestamp checks in the final reset-password step.
    - Centralized verification validation on the frontend `VerificationPage`.
    - Ensured verification codes are cleaned up only after successful password update.

### 4. Mock Data Elimination (Major Progress) ✅
- **Files:** `backend/server.js`, `lib/repositories/*_repository.dart`
- **Changes:**
    - **Announcements & Schedule**: Fully migrated to MySQL + API.
    - **Courses**: Migrated to MySQL `courses` table with JSON storage for nested content (Schedule, Assignments, Exams).
    - **Tasks**: Using `ApiTaskDatabase` connected to backend.
    - **Repositories**: All core repositories (`Announcement`, `Schedule`, `Course`, `Task`, `Auth`) are now connected to the real API.
    - *Note:* Department/Program list remains in `assets/mock/departments.json` as static configuration data (acceptable for now).

### 5. Profile & Onboarding Improvements ✅
- **Files:** `lib/screens/auth/course_selection_screen.dart`
- **Changes:**
    - Replaced free-text inputs with structured dropdowns for Department, Program, and Level.
    - Implemented filtered program selection based on the chosen department.
    - Verified full profile persistence (GPA, Level, Major) to the database.

---

## 🔲 Remaining Production Readiness Tasks

### Phase 3: Enhanced Data Integration
- [x] **Course Details API**: Transition course assignments, content, and exams from mock data to the database (Done via JSON columns).
- [ ] **Data Migration**: Move initial mock data from JSON files to database seed scripts (Partially done in seed logic).
- [ ] **Search & Filters**: Implement backend-side searching for courses and announcements.

### Phase 4: Push Notifications & Messaging
- [ ] **Push Notifications**: Integrate Firebase Cloud Messaging for real-time alerts.
- [ ] **System Alerts**: Create backend triggers for local notifications (e.g., 10 mins before a lecture).

---

## 📱 Testing Checklist
- [x] Register new user & complete onboarding.
- [x] Verify email and reset password successfully.
- [x] Add/Toggle/Delete tasks with instant UI feedback.
- [x] Navigate between all screens using tab bar and back buttons.
- [x] Verify Announcements and Schedule show real data from DB.

## 🚀 How to Run
1. **Backend:** `cd backend && node server.js`
2. **Frontend:** `flutter run -d chrome`
