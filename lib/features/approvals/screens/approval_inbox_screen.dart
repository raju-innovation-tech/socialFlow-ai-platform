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

class ApprovalInboxScreen extends StatefulWidget {
  const ApprovalInboxScreen({super.key});

  @override
  State<ApprovalInboxScreen> createState() => _ApprovalInboxScreenState();
}

class _ApprovalInboxScreenState extends State<ApprovalInboxScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<PostItem> _pendingPosts;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pendingPosts = MockData.posts.where((p) => p.status == PostStatus.inReview).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _approvePost(PostItem post) {
    setState(() {
      _pendingPosts.removeWhere((p) => p.id == post.id);
    });
    AppToast.show(context, 'Post "${post.title}" approved & queued! (Demo)', isSuccess: true);
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
              title: 'Editorial Approval Inbox',
              subtitle: 'Multi-stage editorial review workflow before content is automatically dispatched.',
              breadcrumbs: const ['Workspace', 'Approvals'],
              action: PrimaryButton(
                text: 'Create Review Item',
                icon: LucideIcons.plus,
                onPressed: () => context.go('/publishing/create'),
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.mdBorder,
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: [
                  Tab(text: 'Pending Approval (${_pendingPosts.length})'),
                  const Tab(text: 'Approved (24)'),
                  const Tab(text: 'Rejected / Revisions (3)'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 520,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPendingTab(),
                  _buildApprovedTab(),
                  _buildRejectedTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_pendingPosts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.cardBorder,
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(child: Text('All pending items have been reviewed! 🎉')),
      );
    }

    return ListView.separated(
      itemCount: _pendingPosts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final p = _pendingPosts[index];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadius.cardBorder,
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            children: [
              if (p.mediaUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(p.mediaUrl!, width: 70, height: 70, fit: BoxFit.cover),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ...p.platforms.map((plat) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: PlatformBrandIcon(platform: plat.name, size: 16),
                            )),
                        const SizedBox(width: 6),
                        Text('Drafted by ${p.authorName}', style: AppTypography.chip.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(p.title, style: AppTypography.cardHeading.copyWith(fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(p.content, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.supporting),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  SecondaryButton(
                    text: 'Review Details',
                    icon: LucideIcons.eye,
                    height: 38,
                    onPressed: () => context.go('/approvals/details/${p.id}'),
                  ),
                  const SizedBox(width: 10),
                  PrimaryButton(
                    text: 'Approve',
                    icon: LucideIcons.check,
                    height: 38,
                    onPressed: () => _approvePost(p),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildApprovedTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(child: Text('24 Posts have been approved this month and dispatched to scheduler.')),
    );
  }

  Widget _buildRejectedTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(child: Text('3 Posts requested revisions from creators.')),
    );
  }
}
