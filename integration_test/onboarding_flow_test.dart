import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_dashboard_flutter/main.dart';
import 'package:student_dashboard_flutter/screens/auth/login_screen.dart';
import 'package:student_dashboard_flutter/screens/auth/course_selection_screen.dart';
import 'package:student_dashboard_flutter/screens/home_screen.dart';

void main() {
  group('Onboarding Flow Integration Tests', () {
    testWidgets('complete onboarding flow from login to dashboard',
        (WidgetTester tester) async {
      await tester
          .pumpWidget(const ProviderScope(child: StudentDashboardApp()));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('Get Started now'), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@sci.asu.edu.eg');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.byType(SelectCoursePage), findsOneWidget);

      expect(find.text('Select Your Courses'), findsOneWidget);

      await tester.pumpAndSettle(const Duration(seconds: 2));

      final courseCards = find.byType(ListView);

      if (courseCards.evaluate().isNotEmpty) {
        await tester.tap(find.byType(ListTile).first);

        await tester.pump();

        expect(find.textContaining('Finish (1 selected)'), findsOneWidget);

        await tester.tap(find.textContaining('Finish (1 selected)'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.byType(HomeScreen), findsOneWidget);
      }
    });

    testWidgets('should show validation errors for invalid login',
        (WidgetTester tester) async {
      await tester
          .pumpWidget(const ProviderScope(child: StudentDashboardApp()));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('email_field')), 'invalid-email');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.text('Log In'));
      await tester.pump();
      expect(find.text('Please enter a valid @sci.asu.edu.eg email'),
          findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@sci.asu.edu.eg');
      await tester.enterText(find.byKey(const Key('password_field')), '123');
      await tester.tap(find.text('Log In'));
      await tester.pump();
      expect(
          find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('should prevent finishing course selection without courses',
        (WidgetTester tester) async {
      await tester
          .pumpWidget(const ProviderScope(child: StudentDashboardApp()));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@sci.asu.edu.eg');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.byType(SelectCoursePage), findsOneWidget);

      await tester.tap(find.textContaining('Finish (0 selected)'));
      await tester.pump();

      expect(find.text('Please select at least one course'), findsOneWidget);
    });

    testWidgets('should navigate between auth screens',
        (WidgetTester tester) async {
      await tester
          .pumpWidget(const ProviderScope(child: StudentDashboardApp()));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();
      expect(find.text('Sign Up'), findsNWidgets(2));

      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);

      await tester.tap(find.text('Forgot Password ?'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Forgot Password'), findsOneWidget);
    });
  });
}
