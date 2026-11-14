import 'social_account.dart';

enum PostStatus {
  draft,
  inReview,
  approved,
  scheduled,
  published,
  failed,
}

class PostItem {
  final String id;
  final String title;
  final String content;
  final List<PlatformType> platforms;
  final PostStatus status;
  final DateTime? scheduledTime;
  final DateTime? publishedTime;
  final String? mediaUrl;
  final String authorName;
  final String? errorMessage;
  final int reach;
  final int engagement;
  final int clicks;

  const PostItem({
    required this.id,
    required this.title,
    required this.content,
    required this.platforms,
    required this.status,
    this.scheduledTime,
    this.publishedTime,
    this.mediaUrl,
    required this.authorName,
    this.errorMessage,
    this.reach = 0,
    this.engagement = 0,
    this.clicks = 0,
  });

  String get statusText {
    switch (status) {
      case PostStatus.draft:
        return 'Draft';
      case PostStatus.inReview:
        return 'Pending Review';
      case PostStatus.approved:
        return 'Approved';
      case PostStatus.scheduled:
        return 'Scheduled';
      case PostStatus.published:
        return 'Published';
      case PostStatus.failed:
        return 'Failed';
    }
  }
}

