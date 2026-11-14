import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/dialogs.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _nameController = TextEditingController(text: 'Cyber Magic Team');
  final _emailController = TextEditingController(text: 'admin@cybermagic.studio');
  bool _emailNotifications = true;
  bool _aiAssistance = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
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
              title: 'Personal Profile Settings',
              subtitle: 'Manage your avatar, security credentials, and personal notification preferences.',
              breadcrumbs: const ['Settings', 'Profile'],
              action: Row(
                children: [
                  SecondaryButton(
                    text: 'Workspace Settings',
                    icon: LucideIcons.building2,
                    onPressed: () => context.go('/settings/workspace'),
                  ),
                  const SizedBox(width: 10),
                  PrimaryButton(
                    text: 'Save Changes',
                    icon: LucideIcons.check,
                    onPressed: () => AppToast.show(context, 'Profile updated successfully! (Demo)', isSuccess: true),
                  ),
                ],
              ),
            ),

            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppRadius.cardBorder,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar row
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('CM', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cyber Magic Team', style: AppTypography.cardHeading),
                            const SizedBox(height: 4),
                            Text('Workspace Owner & Super Administrator', style: AppTypography.supporting),
                          ],
                        ),
                        const Spacer(),
                        OutlinedActionButton(
                          text: 'Change Avatar',
                          icon: LucideIcons.upload,
                          onPressed: () => AppToast.show(context, 'Avatar picker opened (Demo)', isSuccess: true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 24),

                    CustomTextField(
                      label: 'Full Name',
                      controller: _nameController,
                    ),
                    const SizedBox(height: 18),

                    CustomTextField(
                      label: 'Work Email Address',
                      controller: _emailController,
                    ),
                    const SizedBox(height: 24),

                    Text('Notification & AI Preferences', style: AppTypography.cardHeading),
                    const SizedBox(height: 12),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Email Notification on Post Approval'),
                      subtitle: const Text('Receive digest emails when posts are approved or require revisions.'),
                      value: _emailNotifications,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _emailNotifications = val),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable AI Content Studio Suggestions'),
                      subtitle: const Text('Autogenerate hashtag recommendations and peak engagement slots.'),
                      value: _aiAssistance,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _aiAssistance = val),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
