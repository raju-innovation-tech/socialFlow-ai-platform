import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/providers/notifications_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';

class NotificationsCenterScreen extends ConsumerStatefulWidget {
  const NotificationsCenterScreen({super.key});

  @override
  ConsumerState<NotificationsCenterScreen> createState() => _NotificationsCenterScreenState();
}

class _NotificationsCenterScreenState extends ConsumerState<NotificationsCenterScreen> {
  String _selectedFilter = 'All';

  Color _getTagBgColor(String? tag) {
    switch (tag?.toLowerCase()) {
      case 'success':
        return AppColors.success.withValues(alpha: 0.15);
      case 'action required':
      case 'action_required':
        return AppColors.danger.withValues(alpha: 0.15);
      case 'new':
        return AppColors.primary.withValues(alpha: 0.15);
      default:
        return AppColors.elevatedCard;
    }
  }

  Color _getTagTextColor(String? tag) {
    switch (tag?.toLowerCase()) {
      case 'success':
        return AppColors.success;
      case 'action required':
      case 'action_required':
        return AppColors.danger;
      case 'new':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'publishing':
        return LucideIcons.circleCheck;
      case 'account':
        return LucideIcons.circleAlert;
      case 'approval':
        return LucideIcons.users;
      default:
        return LucideIcons.bell;
    }
  }

  Color _getIconColor(String? type) {
    switch (type) {
      case 'publishing':
        return AppColors.success;
      case 'account':
        return AppColors.danger;
      case 'approval':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);

    final filteredList = state.notifications.where((n) {
      if (_selectedFilter == 'Unread') return n['is_read'] != true;
      if (_selectedFilter == 'Publishing') return n['notification_type'] == 'publishing';
      if (_selectedFilter == 'Alerts') return n['notification_type'] == 'account';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Notification Center',
              subtitle: 'Monitor real-time publishing status, platform authorizations, and workspace activity.',
              breadcrumbs: const ['Workspace', 'Notifications'],
              action: Row(
                children: [
                  SecondaryButton(
                    text: 'Refresh',
                    icon: LucideIcons.refreshCw,
                    onPressed: () => notifier.loadNotifications(),
                  ),
                  const SizedBox(width: 10),
                  PrimaryButton(
                    text: 'Mark All Read',
                    icon: LucideIcons.checkCheck,
                    onPressed: () => notifier.markAllAsRead(),
                  ),
                ],
              ),
            ),

            // Filter Tabs
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.cardBorder,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: ['All', 'Unread', 'Publishing', 'Alerts'].map((tab) {
                  final isSelected = _selectedFilter == tab;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = tab),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tab,
                        style: AppTypography.chip.copyWith(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Notification Items List
            if (filteredList.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppRadius.cardBorder,
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(LucideIcons.bellOff, size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      Text('No notifications found', style: AppTypography.cardHeading),
                      const SizedBox(height: 4),
                      Text('All systems are operating normally.', style: AppTypography.supporting),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredList.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final notif = filteredList[index];
                  final id = notif['id']?.toString() ?? '';
                  final isRead = notif['is_read'] == true;
                  final type = notif['notification_type']?.toString();
                  final tag = notif['status_tag']?.toString() ??
                      (type == 'publishing' ? 'Success' : type == 'account' ? 'Action required' : 'New');

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isRead ? AppColors.card : AppColors.elevatedCard,
                      borderRadius: AppRadius.cardBorder,
                      border: Border.all(
                        color: isRead ? AppColors.border : AppColors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getIconColor(type).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_getIconForType(type), size: 20, color: _getIconColor(type)),
                        ),
                        const SizedBox(width: 14),

                        // Title & Message
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notif['title']?.toString() ?? 'Notification',
                                style: AppTypography.cardHeading.copyWith(
                                  fontSize: 14,
                                  fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notif['message']?.toString() ?? '',
                                style: AppTypography.supporting.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Status Tag Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getTagBgColor(tag),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            style: AppTypography.chip.copyWith(
                              color: _getTagTextColor(tag),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Mark as read action button
                        if (!isRead)
                          IconButton(
                            icon: const Icon(LucideIcons.check, size: 16, color: AppColors.textSecondary),
                            tooltip: 'Mark as read',
                            onPressed: () => notifier.markAsRead(id),
                          ),
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.textSecondary),
                          tooltip: 'Delete notification',
                          onPressed: () => notifier.deleteNotification(id),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
