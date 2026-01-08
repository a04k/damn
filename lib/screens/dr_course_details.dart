import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// DrCourseDetails - redirects to the main add content screen
/// This file exists for backwards compatibility with existing routes
class DrCourseDetails extends StatelessWidget {
  const DrCourseDetails({super.key});

  @override
  Widget build(BuildContext context) {
    // Redirect to the main add content screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/add-content');
    });
    
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
