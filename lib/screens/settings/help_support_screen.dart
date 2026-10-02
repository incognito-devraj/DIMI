import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dimi_hero.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  // ── URL helpers ──────────────────────────────────────────────────────────

  Future<void> _launch(BuildContext context, Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open link. Please try manually.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: DimiHero(
                title: 'Help & Support',
                subtitle: 'We\'re here for you',
                height: 200,
                leading: DimiHeroCircleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => context.pop(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Contact ──────────────────────────────────────────────────
            _SectionLabel(label: 'Contact'),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: _Card(
                  children: [
                    _Tile(
                      icon: Icons.email_outlined,
                      iconColor: AppColors.info,
                      label: 'Email Support',
                      subtitle: AppConfig.supportEmail,
                      onTap: () => _launch(
                        context,
                        Uri.parse('mailto:${AppConfig.supportEmail}'),
                      ),
                    ),
                    const _Divider(),
                    _Tile(
                      icon: Icons.code_rounded,
                      iconColor: AppColors.textSecondary,
                      label: 'GitHub',
                      subtitle: 'View source and follow updates',
                      onTap: () =>
                          _launch(context, Uri.parse(AppConfig.githubRepoUrl)),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── FAQ ──────────────────────────────────────────────────────
            _SectionLabel(label: 'Frequently Asked Questions'),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: _FaqCard(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

// ─── FAQ ──────────────────────────────────────────────────────────────────────

class _FaqCard extends StatelessWidget {
  const _FaqCard();

  static const _items = [
    _FaqItem(
      question: 'Do I need an account to use DIMI?',
      answer:
          'No. DIMI is fully functional without an account. All your tasks, '
          'reminders, notes, planner entries, and expenses are stored locally '
          'on your device. An optional Google Sign-In is available if you want '
          'to sync data across devices.',
    ),
    _FaqItem(
      question: 'Is my data safe?',
      answer:
          'Yes. Without an account, your data never leaves your device. If you '
          'sign in, data is synced to Supabase, which uses industry-standard '
          'encryption at rest and in transit. DIMI never shares your data with '
          'advertisers or third parties.',
    ),
    _FaqItem(
      question: 'How do I back up my data?',
      answer:
          'Currently, data backup is done automatically through Supabase sync '
          'when you are signed in. A manual export feature is coming in a '
          'future update. Until then, signing in with Google is the recommended '
          'way to keep your data safe across devices.',
    ),
    _FaqItem(
      question: 'How do I get notifications to work?',
      answer:
          'Make sure DIMI has notification permission in your device settings. '
          'On Android 12 and above, also allow exact alarms in App Settings → '
          'DIMI → Alarms & Reminders. Disabling battery optimisation for DIMI '
          'ensures reminders fire reliably even when the screen is off.',
    ),
    _FaqItem(
      question: 'What does Full Screen notification mode do?',
      answer:
          'In Full Screen mode, reminder and planner notifications are shown '
          'as a full-screen overlay on your lock screen, similar to an incoming '
          'call. This is useful for important reminders you don\'t want to '
          'miss. Normal mode shows a standard notification in the shade.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1C1C1E),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          expansionTileTheme: const ExpansionTileThemeData(
            backgroundColor: AppColors.surface,
            collapsedBackgroundColor: AppColors.surface,
            iconColor: AppColors.accent,
            collapsedIconColor: AppColors.textSecondary,
          ),
          dividerColor: AppColors.divider,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: Column(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final isLast = i == _items.length - 1;
              return Column(
                children: [
                  ExpansionTile(
                    title: Text(
                      item.question,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          item.answer,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!isLast)
                    const Divider(height: 1, color: AppColors.divider),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _FaqItem {
  const _FaqItem({required this.question, required this.answer});
  final String question;
  final String answer;
}

// ─── Shared local widgets ─────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          0,
          AppSpacing.screenHorizontal,
          10,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1C1C1E),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 54, color: AppColors.divider);
  }
}
