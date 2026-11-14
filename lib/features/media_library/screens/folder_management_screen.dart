import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/dialogs.dart';

class FolderManagementScreen extends StatefulWidget {
  const FolderManagementScreen({super.key});

  @override
  State<FolderManagementScreen> createState() => _FolderManagementScreenState();
}

class _FolderManagementScreenState extends State<FolderManagementScreen> {
  final List<Map<String, dynamic>> _folders = [
    {'name': 'Campaigns 2025', 'items': 42, 'color': AppColors.primary},
    {'name': 'Instagram Reels & Stories', 'items': 18, 'color': AppColors.instagram},
    {'name': 'Product Screenshots', 'items': 35, 'color': AppColors.accentViolet},
    {'name': 'Brand Guidelines & Logos', 'items': 12, 'color': AppColors.warning},
    {'name': 'Client Testimonials', 'items': 9, 'color': AppColors.success},
  ];

  void _showNewFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevatedCard,
        title: Text('Create Folder', style: AppTypography.cardHeading),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Folder name, e.g. Summer Launch'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          PrimaryButton(
            text: 'Create',
            height: 36,
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _folders.add({'name': controller.text, 'items': 0, 'color': AppColors.primary});
                });
                Navigator.pop(context);
                AppToast.show(context, 'Folder created! (Demo)', isSuccess: true);
              }
            },
          ),
        ],
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
              title: 'Media Folders & Hierarchy',
              subtitle: 'Organize assets into categorized folders for seamless campaign reuse.',
              breadcrumbs: const ['Workspace', 'Media Library', 'Folders'],
              action: Row(
                children: [
                  SecondaryButton(
                    text: 'View All Media',
                    icon: LucideIcons.image,
                    onPressed: () => context.go('/media'),
                  ),
                  const SizedBox(width: 10),
                  PrimaryButton(
                    text: 'New Folder',
                    icon: LucideIcons.folderPlus,
                    onPressed: _showNewFolderDialog,
                  ),
                ],
              ),
            ),

            LayoutBuilder(
              builder: (context, constraints) {
                final count = constraints.maxWidth > 1100 ? 4 : (constraints.maxWidth > 700 ? 3 : 2);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: count,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: _folders.length,
                  itemBuilder: (context, index) {
                    final f = _folders[index];
                    return InkWell(
                      onTap: () => context.go('/media'),
                      borderRadius: AppRadius.cardBorder,
                      child: Container(
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (f['color'] as Color).withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(LucideIcons.folder, color: f['color'] as Color, size: 20),
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.moreVertical, size: 14, color: AppColors.textSecondary),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(f['name'], style: AppTypography.cardHeading.copyWith(fontSize: 14), overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text('${f["items"]} items', style: AppTypography.chip.copyWith(color: AppColors.textMuted)),
                              ],
                            ),
                          ],
                        ),
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
