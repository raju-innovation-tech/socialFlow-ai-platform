import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_header.dart';

class MultiPreviewScreen extends StatefulWidget {
  const MultiPreviewScreen({super.key});

  @override
  State<MultiPreviewScreen> createState() => _MultiPreviewScreenState();
}

class _MultiPreviewScreenState extends State<MultiPreviewScreen> {
  String _activePlatform = 'LinkedIn';
  final List<String> _platforms = ['LinkedIn', 'Instagram', 'Facebook', 'X', 'YouTube', 'WhatsApp', 'Telegram'];

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
              title: 'Multi-Platform Live Previews',
              subtitle: 'Exact native device rendering simulation for all 7 supported channels.',
              breadcrumbs: const ['Publishing', 'Multi-Preview'],
              action: Row(
                children: [
                  SecondaryButton(
                    text: 'Edit Post',
                    icon: LucideIcons.fileEdit,
                    onPressed: () => context.go('/publishing/create'),
                  ),
                  const SizedBox(width: 10),
                  PrimaryButton(
                    text: 'Confirm & Publish',
                    icon: LucideIcons.checkCheck,
                    onPressed: () => context.go('/publishing/queue'),
                  ),
                ],
              ),
            ),

            // Platform Selector Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _platforms.map((p) {
                  final isSelected = _activePlatform == p;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      onTap: () => setState(() => _activePlatform = p),
                      borderRadius: AppRadius.pillBorder,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.card,
                          borderRadius: AppRadius.pillBorder,
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            PlatformBrandIcon(platform: p, size: 16, color: isSelected ? Colors.white : null),
                            const SizedBox(width: 8),
                            Text(
                              p,
                              style: AppTypography.chip.copyWith(
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Centered Realistic Mockup Container
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 550),
                child: _buildSelectedMockup(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedMockup() {
    switch (_activePlatform) {
      case 'LinkedIn':
        return _buildLinkedInMockup();
      case 'Instagram':
        return _buildInstagramMockup();
      case 'Facebook':
        return _buildFacebookMockup();
      case 'X':
        return _buildXMockup();
      case 'YouTube':
        return _buildYouTubeMockup();
      case 'WhatsApp':
        return _buildWhatsAppMockup();
      case 'Telegram':
        return _buildTelegramMockup();
      default:
        return _buildLinkedInMockup();
    }
  }

  Widget _buildLinkedInMockup() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1B222E),
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.linkedin,
                child: Text('CM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cyber Magic Inc.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('65,400 followers • Promoted', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                  ],
                ),
              ),
              const Icon(LucideIcons.moreHorizontal, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            '🚀 Excited to announce our Q3 product roadmap! Exploring how AI-driven workflows streamline omni-channel reach without compromising creative nuance.\n\n#B2B #Marketing #Growth #AI',
            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=600',
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MockAction(icon: LucideIcons.thumbsUp, label: 'Like'),
              _MockAction(icon: LucideIcons.messageSquare, label: 'Comment'),
              _MockAction(icon: LucideIcons.share2, label: 'Repost'),
              _MockAction(icon: LucideIcons.send, label: 'Send'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstagramMockup() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.purple, Colors.orange]),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('CM', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('cybermagic.studio', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                const Spacer(),
                const Icon(LucideIcons.moreVertical, color: Colors.white),
              ],
            ),
          ),
          Image.network(
            'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=600',
            height: 300,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(LucideIcons.heart, color: Colors.white, size: 20),
                    SizedBox(width: 14),
                    Icon(LucideIcons.messageCircle, color: Colors.white, size: 20),
                    SizedBox(width: 14),
                    Icon(LucideIcons.send, color: Colors.white, size: 20),
                    Spacer(),
                    Icon(LucideIcons.bookmark, color: Colors.white, size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('1,420 likes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 12, color: Colors.white),
                    children: [
                      TextSpan(text: 'cybermagic.studio ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: 'Minimalism meets spatial design. Here are the 5 top trends defining modern interfaces this year. ✨ #design'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacebookMockup() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF242526),
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.facebook,
                child: Icon(Icons.facebook_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cyber Magic', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('Just now • 🌐', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(LucideIcons.moreHorizontal, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'We are excited to share our latest case study! Learn how smart automation saved 16.5 hours this week alone.',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=600',
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXMockup() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Text('X', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              const Text('Cyber Magic', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              const Icon(LucideIcons.checkCircle, color: Colors.blue, size: 14),
              const SizedBox(width: 6),
              const Text('@CyberMagicHQ • 1m', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Automating multi-channel distribution without losing your brand nuance:\n\n1/ Format copy natively\n2/ Optimize posting hours\n3/ Automate repetitive workflows 🚀',
            style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=600',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYouTubeMockup() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=600',
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(LucideIcons.play, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Next-Gen Social Flow AI: Full Studio Walkthrough & Architecture',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
          const Text('Cyber Magic Official • 94K views • 2 hours ago', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildWhatsAppMockup() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B141A),
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.whatsapp,
                child: Icon(LucideIcons.phoneCall, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Text('Cyber Magic Official Broadcast', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF005C4B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '📢 Hi Alex! Your scheduled campaign report is ready. Click below to view performance analytics.\n\n10:30 AM ✓✓',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelegramMockup() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF17212B),
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.telegram,
                child: Icon(LucideIcons.send, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Text('Cyber Magic VIP Channel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const Spacer(),
              const Text('14.8K subscribers', style: TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF242F3D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '⚡ Early Access Alert: New automated pipeline is live. Join today’s live walkthrough at 4 PM UTC.\n\n11:00 AM • 4.2K views',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockAction extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MockAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
