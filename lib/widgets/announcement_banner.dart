import 'package:flutter/material.dart';
import '../models/announcement.dart';

class AnnouncementBanner extends StatelessWidget {
  final List<Announcement> announcements;
  final VoidCallback? onViewAll;

  const AnnouncementBanner({
    super.key,
    required this.announcements,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (announcements.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.announcement_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Latest Announcements',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('View All'),
                  ),
              ],
            ),
          ),
          ...announcements.map((announcement) => _AnnouncementItem(
            announcement: announcement,
            showDivider: announcement != announcements.last,
          )),
        ],
      ),
    );
  }
}

class _AnnouncementItem extends StatelessWidget {
  final Announcement announcement;
  final bool showDivider;

  const _AnnouncementItem({
    required this.announcement,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _getAnnouncementColor(announcement.type).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  _getAnnouncementIcon(announcement.type),
                  size: 16,
                  color: _getAnnouncementColor(announcement.type),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      announcement.message,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(announcement.date),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (!announcement.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: Colors.grey.shade300,
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }

  Color _getAnnouncementColor(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.exam:
        return Colors.red;
      case AnnouncementType.assignment:
        return Colors.orange;
      case AnnouncementType.event:
        return Colors.purple;
      case AnnouncementType.general:
        return Colors.blue;
    }
  }

  IconData _getAnnouncementIcon(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.exam:
        return Icons.quiz;
      case AnnouncementType.assignment:
        return Icons.assignment;
      case AnnouncementType.event:
        return Icons.event;
      case AnnouncementType.general:
        return Icons.info;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}