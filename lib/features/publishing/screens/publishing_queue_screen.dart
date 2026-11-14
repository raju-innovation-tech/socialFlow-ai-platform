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
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/dialogs.dart';

class PublishingQueueScreen extends StatefulWidget {
  const PublishingQueueScreen({super.key});

  @override
  State<PublishingQueueScreen> createState() => _PublishingQueueScreenState();
}

class _PublishingQueueScreenState extends State<PublishingQueueScreen> {
  late List<PostItem> _queue;

  @override
  void initState() {
    super.initState();
    _queue = MockData.posts.where((p) => p.status == PostStatus.scheduled).toList();
  }

  void _cancelScheduledPost(PostItem post) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Cancel Scheduled Post?',
        message: 'This post will be reverted to drafts and removed from the active publishing queue.',
        confirmText: 'Move to Drafts',
        onConfirm: () {
          setState(() {
            _queue.removeWhere((p) => p.id == post.id);
          });
          AppToast.show(context, 'Post moved to drafts (Demo)', isSuccess: true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      Text('Upcoming Scheduled Queue (${_queue.length} posts)', style: AppTypography.cardHeading),
                      const StatusBadge(label: 'Scheduler Engine Active', isSolid: false),
                    ],
                  ),
                  const SizedBox(height: 18),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _queue.length,
                    separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 24),
                    itemBuilder: (context, index) {
                      final post = _queue[index];
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
                                      'Target: May ${post.scheduledTime?.day ?? 20}, 2025 at ${post.scheduledTime?.hour}:${post.scheduledTime?.minute == 0 ? "00" : post.scheduledTime?.minute}',
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
                                onPressed: () => _cancelScheduledPost(post),
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
