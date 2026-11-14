import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/dialogs.dart';

class MediaUploadScreen extends StatefulWidget {
  const MediaUploadScreen({super.key});

  @override
  State<MediaUploadScreen> createState() => _MediaUploadScreenState();
}

class _MediaUploadScreenState extends State<MediaUploadScreen> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  bool _hasCompleted = false;

  void _simulateUpload() async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.1;
      _hasCompleted = false;
    });

    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      setState(() => _uploadProgress = i / 10);
    }

    setState(() {
      _isUploading = false;
      _hasCompleted = true;
    });
    AppToast.show(context, '3 media files uploaded and indexed! (Demo)', isSuccess: true);
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
              title: 'Upload Media Assets',
              subtitle: 'Drag and drop high-res images, carousels, reels, and video clips.',
              breadcrumbs: const ['Workspace', 'Media Library', 'Upload'],
              action: SecondaryButton(
                text: 'Back to Gallery',
                icon: LucideIcons.arrowLeft,
                onPressed: () => context.go('/media'),
              ),
            ),

            // Drag and drop dropzone
            InkWell(
              onTap: _simulateUpload,
              borderRadius: AppRadius.cardBorder,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppRadius.cardBorder,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.5),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.uploadCloud, size: 30, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text('Drag and drop files here, or browse local disk', style: AppTypography.cardHeading),
                    const SizedBox(height: 6),
                    Text('Supports PNG, JPG, GIF, MP4, WEBM up to 250MB each.', style: AppTypography.supporting),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      text: 'Select Files to Upload',
                      icon: LucideIcons.folderPlus,
                      onPressed: _simulateUpload,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Upload Progress & Queue
            if (_isUploading || _hasCompleted)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppRadius.cardBorder,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Uploading Batch #2025-05', style: AppTypography.cardHeading),
                        Text('${(_uploadProgress * 100).toInt()}%', style: AppTypography.chip.copyWith(color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: AppColors.secondaryBackground,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 16),
                    _buildUploadFileRow('brand_keyframe_4k.png', '4.2 MB', _uploadProgress >= 1.0),
                    const SizedBox(height: 10),
                    _buildUploadFileRow('reel_teaser_final.mp4', '28.5 MB', _uploadProgress >= 0.7),
                    const SizedBox(height: 10),
                    _buildUploadFileRow('carousel_slide_1.png', '1.8 MB', _uploadProgress >= 0.4),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadFileRow(String name, String size, bool isDone) {
    return Row(
      children: [
        Icon(
          isDone ? LucideIcons.checkCircle : LucideIcons.loader2,
          size: 16,
          color: isDone ? AppColors.success : AppColors.primary,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(name, style: AppTypography.body.copyWith(fontSize: 13))),
        Text(size, style: AppTypography.chip.copyWith(color: AppColors.textMuted)),
      ],
    );
  }
}
