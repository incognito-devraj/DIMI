import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import '../../widgets/dimi_hero.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
                title: 'Privacy Policy',
                subtitle: 'Your data, your rights',
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
                        'Last Updated: June 2026',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 20),
                      _PolicySection(
                        title: '1. Overview',
                        body:
                            'DIMI is a local-first personal productivity application. '
                            'It is designed to work fully offline without requiring an '
                            'account. All data you enter — tasks, reminders, notes, '
                            'planner entries, financial records, and YouTube playlist '
                            'URLs — is stored on your device by default. No data leaves '
                            'your device unless you explicitly sign in with Google.',
                      ),
                      _PolicySection(
                        title: '2. Data We Do NOT Collect',
                        body:
                            'DIMI does not collect analytics, crash reports, usage '
                            'statistics, or any form of advertising identifiers. '
                            'There are no third-party tracking SDKs, no Firebase '
                            'integration, and no advertising network in the app. '
                            'DIMI does not communicate with any server except the '
                            'optional Supabase sync described below.',
                      ),
                      _PolicySection(
                        title: '3. Data Stored Locally on Your Device',
                        body:
                            'The following data is stored exclusively on your device '
                            'using an SQLite database managed by Drift:\n\n'
                            '• Tasks and to-do items\n'
                            '• Planner and timetable entries\n'
                            '• Reminders (title, time, recurrence settings)\n'
                            '• Notes\n'
                            '• Expense and income records\n'
                            '• YouTube playlist URLs and metadata you enter\n'
                            '• Profile display name and email (if provided)\n\n'
                            'This data is only accessible to DIMI and is not shared '
                            'with other apps except through standard Android file-sharing '
                            'mechanisms at your explicit request.',
                      ),
                      _PolicySection(
                        title: '4. Optional Google Sign-In and Cloud Sync',
                        body:
                            'DIMI offers an optional Google Sign-In powered by Supabase '
                            'OAuth. When you sign in:\n\n'
                            '• DIMI receives your Google account email address and '
                            'display name to identify your profile.\n'
                            '• The data listed in Section 3 is synchronised to your '
                            'Supabase account (hosted by Supabase, Inc.) so you can '
                            'access it on multiple devices.\n\n'
                            'Signing in is never required. You may use all core features '
                            'without an account. Supabase\'s own privacy policy applies '
                            'to data stored on their infrastructure.',
                      ),
                      _PolicySection(
                        title: '5. Financial Data',
                        body:
                            'Expense and income amounts are user-entered and stored '
                            'locally. If you are signed in, they are synced to Supabase '
                            'as part of your account data. DIMI never processes payments '
                            'and has no access to your bank accounts or payment instruments.',
                      ),
                      _PolicySection(
                        title: '6. Notifications',
                        body:
                            'DIMI uses local notifications to deliver reminders and '
                            'planner alerts. Notification content (reminder title and '
                            'time) is stored only on your device and is never transmitted '
                            'to any external server.',
                      ),
                      _PolicySection(
                        title: '7. YouTube Features',
                        body:
                            'DIMI lets you save YouTube playlist URLs for tracking '
                            'your watch progress. These URLs and your progress data '
                            'are stored locally (and synced via Supabase if signed in). '
                            'DIMI does not interact with the YouTube API, does not '
                            'embed videos, and does not scrape YouTube content.',
                      ),
                      _PolicySection(
                        title: '8. Data Deletion',
                        body:
                            'You can delete your local data at any time by clearing '
                            'app storage in your device\'s app settings.\n\n'
                            'If you are signed in, logging out does NOT delete your '
                            'local data. To remove your Supabase account data, use the '
                            'account deletion option in Settings → Account (coming in a '
                            'future update) or contact us at '
                            'devrajmukherjee.om@gmail.com.',
                      ),
                      _PolicySection(
                        title: '9. Third-Party Services',
                        body:
                            'The only third-party service DIMI integrates with is '
                            'Supabase (used for optional cloud sync and Google OAuth). '
                            'Supabase is subject to its own privacy policy available '
                            'at supabase.com/privacy. No other third-party services, '
                            'SDKs, or APIs are used.',
                      ),
                      _PolicySection(
                        title: '10. Security',
                        body:
                            'Local data is protected by Android\'s application sandbox '
                            'and device encryption (if enabled). Data synced to Supabase '
                            'is transmitted over HTTPS and encrypted at rest according to '
                            'Supabase\'s security practices.',
                      ),
                      _PolicySection(
                        title: '11. Children\'s Privacy',
                        body:
                            'DIMI is not directed at children under the age of 13. '
                            'We do not knowingly collect personal information from '
                            'children under 13. If you believe a child has provided '
                            'information through DIMI, please contact us so we can '
                            'take appropriate action.',
                      ),
                      _PolicySection(
                        title: '12. Changes to This Policy',
                        body:
                            'We may update this Privacy Policy from time to time. '
                            'Changes will be reflected in an updated version of the app '
                            'and on the GitHub repository. The "Last Updated" date at '
                            'the top of this policy will always reflect the most recent '
                            'revision.',
                      ),
                      _PolicySection(
                        title: '13. Contact Us',
                        body:
                            'If you have questions or concerns about this Privacy Policy '
                            'or DIMI\'s data practices, please contact:\n\n'
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
