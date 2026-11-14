import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_badge.dart';

class CampaignDetailsScreen extends StatelessWidget {
  final String campaignId;

  const CampaignDetailsScreen({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context) {
    final campaign = MockData.campaigns.firstWhere(
      (c) => c.id == campaignId,
      orElse: () => MockData.campaigns.first,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: campaign.name,
              subtitle: 'Campaign performance attribution, post timeline, and completion metrics.',
              breadcrumbs: ['Workspace', 'Campaigns', campaign.name],
              action: Row(
                children: [
                  SecondaryButton(
                    text: 'All Campaigns',
                    icon: LucideIcons.arrowLeft,
                    onPressed: () => context.go('/campaigns'),
                  ),
                  const SizedBox(width: 10),
                  PrimaryButton(
                    text: 'Add Post to Campaign',
                    icon: LucideIcons.plus,
                    onPressed: () => context.go('/publishing/create'),
                  ),
                ],
              ),
            ),

            // Top Status & KPI Overview
            Container(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(campaign.description, style: AppTypography.subHeading),
                      ),
                      const StatusBadge(label: 'Active Campaign', isSolid: false),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDetailMetric('Progress', '${campaign.completedPosts}/${campaign.totalPosts} Posts'),
                      _buildDetailMetric('Budget Allocated', '\$${campaign.budget.toInt()}'),
                      _buildDetailMetric('Engagement Rate', '${campaign.engagementRate}%'),
                      _buildDetailMetric('Status', 'On Track'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Associated Posts list
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.cardBorder,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Associated Posts (${MockData.posts.length} posts)', style: AppTypography.cardHeading),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 4,
                    separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 20),
                    itemBuilder: (context, index) {
                      final p = MockData.posts[index];
                      return Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(p.mediaUrl ?? '', width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(LucideIcons.image)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.title, style: AppTypography.cardHeading.copyWith(fontSize: 14)),
                                Text(p.content, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.supporting),
                              ],
                            ),
                          ),
                          StatusBadge(label: p.statusText),
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

  Widget _buildDetailMetric(String title, String value) {
    return Column(
      children: [
        Text(title, style: AppTypography.chip.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.cardHeading.copyWith(fontSize: 18, color: AppColors.primary)),
      ],
    );
  }
}
