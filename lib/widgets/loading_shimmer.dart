import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingShimmer extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadius? borderRadius;

  const LoadingShimmer({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class TaskCardShimmer extends StatelessWidget {
  const TaskCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LoadingShimmer(height: 20, width: 20),
                SizedBox(width: 12),
                LoadingShimmer(height: 16, width: 200),
              ],
            ),
            SizedBox(height: 8),
            LoadingShimmer(height: 12, width: 150),
            SizedBox(height: 8),
            Row(
              children: [
                LoadingShimmer(height: 24, width: 60),
                SizedBox(width: 8),
                LoadingShimmer(height: 24, width: 60),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CourseCardShimmer extends StatelessWidget {
  const CourseCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LoadingShimmer(height: 20, width: 120),
            SizedBox(height: 8),
            LoadingShimmer(height: 16, width: 180),
            SizedBox(height: 8),
            LoadingShimmer(height: 12, width: 250),
            SizedBox(height: 12),
            Row(
              children: [
                LoadingShimmer(height: 32, width: 32),
                SizedBox(width: 8),
                LoadingShimmer(height: 14, width: 100),
                Spacer(),
                LoadingShimmer(height: 32, width: 80),
              ],
            ),
          ],
        ),
      ),
    );
  }
}