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

class MediaGalleryScreen extends StatefulWidget {
  const MediaGalleryScreen({super.key});

  @override
  State<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends State<MediaGalleryScreen> {
  bool _isGridView = true;
  String _selectedFilter = 'All Media';

  final List<Map<String, String>> _mediaItems = [
    {
      'title': 'workspace_hero.png',
      'url': 'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=500',
      'type': 'Image (PNG)',
      'size': '1.4 MB',
      'date': 'May 18, 2025',
    },
    {
      'title': 'team_brainstorm.jpg',
      'url': 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=500',
      'type': 'Image (JPG)',
      'size': '2.1 MB',
      'date': 'May 17, 2025',
    },
    {
      'title': 'analytics_dashboard.png',
      'url': 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=500',
      'type': 'Image (PNG)',
      'size': '980 KB',
      'date': 'May 16, 2025',
    },
    {
      'title': 'project_showcase.jpg',
      'url': 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=500',
      'type': 'Image (JPG)',
      'size': '3.2 MB',
      'date': 'May 15, 2025',
    },
    {
      'title': 'client_success.jpg',
      'url': 'https://images.unsplash.com/photo-1531403009284-440f080d1e12?w=500',
      'type': 'Image (JPG)',
      'size': '1.8 MB',
      'date': 'May 14, 2025',
    },
    {
      'title': 'sunday_reset.jpg',
      'url': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=500',
      'type': 'Image (JPG)',
      'size': '2.4 MB',
      'date': 'May 13, 2025',
    },
  ];

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
              title: 'Media Asset Library',
              subtitle: 'Store, organize, and reuse multi-platform images, reels, and video assets.',
              breadcrumbs: const ['Workspace', 'Media Library'],
              action: Row(
                children: [
                  SecondaryButton(
                    text: 'Folders',
                    icon: LucideIcons.folder,
                    onPressed: () => context.go('/media/folders'),
                  ),
                  const SizedBox(width: 10),
                  PrimaryButton(
                    text: 'Upload Media',
                    icon: LucideIcons.uploadCloud,
                    onPressed: () => context.go('/media/upload'),
                  ),
                ],
              ),
            ),

            // Controls Bar
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.cardBorder,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const SearchField(hintText: 'Search assets by name or tag...', width: 280),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: _selectedFilter,
                    dropdownColor: AppColors.elevatedCard,
                    style: AppTypography.body,
                    items: ['All Media', 'Images', 'Videos', 'Documents']
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedFilter = val);
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(LucideIcons.layoutGrid, color: _isGridView ? AppColors.primary : AppColors.textSecondary),
                    onPressed: () => setState(() => _isGridView = true),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.list, color: !_isGridView ? AppColors.primary : AppColors.textSecondary),
                    onPressed: () => setState(() => _isGridView = false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Grid or List View
            if (_isGridView) _buildGridView() else _buildListView(),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth > 1100 ? 4 : (constraints.maxWidth > 700 ? 3 : 2);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.9,
          ),
          itemCount: _mediaItems.length,
          itemBuilder: (context, index) {
            final item = _mediaItems[index];
            return Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.cardBorder,
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: Image.network(
                        item['url']!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.cardHeading.copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item['size']!, style: AppTypography.chip.copyWith(color: AppColors.textMuted)),
                            Text(item['date']!, style: AppTypography.chip.copyWith(color: AppColors.textMuted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildListView() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _mediaItems.length,
        separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
        itemBuilder: (context, index) {
          final item = _mediaItems[index];
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(item['url']!, width: 44, height: 44, fit: BoxFit.cover),
            ),
            title: Text(item['title']!, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text('${item["type"]} • ${item["size"]} • Uploaded on ${item["date"]}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.download, size: 16),
                  onPressed: () => AppToast.show(context, 'Downloading ${item["title"]} (Demo)', isSuccess: true),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.danger),
                  onPressed: () => AppToast.show(context, 'Asset deleted (Demo)', isSuccess: true),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
