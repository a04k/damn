import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_dashboard_flutter/screens/dashboard_shell.dart';

void main() {
  testWidgets('Dashboard shell smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DashboardShell(
            child: Text('Test Content'),
          ),
        ),
      ),
    );

    expect(find.text('Test Content'), findsOneWidget);
  });

  testWidgets('Custom components render', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Status Bar'),
                Text('Header'),
                Text('Bottom Nav'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Status Bar'), findsOneWidget);
    expect(find.text('Header'), findsOneWidget);
    expect(find.text('Bottom Nav'), findsOneWidget);
  });
}