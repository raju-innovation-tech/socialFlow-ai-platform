import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/dialogs.dart';

class ApprovalDetailsScreen extends StatefulWidget {
  final String postId;

  const ApprovalDetailsScreen({super.key, required this.postId});

  @override
  State<ApprovalDetailsScreen> createState() => _ApprovalDetailsScreenState();
}

class _ApprovalDetailsScreenState extends State<ApprovalDetailsScreen> {
  final _commentController = TextEditingController();
  final List<String> _comments = [
    'Alex Morgan: "Added higher contrast graphics for LinkedIn mobile feed."',
    'David Chen: "Looks great! Just double check the CTA link before final approval."',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _addComment() {
    if (_commentController.text.isNotEmpty) {
      setState(() {
        _comments.add('You: "${_commentController.text}"');
        _commentController.clear();
      });
      AppToast.show(context, 'Comment posted! (Demo)', isSuccess: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = MockData.posts.firstWhere(
      (p) => p.id == widget.postId,
      orElse: () => MockData.posts.first,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Review: ${post.title}',
              subtitle: 'Verify messaging accuracy, visual assets, and platform compliance.',
              breadcrumbs: ['Workspace', 'Approvals', post.title],
              action: Row(
                children: [
                  SecondaryButton(
                    text: 'Request Changes',
                    icon: LucideIcons.messageSquare,
                    onPressed: () {
                      AppToast.show(context, 'Change request notification sent to author (Demo)', isError: true);
                      context.go('/approvals');
                    },
                  ),
                  const SizedBox(width: 10),
                  PrimaryButton(
                    text: 'Approve & Schedule',
                    icon: LucideIcons.checkCheck,
                    onPressed: () {
                      AppToast.show(context, 'Post approved! Moved to live publishing queue.', isSuccess: true);
                      context.go('/approvals');
                    },
                  ),
                ],
              ),
            ),

            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                return Flex(
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Post Preview on Left
                    Expanded(
                      flex: isWide ? 12 : 0,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: AppRadius.cardBorder,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ...post.platforms.map((p) => Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: PlatformBrandIcon(platform: p.name, size: 24),
                                    )),
                                const SizedBox(width: 8),
                                Text('Created by ${post.authorName}', style: AppTypography.cardHeading.copyWith(fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(post.title, style: AppTypography.mainHeading.copyWith(fontSize: 20)),
                            const SizedBox(height: 12),
                            Text(post.content, style: AppTypography.body.copyWith(height: 1.5)),
                            const SizedBox(height: 16),
                            if (post.mediaUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  post.mediaUrl!,
                                  height: 260,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    if (isWide) const SizedBox(width: 20) else const SizedBox(height: 20),

                    // Comments Thread on Right
                    Expanded(
                      flex: isWide ? 8 : 0,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: AppRadius.cardBorder,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Editorial Review Thread', style: AppTypography.cardHeading),
                            const SizedBox(height: 16),
                            ..._comments.map((c) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryBackground,
                                      borderRadius: AppRadius.mdBorder,
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Text(c, style: AppTypography.supporting),
                                  ),
                                )),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _commentController,
                              style: AppTypography.body,
                              decoration: InputDecoration(
                                hintText: 'Add editorial feedback...',
                                suffixIcon: IconButton(
                                  icon: const Icon(LucideIcons.send, color: AppColors.primary, size: 16),
                                  onPressed: _addComment,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
