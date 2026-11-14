import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../../../app/providers/publishing_provider.dart';
import '../../../app/providers/social_accounts_provider.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _contentController = TextEditingController(
    text: '🚀 Excited to share our new product update! Exploring how unified social operations streamline omni-channel reach. Read our full overview and let us know your thoughts.',
  );
  final Set<PlatformType> _selectedPlatforms = {
    PlatformType.linkedin,
    PlatformType.twitter,
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

  List<String> _getSelectedAccountIds() {
    final accounts = ref.read(socialAccountsProvider).accounts;
    final ids = <String>[];
    for (final acc in accounts) {
      if (_selectedPlatforms.contains(acc.platform)) {
        ids.add(acc.id);
      }
    }
    return ids;
  }

  void _handlePublishNow() async {
    final text = _contentController.text.trim();
    if (text.isEmpty) {
      AppToast.show(context, 'Please enter post content', isError: true);
      return;
    }

    setState(() => _isPublishing = true);
    final targetIds = _getSelectedAccountIds();

    final created = await ref.read(publishingProvider.notifier).createPost(
      content: text,
      targetAccountIds: targetIds,
    );

    if (!mounted) return;

    if (created != null && created['id'] != null) {
      final postId = created['id'] as String;
      final pubResult = await ref.read(publishingProvider.notifier).publishNow(postId);
      if (!mounted) return;
      setState(() => _isPublishing = false);

      if (pubResult != null) {
        AppToast.show(
          context,
          'Publishing completed (${pubResult['overall_status']})',
          isSuccess: pubResult['overall_status'] != 'failed',
          isError: pubResult['overall_status'] == 'failed',
        );
      }
      context.go('/publishing/queue');
    } else {
      setState(() => _isPublishing = false);
      AppToast.show(context, 'Failed to create post record', isError: true);
    }
  }

  void _handleSchedule() async {
    final text = _contentController.text.trim();
    if (text.isEmpty) {
      AppToast.show(context, 'Please enter post content', isError: true);
      return;
    }

    final targetDateTime = DateTime(
      _scheduledDate.year,
      _scheduledDate.month,
      _scheduledDate.day,
      _scheduledTime.hour,
      _scheduledTime.minute,
    );

    if (targetDateTime.isBefore(DateTime.now())) {
      AppToast.show(context, 'Scheduled time must be in the future', isError: true);
      return;
    }

    setState(() => _isPublishing = true);
    final targetIds = _getSelectedAccountIds();

    final created = await ref.read(publishingProvider.notifier).createPost(
      content: text,
      scheduledAt: targetDateTime,
      targetAccountIds: targetIds,
    );

    if (!mounted) return;
    setState(() => _isPublishing = false);

    if (created != null) {
      AppToast.show(
        context,
        'Post scheduled for ${_scheduledDate.month}/${_scheduledDate.day} at ${_scheduledTime.format(context)}',
        isSuccess: true,
      );
      context.go('/publishing/queue');
    } else {
      AppToast.show(context, 'Failed to schedule post', isError: true);
    }
  }

  void _handleSaveDraft() async {
    final text = _contentController.text.trim();
    if (text.isEmpty) {
      AppToast.show(context, 'Please enter post content', isError: true);
      return;
    }

    setState(() => _isPublishing = true);
    final targetIds = _getSelectedAccountIds();

    final created = await ref.read(publishingProvider.notifier).createPost(
      content: text,
      targetAccountIds: targetIds,
    );

    if (!mounted) return;
    setState(() => _isPublishing = false);

    if (created != null) {
      AppToast.show(context, 'Draft saved successfully', isSuccess: true);
      context.go('/publishing/drafts');
    } else {
      AppToast.show(context, 'Failed to save draft', isError: true);
    }
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
                    onPressed: _handleSaveDraft,
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
                                      icon: const Icon(LucideIcons.hash, size: 18, color: AppColors.textSecondary),
                                      tooltip: 'Insert Hashtags',
                                      onPressed: () {
                                        setState(() {
                                          _contentController.text += ' #Productivity #SaaS #Growth';
                                        });
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(LucideIcons.link, size: 18, color: AppColors.textSecondary),
                                      tooltip: 'Insert Link',
                                      onPressed: () {
                                        setState(() {
                                          _contentController.text += ' https://socialflow.ai';
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: _contentController,
                                  builder: (context, val, _) {
                                    return Text(
                                      '${val.text.length} chars',
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
                                        Text('campaign_hero_banner.png', style: AppTypography.cardHeading.copyWith(fontSize: 14)),
                                        const SizedBox(height: 4),
                                        Text('1920 × 1080 • 1.4 MB • PNG', style: AppTypography.supporting),
                                        const SizedBox(height: 8),
                                        Text('Compliant with all 7 platforms', style: AppTypography.chip.copyWith(color: AppColors.success)),
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

                    if (isWide) const SizedBox(width: 24) else const SizedBox(height: 24),

                    // Right Schedule & Configuration Panel
                    Expanded(
                      flex: isWide ? 7 : 0,
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
                            Text('Publishing Schedule', style: AppTypography.cardHeading),
                            const SizedBox(height: 6),
                            Text('Queue for automated publication or target peak engagement.', style: AppTypography.supporting),
                            const SizedBox(height: 18),

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
                                  const Icon(LucideIcons.clock, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Timezone: Workspace UTC (Standard)',
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
