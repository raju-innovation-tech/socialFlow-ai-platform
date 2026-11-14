import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_badge.dart';

class WhatsAppCommunitiesScreen extends StatelessWidget {
  const WhatsAppCommunitiesScreen({super.key});

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
              title: 'WhatsApp Communities Hub',
              subtitle: 'Structure sub-groups, plan cross-group announcements, and schedule reminders.',
              breadcrumbs: const ['Channels', 'WhatsApp', 'Communities'],
              action: PrimaryButton(
                text: 'New Community Broadcast',
                icon: LucideIcons.plus,
                onPressed: () => context.go('/publishing/create'),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(20),
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
                      Text('Managed Communities', style: AppTypography.cardHeading),
                      const StatusBadge(label: 'Assisted Companion Dispatch', color: AppColors.warning),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCommunityCard(
                    title: 'SocialFlow Global Creator Community',
                    subgroups: '6 Subgroups (Announcements, Feedback, UI Designers, Developers, General, Events)',
                    totalMembers: '2,450 Total Reach',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityCard({
    required String title,
    required String subgroups,
    required String totalMembers,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: AppRadius.mdBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.whatsapp.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.globe, color: AppColors.whatsapp, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.cardHeading.copyWith(fontSize: 15)),
                    Text(totalMembers, style: AppTypography.chip.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(subgroups, style: AppTypography.supporting),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedActionButton(
                text: 'Draft Announcement',
                icon: LucideIcons.send,
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
