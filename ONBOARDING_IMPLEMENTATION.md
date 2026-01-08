# Onboarding Flow Implementation

This document describes the onboarding flow implementation for the Student Dashboard Flutter app.

## Overview

The onboarding flow consists of three main stages:
1. **Authentication** - Login/Register/Forgot Password screens
2. **Course Selection** - Mandatory course selection wizard
3. **Dashboard** - Main app interface after onboarding completion

## Architecture

### Core Infrastructure

- **AuthRepository**: Handles authentication operations (login, register, logout, forgot password)
- **AppSessionController**: Manages user session state and onboarding completion
- **Auth Guard**: Router-based navigation guard that enforces authentication flow

### State Management

- Uses Riverpod for state management
- `AuthState` enum represents current authentication state:
  - `unauthenticated`: User needs to log in
  - `onboardingRequired`: User is authenticated but needs to select courses
  - `authenticated`: User has completed onboarding and can access the app

### Navigation Flow

The router automatically redirects users based on their authentication state:

1. **Unauthenticated users** → Login screen
2. **Authenticated users without onboarding** → Course selection screen
3. **Authenticated users with completed onboarding** → Dashboard

## Screens

### LoginScreen (`/lib/screens/auth/login_screen.dart`)

- Email and password validation
- Remember me functionality
- Password visibility toggle
- Navigation to Register and Forgot Password screens
- Error handling with inline validation messages

### RegisterScreen (`/lib/screens/auth/register_screen.dart`)

- Full name, email, password, and password confirmation fields
- Client-side validation for all fields
- Password strength requirements (minimum 6 characters)
- Password confirmation matching
- Remember me option

### ForgotPasswordScreen (`/lib/screens/auth/forgot_password_screen.dart`)

- Email input for password reset
- Success state after email submission
- Navigation back to login

### CourseSelectionScreen (`/lib/screens/auth/course_selection_screen.dart`)

- Search functionality by course code or name
- Filter by year and department
- Course selection with visual feedback
- Minimum one course requirement
- Persists selected courses to user profile

## Data Persistence

- Uses `SharedPreferences` for local storage
- Stores user session data including:
  - Authentication token
  - Enrolled courses
  - Onboarding completion status
  - Remember me preference

## Mock Data

- Mock authentication with predefined users:
  - `student@university.edu`
  - `professor@university.edu`
  - `test@example.com`
  Password: `password123`

- Mock course data from existing course repository

## Testing

### Widget Tests

- `login_screen_test.dart`: Tests login form validation and UI components
- `course_selection_screen_test.dart`: Tests course selection functionality

### Test Coverage

- Form validation (email format, password strength)
- UI component interactions (toggles, checkboxes, buttons)
- Navigation between screens
- Error states and loading indicators
- Course search and filtering

## Usage

### Development

1. Run `flutter pub get` to install dependencies
2. Run `flutter pub run build_runner build` to generate freezed files
3. Run `flutter test` to execute tests

### Authentication Flow

1. App launches → Login screen
2. User logs in or registers → Course selection screen
3. User selects courses → Dashboard
4. User logs out → Login screen

### Testing Credentials

- Email: `test@example.com`
- Password: `password123`

## Error Handling

- Network errors display user-friendly messages
- Validation errors provide specific feedback
- Loading states prevent duplicate actions
- Graceful degradation for offline scenarios

## Security Considerations

- Password validation enforces minimum length
- Token-based authentication simulation
- Remember me functionality optional
- Session timeout on logout

## Future Enhancements

- Real authentication backend integration
- Social login options
- Biometric authentication
- Course recommendation system
- Progress saving during onboarding