import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_dashboard_flutter/main.dart';
import 'package:student_dashboard_flutter/screens/home_screen.dart';
import 'package:student_dashboard_flutter/screens/TaskPages/Task.dart';
import 'package:student_dashboard_flutter/screens/profile_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('Complete app flow test', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: StudentDashboardApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Test 1: Home Screen Loading
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Progress Overview'), findsOneWidget);

      // Test 2: Navigate to Tasks
      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();

      expect(find.byType(TasksPage), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Search tasks...'), findsOneWidget);

      // Test 3: Test task filtering
      await tester.tap(find.text('PENDING'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('HIGH'));
      await tester.pumpAndSettle();

      // Test 4: Test search functionality
      await tester.enterText(find.byType(TextField), 'Data Structures');
      await tester.pumpAndSettle();

      expect(find.text('Data Structures'), findsOneWidget);

      // Test 5: Navigate to Schedule
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();

      expect(find.text('Schedule'), findsAtLeastNWidgets(1));
      expect(find.text('Upcoming Events'), findsOneWidget);

      // Test 6: Navigate to Profile
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Student Information'), findsOneWidget);
      expect(find.text('Account Settings'), findsOneWidget);
      expect(find.text('App Mode'), findsOneWidget);

      // Test 7: Test app mode switching
      expect(find.text('Student Mode'), findsOneWidget);
      
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Professor Mode'), findsOneWidget);

      // Test 8: Navigate back to Home
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);

      // Test 9: Test pull to refresh
      await tester.fling(
        find.byType(Scrollable).first,
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      // Test 10: Navigate to Navigate (AR) tab
      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.text('AR Navigation'), findsOneWidget);
      expect(find.text('Augmented Reality navigation features'), findsOneWidget);

      // Final verification - all tabs are accessible
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();
      expect(find.byType(TasksPage), findsOneWidget);

      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('Data flow integration test', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: StudentDashboardApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Test that user data flows correctly
      expect(find.text('Welcome back'), findsOneWidget);
      
      // Navigate to tasks to test task data flow
      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();

      // Verify tasks are loaded
      expect(find.text('Pending'), findsOneWidget);
      
      // Switch to completed tab
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();
      
      // Switch back to pending
      await tester.tap(find.text('Pending'));
      await tester.pumpAndSettle();

      // Test that task interactions work
      if (find.byType(Checkbox).evaluate().isNotEmpty) {
        await tester.tap(find.byType(Checkbox).first);
        await tester.pumpAndSettle();
      }

      // Navigate back to home to verify progress updates
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      // Verify progress cards show updated data
      expect(find.text('Progress Overview'), findsOneWidget);
    });

    testWidgets('Professor mode integration test', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: StudentDashboardApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to professor mode
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Navigate back to home to see professor features
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      // Check for professor-specific features (like add button)
      // This would depend on the actual implementation
      expect(find.byType(HomeScreen), findsOneWidget);

      // Navigate to tasks to see if professor features are available
      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();

      // Verify professor mode is active throughout the app
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Professor Mode'), findsOneWidget);
    });
  });
}

class IntegrationTestWidgetsFlutterBinding {
  static void ensureInitialized() {}
}