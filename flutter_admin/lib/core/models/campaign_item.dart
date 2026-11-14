import 'social_account.dart';

enum CampaignStatus {
  active,
  draft,
  completed,
  paused,
}

class CampaignItem {
  final String id;
  final String name;
  final String description;
  final CampaignStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final List<PlatformType> platforms;
  final int totalPosts;
  final int completedPosts;
  final double budget;
  final double engagementRate;

  const CampaignItem({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.platforms,
    required this.totalPosts,
    required this.completedPosts,
    this.budget = 0,
    this.engagementRate = 0,
  });
}

