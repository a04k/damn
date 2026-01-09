import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_dashboard_flutter/screens/auth/course_selection_screen.dart';
void main() {
  group('CourseSelectionScreen Tests', () {
    Widget createWidgetUnderTest() {
      return const ProviderScope(
        child: MaterialApp(
          home: SelectCoursePage(email: '',),
        ),
      );
    }

    testWidgets('should display course selection screen', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Select Your Courses'), findsOneWidget);
      expect(find.text('Choose courses from any year to build your schedule'), findsOneWidget);
      expect(find.text('Search by course code or name...'), findsOneWidget);
      expect(find.text('All Years'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
    });

    testWidgets('should display search and filter controls', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget); // Search field
      expect(find.byType(DropdownButton<String>), findsNWidgets(2)); // Year and Department filters
    });

    testWidgets('should display finish button', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Finish (0 selected)'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should show loading state', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should handle search input', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'COMP101');
      await tester.pump();

      expect(find.text('COMP101'), findsOneWidget);
    });

    testWidgets('should show empty state when no search results', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'NonExistentCourse');
      await tester.pump();

      expect(find.text('No courses found'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });
  });
}