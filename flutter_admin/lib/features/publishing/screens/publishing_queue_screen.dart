import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../app/providers/publishing_provider.dart';

class PublishingQueueScreen extends ConsumerStatefulWidget {
  const PublishingQueueScreen({super.key});

  @override
  ConsumerState<PublishingQueueScreen> createState() => _PublishingQueueScreenState();
}

class _PublishingQueueScreenState extends ConsumerState<PublishingQueueScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(publishingProvider.notifier).loadQueue());
  }

  void _cancelScheduledPost(String postId, String title) {
    showDialog(
      context: context,
      builder: (dialogCtx) => ConfirmationDialog(
        title: 'Cancel Scheduled Post?',
        message: 'This post will be reverted to drafts and removed from the active publishing queue.',
        confirmText: 'Move to Drafts',
        onConfirm: () async {
          final ok = await ref.read(publishingProvider.notifier).cancelSchedule(postId);
          if (!mounted) return;
          if (ok) {
            AppToast.show(context, 'Post moved to drafts', isSuccess: true);
          } else {
            AppToast.show(context, 'Failed to cancel post schedule', isError: true);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(publishingProvider);
    final queueItems = state.queueItems;

    // Use mock data fallback if remote is empty to preserve demonstration layout
    final hasRemote = queueItems.isNotEmpty;
    final displayCount = hasRemote ? queueItems.length : MockData.posts.where((p) => p.status == PostStatus.scheduled).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Publishing Queue',
              subtitle: 'Active queue of automated posts queued for direct dispatch.',
              breadcrumbs: const ['Publishing', 'Publishing Queue'],
              action: Row(
                children: [
                  SecondaryButton(
                    text: 'Refresh Queue',
                    icon: LucideIcons.refreshCw,
                    onPressed: () => ref.read(publishingProvider.notifier).loadQueue(),
                  ),
                  const SizedBox(width: 10),
                  SecondaryButton(
                    text: 'View Drafts',
                    icon: LucideIcons.fileText,
                    onPressed: () => context.go('/publishing/drafts'),
                  ),
                  const SizedBox(width: 10),
                  PrimaryButton(
                    text: 'Create New Post',
                    icon: LucideIcons.plus,
                    onPressed: () => context.go('/publishing/create'),
                  ),
                ],
              ),
            ),

            Container(
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
                      Text('Upcoming Scheduled Queue ($displayCount posts)', style: AppTypography.cardHeading),
                      const StatusBadge(label: 'Scheduler Engine Active', isSolid: false),
                    ],
                  ),
                  const SizedBox(height: 18),

                  if (hasRemote)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: queueItems.length,
                      separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 24),
                      itemBuilder: (context, index) {
                        final item = queueItems[index];
                        final postId = item['post_id']?.toString() ?? '';
                        final title = item['title']?.toString() ?? 'Untitled Post';
                        final scheduledTime = item['scheduled_time']?.toString() ?? '';
                        final platforms = (item['platforms'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

                        return Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.secondaryBackground,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(LucideIcons.calendarClock, color: AppColors.primary, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      ...platforms.map((p) => Padding(
                                            padding: const EdgeInsets.only(right: 6),
                                            child: PlatformBrandIcon(platform: p, size: 18),
                                          )),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Target: $scheduledTime',
                                        style: AppTypography.supporting.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(title, style: AppTypography.cardHeading.copyWith(fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Job ID: ${item['job_id'] ?? ''} • Status: ${item['status'] ?? 'pending'}',
                                    style: AppTypography.chip.copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(LucideIcons.xCircle, color: AppColors.danger, size: 20),
                                  tooltip: 'Cancel schedule',
                                  onPressed: () => _cancelScheduledPost(postId, title),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    )
                  else
                    // Fallback to MockData
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: MockData.posts.where((p) => p.status == PostStatus.scheduled).length,
                      separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 24),
                      itemBuilder: (context, index) {
                        final post = MockData.posts.where((p) => p.status == PostStatus.scheduled).toList()[index];
                        return Row(
                          children: [
                            if (post.mediaUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(post.mediaUrl!, width: 64, height: 64, fit: BoxFit.cover),
                              ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      ...post.platforms.map((p) => Padding(
                                            padding: const EdgeInsets.only(right: 6),
                                            child: PlatformBrandIcon(platform: p.name, size: 18),
                                          )),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Target: ${post.scheduledTime?.month}/${post.scheduledTime?.day} at ${post.scheduledTime?.hour}:${post.scheduledTime?.minute == 0 ? "00" : post.scheduledTime?.minute}',
                                        style: AppTypography.supporting.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(post.title, style: AppTypography.cardHeading.copyWith(fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text(
                                    post.content,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.supporting,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Row(
                              children: [
                                OutlinedActionButton(
                                  text: 'Edit',
                                  icon: LucideIcons.edit,
                                  onPressed: () => context.go('/publishing/create'),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(LucideIcons.xCircle, color: AppColors.danger, size: 20),
                                  tooltip: 'Cancel schedule',
                                  onPressed: () => _cancelScheduledPost(post.id, post.title),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
