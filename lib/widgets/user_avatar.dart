import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double size;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    required this.name,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    // Build fallback widget (initial letter)
    Widget fallbackWidget = CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFF002147).withOpacity(0.1),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: size / 2.2,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF002147),
        ),
      ),
    );
    
    // Check if we have a valid URL
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: CachedNetworkImage(
          imageUrl: avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => CircleAvatar(
            radius: size / 2,
            backgroundColor: Colors.grey.shade200,
            child: SizedBox(
              width: size / 3,
              height: size / 3,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: const Color(0xFF002147).withOpacity(0.5),
              ),
            ),
          ),
          errorWidget: (context, url, error) => fallbackWidget,
        ),
      );
    }
    
    // Return fallback for invalid/missing URLs
    return fallbackWidget;
  }
}