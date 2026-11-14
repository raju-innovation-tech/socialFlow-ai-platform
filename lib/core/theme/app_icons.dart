import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'app_colors.dart';

class AppIcons {
  // Navigation & Core
  static const IconData dashboard = LucideIcons.layoutDashboard;
  static const IconData calendar = LucideIcons.calendar;
  static const IconData createPost = LucideIcons.fileEdit;
  static const IconData queue = LucideIcons.clock;
  static const IconData drafts = LucideIcons.fileText;
  static const IconData published = LucideIcons.checkCircle2;
  static const IconData failed = LucideIcons.alertTriangle;
  static const IconData media = LucideIcons.image;
  static const IconData accounts = LucideIcons.users2;
  static const IconData campaigns = LucideIcons.target;
  static const IconData approvals = LucideIcons.checkSquare;
  static const IconData analytics = LucideIcons.barChart2;
  static const IconData reports = LucideIcons.fileSpreadsheet;
  static const IconData team = LucideIcons.userCheck;
  static const IconData settings = LucideIcons.settings;
  static const IconData billing = LucideIcons.creditCard;
  static const IconData superAdmin = LucideIcons.shieldAlert;

  // Actions & Controls
  static const IconData search = LucideIcons.search;
  static const IconData filter = LucideIcons.filter;
  static const IconData bell = LucideIcons.bell;
  static const IconData sparkler = LucideIcons.sparkles;
  static const IconData plus = LucideIcons.plus;
  static const IconData edit = LucideIcons.pencil;
  static const IconData delete = LucideIcons.trash2;
  static const IconData download = LucideIcons.download;
  static const IconData upload = LucideIcons.uploadCloud;
  static const IconData refresh = LucideIcons.rotateCw;
  static const IconData check = LucideIcons.check;
  static const IconData close = LucideIcons.x;
  static const IconData eye = LucideIcons.eye;
  static const IconData eyeOff = LucideIcons.eyeOff;
  static const IconData arrowRight = LucideIcons.arrowRight;
  static const IconData arrowUpRight = LucideIcons.arrowUpRight;
  static const IconData chevronDown = LucideIcons.chevronDown;
  static const IconData chevronRight = LucideIcons.chevronRight;
  static const IconData chevronLeft = LucideIcons.chevronLeft;
  static const IconData info = LucideIcons.info;
  static const IconData share = LucideIcons.share2;
  static const IconData zap = LucideIcons.zap;
  static const IconData link = LucideIcons.link2;
  static const IconData lock = LucideIcons.lock;
  static const IconData folder = LucideIcons.folder;
  static const IconData messageCircle = LucideIcons.messageCircle;
  static const IconData send = LucideIcons.send;
}

/// Custom platform brand badge/icon widget
class PlatformBrandIcon extends StatelessWidget {
  final String platform;
  final double size;
  final Color? color;

  const PlatformBrandIcon({
    super.key,
    required this.platform,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final norm = platform.toLowerCase().trim();
    Color brandColor = AppColors.primary;
    IconData iconData = Icons.share;

    if (norm.contains('instagram')) {
      brandColor = AppColors.instagram;
      iconData = Icons.camera_alt_rounded;
    } else if (norm.contains('facebook')) {
      brandColor = AppColors.facebook;
      iconData = Icons.facebook_rounded;
    } else if (norm.contains('linkedin')) {
      brandColor = AppColors.linkedin;
      iconData = Icons.business_center_rounded;
    } else if (norm.contains('youtube')) {
      brandColor = AppColors.youtube;
      iconData = Icons.smart_display_rounded;
    } else if (norm.contains('twitter') || norm == 'x') {
      brandColor = Colors.white;
      iconData = Icons.tag_rounded;
    } else if (norm.contains('whatsapp')) {
      brandColor = AppColors.whatsapp;
      iconData = LucideIcons.phoneCall;
    } else if (norm.contains('telegram')) {
      brandColor = AppColors.telegram;
      iconData = LucideIcons.send;
    }

    final effectiveColor = color ?? brandColor;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: effectiveColor.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          iconData,
          size: size * 0.58,
          color: effectiveColor,
        ),
      ),
    );
  }
}
