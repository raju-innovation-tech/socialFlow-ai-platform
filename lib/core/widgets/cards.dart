import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import '../theme/app_icons.dart';
import '../models/social_account.dart';
import '../models/post_item.dart';
import '../models/campaign_item.dart';
import 'status_badge.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? trend;
  final bool isTrendPositive;
  final IconData icon;
  final Color? iconColor;
  final Widget? trailingWidget;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.trend,
    this.isTrendPositive = true,
    required this.icon,
    this.iconColor,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = iconColor ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: activeColor.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.supporting.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: activeColor.withValues(alpha: 0.3), width: 1),
                ),
                child: Icon(icon, size: 18, color: activeColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: AppTypography.kpiValue),
          const SizedBox(height: 10),
          Row(
            children: [
              if (trend != null) ...[
                Icon(
                  isTrendPositive ? LucideIcons.arrowUpRight : LucideIcons.arrowDownRight,
                  size: 14,
                  color: isTrendPositive ? AppColors.success : AppColors.danger,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    trend!,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.supporting.copyWith(
                      color: isTrendPositive ? AppColors.success : AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (trailingWidget != null) ...[
                const Spacer(),
                trailingWidget!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class ChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? action;

  const ChartCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.cardHeading),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppTypography.supporting),
                  ],
                ],
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class AccountCard extends StatelessWidget {
  final SocialAccount account;
  final VoidCallback? onManage;
  final VoidCallback? onDisconnect;

  const AccountCard({
    super.key,
    required this.account,
    this.onManage,
    this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          PlatformBrandIcon(
            platform: account.platformName,
            size: 40,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        account.name,
                        style: AppTypography.cardHeading,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  account.handle,
                  style: AppTypography.supporting.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (onManage != null)
            IconButton(
              icon: const Icon(LucideIcons.moreVertical, size: 16, color: AppColors.textSecondary),
              onPressed: onManage,
            ),
        ],
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final PostItem post;
  final VoidCallback? onTap;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdBorder,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.elevatedCard,
          borderRadius: AppRadius.mdBorder,
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.mediaUrl != null)
              ClipRRect(
                borderRadius: AppRadius.smBorder,
                child: Image.network(
                  post.mediaUrl!,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 100,
                    color: AppColors.card,
                    child: const Center(
                      child: Icon(LucideIcons.image, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                ...post.platforms.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: PlatformBrandIcon(platform: p.name, size: 18),
                  ),
                ),
                const Spacer(),
                StatusBadge(label: post.statusText),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              post.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.cardHeading.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class CampaignCard extends StatelessWidget {
  final CampaignItem campaign;
  final VoidCallback? onTap;

  const CampaignCard({
    super.key,
    required this.campaign,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = campaign.totalPosts > 0
        ? (campaign.completedPosts / campaign.totalPosts).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
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
              Expanded(
                child: Text(
                  campaign.name,
                  style: AppTypography.cardHeading,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusBadge(
                label: campaign.status == CampaignStatus.active ? 'Active' : 'Draft',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            campaign.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.supporting,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              ...campaign.platforms.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: PlatformBrandIcon(platform: p.name, size: 20),
                ),
              ),
              const Spacer(),
              Text(
                '${campaign.completedPosts}/${campaign.totalPosts} Posts',
                style: AppTypography.supporting.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.secondaryBackground,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
        ],
      ),
    );
  }
}
