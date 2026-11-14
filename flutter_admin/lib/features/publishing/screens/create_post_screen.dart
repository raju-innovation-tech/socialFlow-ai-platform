import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/models/social_account.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/dialogs.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController(
    text: '🚀 Excited to announce our Q3 product roadmap! Exploring how AI-driven workflows streamline omni-channel reach without compromising creative nuance. Read more in our latest blog post.',
  );
  final Set<PlatformType> _selectedPlatforms = {
    PlatformType.linkedin,
    PlatformType.instagram,
    PlatformType.facebook,
  };
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _scheduledTime = const TimeOfDay(hour: 10, minute: 30);
  bool _isPublishing = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _handlePublishNow() async {
    setState(() => _isPublishing = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _isPublishing = false);
    AppToast.show(context, 'Post published to ${_selectedPlatforms.length} platforms! (Demo)', isSuccess: true);
    context.go('/publishing/queue');
  }

  void _handleSchedule() async {
    setState(() => _isPublishing = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _isPublishing = false);
    AppToast.show(context, 'Post scheduled for ${_scheduledDate.month}/${_scheduledDate.day} at ${_scheduledTime.format(context)}', isSuccess: true);
    context.go('/publishing/queue');
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
              title: 'Create & Publish Content',
              subtitle: 'Draft once, customize across platforms, and schedule with automated pacing.',
              breadcrumbs: const ['Publishing', 'Create Post'],
              action: Row(
                children: [
                  SecondaryButton(
                    text: 'Platform Editor',
                    icon: LucideIcons.sliders,
                    onPressed: () => context.go('/publishing/editor'),
                  ),
                  const SizedBox(width: 10),
                  SecondaryButton(
                    text: 'Multi-Preview',
                    icon: LucideIcons.eye,
                    onPressed: () => context.go('/publishing/preview'),
                  ),
                  const SizedBox(width: 10),
                  SecondaryButton(
                    text: 'Save Draft',
                    icon: LucideIcons.fileText,
                    onPressed: () {
                      AppToast.show(context, 'Draft saved successfully (Demo)', isSuccess: true);
                      context.go('/publishing/drafts');
                    },
                  ),
                  const SizedBox(width: 10),
                  PrimaryButton(
                    text: 'Publish Now',
                    icon: LucideIcons.send,
                    isLoading: _isPublishing,
                    onPressed: _handlePublishNow,
                  ),
                ],
              ),
            ),

            // Two-column responsive builder
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 950;
                return Flex(
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Editor Panel
                    Expanded(
                      flex: isWide ? 13 : 0,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: AppRadius.cardBorder,
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Select Target Platforms', style: AppTypography.cardHeading),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: PlatformType.values.map((platform) {
                                final isSelected = _selectedPlatforms.contains(platform);
                                return FilterChip(
                                  selected: isSelected,
                                  showCheckmark: true,
                                  checkmarkColor: Colors.white,
                                  backgroundColor: AppColors.secondaryBackground,
                                  selectedColor: AppColors.primary,
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      PlatformBrandIcon(
                                        platform: platform.name,
                                        size: 16,
                                        color: isSelected ? Colors.white : null,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        platform.name.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected ? Colors.white : AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedPlatforms.add(platform);
                                      } else {
                                        if (_selectedPlatforms.length > 1) {
                                          _selectedPlatforms.remove(platform);
                                        }
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),

                            Text('Post Caption / Content', style: AppTypography.cardHeading),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _contentController,
                              maxLines: 7,
                              style: AppTypography.body,
                              decoration: const InputDecoration(
                                hintText: 'What would you like to share today? Use #hashtags or @mentions...',
                                fillColor: AppColors.secondaryBackground,
                                filled: true,
                              ),
                            ),
                            const SizedBox(height: 12),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(LucideIcons.image, size: 18, color: AppColors.primary),
                                      tooltip: 'Add Media Image/Video',
                                      onPressed: () => context.go('/media'),
                                    ),
                                    IconButton(
                                      icon: const Icon(LucideIcons.sparkles, size: 18, color: AppColors.accentViolet),
                                      tooltip: 'Generate / Rewrite with AI',
                                      onPressed: () {
                                        setState(() {
                                          _contentController.text =
                                              '✨ Discover how our automated social pipeline turns raw ideas into multi-format campaigns that convert! #MarketingAutomation #SaaS #Growth';
                                        });
                                        AppToast.show(context, 'AI rewritten caption applied!', isSuccess: true);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(LucideIcons.hash, size: 18, color: AppColors.textSecondary),
                                      tooltip: 'Hashtag Suggestions',
                                      onPressed: () {
                                        setState(() {
                                          _contentController.text += ' #Productivity #AI #B2B';
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: _contentController,
                                  builder: (context, val, _) {
                                    return Text(
                                      '${val.text.length} / 2200 chars',
                                      style: AppTypography.chip.copyWith(color: AppColors.textSecondary),
                                    );
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),
                            // Media Preview box
                            Container(
                              height: 140,
                              decoration: BoxDecoration(
                                color: AppColors.secondaryBackground,
                                borderRadius: AppRadius.mdBorder,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                    ),
                                    child: Image.network(
                                      'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=300',
                                      width: 140,
                                      height: 140,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Attached Image: workspace_hero.png', style: AppTypography.cardHeading.copyWith(fontSize: 14)),
                                        const SizedBox(height: 4),
                                        Text('Resolution: 1920x1080 • Size: 1.4 MB', style: AppTypography.supporting),
                                        const SizedBox(height: 8),
                                        OutlinedActionButton(
                                          text: 'Change Media',
                                          icon: LucideIcons.refreshCw,
                                          onPressed: () => context.go('/media'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (isWide) const SizedBox(width: 20) else const SizedBox(height: 20),

                    // Right Schedule & Pacing Panel
                    Expanded(
                      flex: isWide ? 8 : 0,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: AppRadius.cardBorder,
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Scheduling & Queueing', style: AppTypography.cardHeading),
                            const SizedBox(height: 6),
                            Text('Select optimal time or let AI pick the peak engagement hour.', style: AppTypography.supporting),
                            const SizedBox(height: 20),

                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryBackground,
                                borderRadius: AppRadius.mdBorder,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Target Date:', style: AppTypography.supporting),
                                      TextButton.icon(
                                        icon: const Icon(LucideIcons.calendar, size: 14),
                                        label: Text('${_scheduledDate.month}/${_scheduledDate.day}/${_scheduledDate.year}'),
                                        onPressed: () async {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: _scheduledDate,
                                            firstDate: DateTime.now(),
                                            lastDate: DateTime.now().add(const Duration(days: 365)),
                                          );
                                          if (picked != null) setState(() => _scheduledDate = picked);
                                        },
                                      ),
                                    ],
                                  ),
                                  const Divider(color: AppColors.border),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Target Time:', style: AppTypography.supporting),
                                      TextButton.icon(
                                        icon: const Icon(LucideIcons.clock, size: 14),
                                        label: Text(_scheduledTime.format(context)),
                                        onPressed: () async {
                                          final picked = await showTimePicker(
                                            context: context,
                                            initialTime: _scheduledTime,
                                          );
                                          if (picked != null) setState(() => _scheduledTime = picked);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: AppRadius.mdBorder,
                                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.sparkles, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Recommended peak audience slot: 10:30 AM (Wednesday)',
                                      style: AppTypography.chip.copyWith(color: AppColors.primary, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            PrimaryButton(
                              text: 'Schedule Post',
                              isFullWidth: true,
                              icon: LucideIcons.calendarCheck,
                              isLoading: _isPublishing,
                              onPressed: _handleSchedule,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
