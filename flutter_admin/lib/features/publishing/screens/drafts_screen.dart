import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/models/post_item.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/dialogs.dart';

class DraftsScreen extends StatefulWidget {
  const DraftsScreen({super.key});

  @override
  State<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<DraftsScreen> {
  late List<PostItem> _drafts;

  @override
  void initState() {
    super.initState();
    _drafts = MockData.posts.where((p) => p.status == PostStatus.draft).toList();
  }

  void _deleteDraft(PostItem post) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete Draft?',
        message: 'Are you sure you want to delete "${post.title}"? This cannot be undone.',
        confirmText: 'Delete',
        isDestructive: true,
        onConfirm: () {
          setState(() {
            _drafts.removeWhere((p) => p.id == post.id);
          });
          AppToast.show(context, 'Draft deleted (Demo)', isSuccess: true);
        },
      ),
    );
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
              title: 'Draft Posts',
              subtitle: 'Work in progress ideas and unapproved concept drafts.',
              breadcrumbs: const ['Publishing', 'Drafts'],
              action: PrimaryButton(
                text: 'New Draft',
                icon: LucideIcons.plus,
                onPressed: () => context.go('/publishing/create'),
              ),
            ),

            if (_drafts.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppRadius.cardBorder,
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text('No active drafts found. Create one now!', style: AppTypography.subHeading),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final cols = constraints.maxWidth > 950 ? 2 : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: _drafts.length,
                    itemBuilder: (context, index) {
                      final draft = _drafts[index];
                      return Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: AppRadius.cardBorder,
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                ...draft.platforms.map((p) => Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: PlatformBrandIcon(platform: p.name, size: 20),
                                    )),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.danger),
                                  onPressed: () => _deleteDraft(draft),
                                ),
                              ],
                            ),
                            Text(draft.title, style: AppTypography.cardHeading),
                            Text(
                              draft.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.supporting,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Created by ${draft.authorName}', style: AppTypography.chip.copyWith(color: AppColors.textMuted)),
                                PrimaryButton(
                                  text: 'Continue Editing',
                                  height: 32,
                                  icon: LucideIcons.fileEdit,
                                  onPressed: () => context.go('/publishing/create'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
