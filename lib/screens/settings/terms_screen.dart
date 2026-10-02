import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import '../../widgets/dimi_hero.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
                title: 'Terms of Service',
                subtitle: 'Fair terms for everyone',
                height: 200,
                leading: DimiHeroCircleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => context.pop(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(color: AppColors.divider),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A1C1C1E),
                        blurRadius: 12,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Effective: January 2026',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 20),
                      _PolicySection(
                        title: '1. Acceptance',
                        body:
                            'By downloading, installing, or using DIMI, you agree to '
                            'be bound by these Terms of Service. If you do not agree, '
                            'please do not use the application.',
                      ),
                      _PolicySection(
                        title: '2. Description of Service',
                        body:
                            'DIMI is a free personal productivity application designed '
                            'for students. It helps you manage tasks, class schedules, '
                            'study sessions, reminders, notes, and personal finances. '
                            'The application is provided as-is, at no cost, and is '
                            'independently developed.',
                      ),
                      _PolicySection(
                        title: '3. User Content',
                        body:
                            'You own all data and content you enter into DIMI — tasks, '
                            'notes, financial records, reminders, and any other '
                            'information. DIMI does not claim any ownership over your '
                            'content. You are responsible for the accuracy of the '
                            'information you enter.',
                      ),
                      _PolicySection(
                        title: '4. Acceptable Use',
                        body:
                            'You agree to use DIMI only for lawful personal purposes. '
                            'You may not:\n\n'
                            '• Use DIMI to store or distribute illegal content\n'
                            '• Attempt to reverse-engineer, decompile, or tamper with '
                            'the application\n'
                            '• Use automated tools to scrape or extract data from the app\n'
                            '• Circumvent any security or authentication measures',
                      ),
                      _PolicySection(
                        title: '5. No Warranty',
                        body:
                            'DIMI is provided "as is" without any warranty, express or '
                            'implied. We do not warrant that the application will be '
                            'error-free, uninterrupted, or free of bugs. Use DIMI at '
                            'your own risk. We strongly recommend keeping backups of '
                            'important data.',
                      ),
                      _PolicySection(
                        title: '6. Limitation of Liability',
                        body:
                            'To the fullest extent permitted by applicable law, the '
                            'developer of DIMI shall not be liable for any indirect, '
                            'incidental, special, or consequential damages, including '
                            'loss of data, arising from your use of or inability to use '
                            'the application.',
                      ),
                      _PolicySection(
                        title: '7. Availability',
                        body:
                            'DIMI is a local-first application and does not depend on '
                            'server availability for core features. The optional cloud '
                            'sync feature depends on Supabase infrastructure. We do not '
                            'guarantee continuous availability of any cloud-dependent '
                            'features.',
                      ),
                      _PolicySection(
                        title: '8. Updates to the App',
                        body:
                            'We may release updates to DIMI from time to time. Updates '
                            'may add, change, or remove features. We will not remove '
                            'core offline functionality in an update without reasonable '
                            'notice. Installing updates is optional but recommended for '
                            'security and bug fixes.',
                      ),
                      _PolicySection(
                        title: '9. Intellectual Property',
                        body:
                            'The DIMI name, logo, design, and source code are the '
                            'intellectual property of incognito-devraj. You may not '
                            'reproduce, redistribute, or create derivative works from '
                            'any part of DIMI without explicit written permission, '
                            'except where permitted by the applicable open-source '
                            'licence (if any).',
                      ),
                      _PolicySection(
                        title: '10. Changes to Terms',
                        body:
                            'We reserve the right to update these Terms of Service. '
                            'Material changes will be communicated through an app '
                            'update. Continued use of DIMI after changes are published '
                            'constitutes your acceptance of the revised terms.',
                      ),
                      _PolicySection(
                        title: '11. Contact',
                        body:
                            'For questions about these Terms, please contact:\n\n'
                            'devrajmukherjee.om@gmail.com\n\n'
                            'Or open an issue on GitHub:\n'
                            'github.com/incognito-devraj/DIMI/issues',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

// ─── Policy section widget ────────────────────────────────────────────────────

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
