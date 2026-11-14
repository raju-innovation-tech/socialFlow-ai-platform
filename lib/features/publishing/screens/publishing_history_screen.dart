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
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/dialogs.dart';

class PublishingHistoryScreen extends StatefulWidget {
  const PublishingHistoryScreen({super.key});

  @override
  State<PublishingHistoryScreen> createState() => _PublishingHistoryScreenState();
}

class _PublishingHistoryScreenState extends State<PublishingHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              title: 'Publishing History & Logs',
              subtitle: 'Monitor successfully dispatched content and debug failed platform calls.',
              breadcrumbs: const ['Publishing', 'History & Logs'],
              action: PrimaryButton(
                text: 'New Post',
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
                tabs: const [
                  Tab(text: 'Published (48 Posts)'),
                  Tab(text: 'Failed / Needs Attention (2 Posts)'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 520,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPublishedTab(),
                  _buildFailedTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublishedTab() {
    final publishedPosts = MockData.posts.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: ListView.separated(
        itemCount: publishedPosts.length,
        separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 24),
        itemBuilder: (context, index) {
          final p = publishedPosts[index];
          return Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(p.mediaUrl ?? '', width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(LucideIcons.image)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.title, style: AppTypography.cardHeading.copyWith(fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      'Published on May 18, 2025 • Reach: ${(p.reach / 1000).toStringAsFixed(1)}K • Engagement: ${p.engagement}',
                      style: AppTypography.supporting,
                    ),
                  ],
                ),
              ),
              const StatusBadge(label: 'Published', isSolid: true, color: AppColors.success),
              const SizedBox(width: 10),
              OutlinedActionButton(
                text: 'View Post',
                icon: LucideIcons.externalLink,
                onPressed: () => AppToast.show(context, 'Opening live post URL in browser (Demo)', isSuccess: true),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFailedTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          _buildFailedItem(
            title: 'Q2 Financial Infographic Showcase',
            platform: 'linkedin',
            error: 'OAuth2 Token Expired: The organization access token was revoked by admin. Re-authorization required.',
            timestamp: 'May 17, 2025 at 04:12 PM',
          ),
          const Divider(color: AppColors.border, height: 28),
          _buildFailedItem(
            title: 'Exclusive Video Teaser #3',
            platform: 'instagram',
            error: 'Media Aspect Ratio Error: Instagram Reels requires 9:16 aspect ratio. Attached video was 16:9.',
            timestamp: 'May 16, 2025 at 09:30 AM',
          ),
        ],
      ),
    );
  }

  Widget _buildFailedItem({
    required String title,
    required String platform,
    required String error,
    required String timestamp,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PlatformBrandIcon(platform: platform, size: 28),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.cardHeading.copyWith(fontSize: 14)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.12),
                  borderRadius: AppRadius.smBorder,
                ),
                child: Text(error, style: AppTypography.supporting.copyWith(color: AppColors.danger)),
              ),
              const SizedBox(height: 6),
              Text(timestamp, style: AppTypography.chip.copyWith(color: AppColors.textMuted)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        PrimaryButton(
          text: 'Retry Dispatch',
          icon: LucideIcons.rotateCw,
          height: 36,
          onPressed: () => AppToast.show(context, 'Post re-queued for dispatch retry (Demo)', isSuccess: true),
        ),
      ],
    );
  }
}
