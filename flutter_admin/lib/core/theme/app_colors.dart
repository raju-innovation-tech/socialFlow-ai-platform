import 'package:flutter/material.dart';

class AppColors {
  // Primary Dark Palette
  static const Color background = Color(0xFF080D18);
  static const Color secondaryBackground = Color(0xFF0D1423);
  static const Color sidebar = Color(0xFF0B1220);
  static const Color card = Color(0xFF111C2E);
  static const Color elevatedCard = Color(0xFF17243A);
  static const Color border = Color(0xFF1D2C46);
  static const Color subtleBorder = Color(0x1F6C8CFF);

  // Accent & Brand Colors
  static const Color primary = Color(0xFF6C8CFF);
  static const Color primaryGradientEnd = Color(0xFF8A53FF);
  static const Color accentViolet = Color(0xFF9B7BFF);

  // Feedback Colors
  static const Color success = Color(0xFF22C58B);
  static const Color warning = Color(0xFFF4B860);
  static const Color danger = Color(0xFFF16D78);
  static const Color info = Color(0xFF38BDF8);

  // Typography Colors
  static const Color textPrimary = Color(0xFFF4F7FF);
  static const Color textSecondary = Color(0xFF9AA9BF);
  static const Color textMuted = Color(0xFF64748B);

  // Glassmorphism & Overlays
  static const Color glassWhite = Color(0x0DFFFFFF);
  static const Color glassHighlight = Color(0x1AFFFFFF);
  static const Color glow = Color(0x336C8CFF);

  // Social Platform Brand Colors
  static const Color linkedin = Color(0xFF0A66C2);
  static const Color facebook = Color(0xFF1877F2);
  static const Color instagram = Color(0xFFE4405F);
  static const Color youtube = Color(0xFFFF0000);
  static const Color twitter = Color(0xFFE7E9EA);
  static const Color whatsapp = Color(0xFF25D366);
  static const Color telegram = Color(0xFF229ED9);

  // Linear Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, accentViolet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF142034), Color(0xFF0F1828)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x14FFFFFF), Color(0x05FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Light Theme Alternatives
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSecondary = Color(0xFFF1F5F9);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightElevatedCard = Color(0xFFF8FAFC);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
}

