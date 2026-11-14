enum PlatformType {
  instagram,
  facebook,
  linkedin,
  youtube,
  twitter,
  whatsapp,
  telegram,
}

enum AccountStatus {
  connected,
  expired,
  needsPermission,
  disconnected,
}

class SocialAccount {
  final String id;
  final String name;
  final String handle;
  final PlatformType platform;
  final AccountStatus status;
  final String avatarUrl;
  final int followersCount;
  final DateTime connectedAt;
  final List<String> permissions;
  final bool isOfficialApi;

  const SocialAccount({
    required this.id,
    required this.name,
    required this.handle,
    required this.platform,
    required this.status,
    required this.avatarUrl,
    required this.followersCount,
    required this.connectedAt,
    required this.permissions,
    this.isOfficialApi = true,
  });

  String get platformName {
    switch (platform) {
      case PlatformType.instagram:
        return 'Instagram Pro';
      case PlatformType.facebook:
        return 'Facebook Page';
      case PlatformType.linkedin:
        return 'LinkedIn Page';
      case PlatformType.youtube:
        return 'YouTube';
      case PlatformType.twitter:
        return 'X (Twitter)';
      case PlatformType.whatsapp:
        return 'WhatsApp Business';
      case PlatformType.telegram:
        return 'Telegram Channel';
    }
  }

  factory SocialAccount.fromJson(Map<String, dynamic> json) {
    PlatformType plat = PlatformType.linkedin;
    final platStr = (json['platform'] ?? '').toString().toLowerCase();
    switch (platStr) {
      case 'instagram':
        plat = PlatformType.instagram;
        break;
      case 'facebook':
        plat = PlatformType.facebook;
        break;
      case 'youtube':
        plat = PlatformType.youtube;
        break;
      case 'x':
      case 'twitter':
        plat = PlatformType.twitter;
        break;
      case 'whatsapp':
        plat = PlatformType.whatsapp;
        break;
      case 'telegram':
        plat = PlatformType.telegram;
        break;
      default:
        plat = PlatformType.linkedin;
    }

    AccountStatus stat = AccountStatus.connected;
    final statStr = (json['connection_status'] ?? '').toString().toLowerCase();
    switch (statStr) {
      case 'expired':
        stat = AccountStatus.expired;
        break;
      case 'needs_permission':
      case 'needspermission':
        stat = AccountStatus.needsPermission;
        break;
      case 'disconnected':
      case 'error':
        stat = AccountStatus.disconnected;
        break;
      default:
        stat = AccountStatus.connected;
    }

    DateTime connAt = DateTime.now();
    if (json['created_at'] != null) {
      connAt = DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
    }

    final perms = (json['permissions'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        ['read_insights', 'publish_content'];

    return SocialAccount(
      id: json['id'] ?? '',
      name: json['account_name'] ?? json['name'] ?? '',
      handle: json['platform_account_id'] != null
          ? '@${json['platform_account_id']}'
          : (json['handle'] ?? ''),
      platform: plat,
      status: stat,
      avatarUrl: json['profile_image_url'] ?? json['avatarUrl'] ?? '',
      followersCount: json['follower_count'] ?? json['followersCount'] ?? 0,
      connectedAt: connAt,
      permissions: perms,
      isOfficialApi: true,
    );
  }
}

