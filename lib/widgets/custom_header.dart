import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/announcement_provider.dart';
import '../providers/app_session_provider.dart';
import 'user_avatar.dart';

class CustomHeader extends ConsumerWidget {
  const CustomHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final announcementsAsync = ref.watch(announcementsProvider);
    
    final unreadCount = announcementsAsync.when(
      data: (announcements) => announcements.where((a) => !a.isRead).length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          userAsync.when(
            data: (user) {
              if (user == null) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () => context.go('/profile'),
                child: Row(
                  children: [
                    UserAvatar(
                      avatarUrl: user.avatar,
                      name: user.name,
                      size: 48,
                    ),
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(),
            ),
            error: (_, __) => const Icon(Icons.error, color: Colors.red),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.go('/notifications'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    size: 24,
                    color: Colors.black,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}