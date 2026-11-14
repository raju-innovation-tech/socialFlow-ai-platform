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
}

