import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/models/post_item.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/dialogs.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers/publishing_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  String _selectedView = 'Week';
  String _selectedPlatform = 'All Platforms';
  DateTime _currentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(publishingProvider.notifier).loadCalendar());
  }

  void _showRescheduleDialog(PostItem post) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.elevatedCard,
        title: Text('Reschedule Post', style: AppTypography.cardHeading),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Move "${post.title}" to a different date & slot:', style: AppTypography.bodyMuted),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(LucideIcons.calendar, color: AppColors.primary),
              title: const Text('Tomorrow at 10:00 AM'),
              onTap: () async {
                Navigator.pop(dialogCtx);
                final tomorrow = DateTime.now().add(const Duration(days: 1));
                final ok = await ref.read(publishingProvider.notifier).schedulePost(
                  post.id,
                  DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10, 0),
                );
                if (!mounted) return;
                if (ok) {
                  AppToast.show(context, 'Post rescheduled to Tomorrow 10:00 AM', isSuccess: true);
                } else {
                  AppToast.show(context, 'Reschedule failed', isError: true);
                }
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.clock, color: AppColors.accentViolet),
              title: const Text('Next Day Slot (2:00 PM)'),
              onTap: () async {
                Navigator.pop(dialogCtx);
                final nextDay = DateTime.now().add(const Duration(days: 2));
                final ok = await ref.read(publishingProvider.notifier).schedulePost(
                  post.id,
                  DateTime(nextDay.year, nextDay.month, nextDay.day, 14, 0),
                );
                if (!mounted) return;
                if (ok) {
                  AppToast.show(context, 'Post rescheduled to 2:00 PM slot', isSuccess: true);
                } else {
                  AppToast.show(context, 'Reschedule failed', isError: true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredPosts = MockData.posts.where((p) {
      if (_selectedPlatform == 'All Platforms') return true;
      return p.platforms.any((plat) => plat.name.toLowerCase().contains(_selectedPlatform.toLowerCase()));
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Content Calendar',
              subtitle: 'Plan, reschedule, and visualize automated omni-channel campaigns.',
              breadcrumbs: const ['Publishing', 'Calendar'],
              action: Row(
                children: [
                  SecondaryButton(
                    text: 'Publishing Queue',
                    icon: LucideIcons.clock,
                    onPressed: () => context.go('/publishing/queue'),
                  ),
                  const SizedBox(width: 10),
                  PrimaryButton(
                    text: 'Add Content',
                    icon: LucideIcons.plus,
                    onPressed: () => context.go('/publishing/create'),
                  ),
                ],
              ),
            ),

            // Controls Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.cardBorder,
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.chevronLeft, size: 18),
                        onPressed: () => setState(() => _currentDate = _currentDate.subtract(const Duration(days: 7))),
                      ),
                      Text(
                        'May 19 – May 25, 2025',
                        style: AppTypography.cardHeading.copyWith(fontSize: 15),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.chevronRight, size: 18),
                        onPressed: () => setState(() => _currentDate = _currentDate.add(const Duration(days: 7))),
                      ),
                      const SizedBox(width: 8),
                      OutlinedActionButton(
                        text: 'Today',
                        onPressed: () => setState(() => _currentDate = DateTime(2025, 5, 21)),
                      ),
                    ],
                  ),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // View selector
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryBackground,
                          borderRadius: AppRadius.mdBorder,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: ['Month', 'Week', 'Day', 'Agenda'].map((view) {
                            final isSel = _selectedView == view;
                            return InkWell(
                              onTap: () => setState(() => _selectedView = view),
                              borderRadius: AppRadius.smBorder,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSel ? AppColors.primary : Colors.transparent,
                                  borderRadius: AppRadius.smBorder,
                                ),
                                child: Text(
                                  view,
                                  style: AppTypography.chip.copyWith(
                                    color: isSel ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _selectedPlatform,
                        dropdownColor: AppColors.elevatedCard,
                        style: AppTypography.body,
                        items: ['All Platforms', 'Instagram', 'LinkedIn', 'Facebook', 'Twitter']
                            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPlatform = val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Calendar Grid or List
            _buildCalendarBody(filteredPosts),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarBody(List<PostItem> posts) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Scheduled Pipeline (${posts.length} posts)', style: AppTypography.cardHeading),
              Text('Drag or click cards to reschedule', style: AppTypography.supporting),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 20),
            itemBuilder: (context, index) {
              final post = posts[index];
              return InkWell(
                onTap: () => _showRescheduleDialog(post),
                borderRadius: AppRadius.mdBorder,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: AppRadius.mdBorder,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      if (post.mediaUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(post.mediaUrl!, width: 50, height: 50, fit: BoxFit.cover),
                        ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ...post.platforms.map((p) => Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: PlatformBrandIcon(platform: p.name, size: 16),
                                    )),
                                const SizedBox(width: 4),
                                Text(
                                  post.scheduledTime != null
                                      ? 'May ${post.scheduledTime!.day} at ${post.scheduledTime!.hour}:${post.scheduledTime!.minute == 0 ? "00" : post.scheduledTime!.minute}'
                                      : 'Draft Slot',
                                  style: AppTypography.chip.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(post.title, style: AppTypography.cardHeading.copyWith(fontSize: 14)),
                          ],
                        ),
                      ),
                      OutlinedActionButton(
                        text: 'Reschedule',
                        icon: LucideIcons.calendarClock,
                        onPressed: () => _showRescheduleDialog(post),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
