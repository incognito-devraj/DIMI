import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/supabase_config.dart';
import '../../routing/app_router.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../providers/database_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dimi_hero.dart';

// ── Update-check helpers ──────────────────────────────────────────────────────

/// Compares two semver-like strings by numeric parts.
/// Returns true if [remote] is strictly newer than [local].
bool _isNewer(String local, String remote) {
  List<int> parse(String v) => v
      .split('.')
      .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
      .toList();

  final l = parse(local);
  final r = parse(remote);
  final len = l.length > r.length ? l.length : r.length;
  for (var i = 0; i < len; i++) {
    final lv = i < l.length ? l[i] : 0;
    final rv = i < r.length ? r[i] : 0;
    if (rv > lv) return true;
    if (rv < lv) return false;
  }
  return false;
}

sealed class _UpdateResult {}

class _UpdateAvailable extends _UpdateResult {
  _UpdateAvailable({required this.version, required this.releaseNotes});
  final String version;
  final String releaseNotes;
}

class _AlreadyLatest extends _UpdateResult {
  _AlreadyLatest({required this.version});
  final String version;
}

class _UpdateError extends _UpdateResult {
  _UpdateError({required this.message});
  final String message;
}

/// Fetches the latest GitHub release and compares to the installed version.
/// Never throws — always returns one of the sealed results.
Future<_UpdateResult> _checkForUpdates() async {
  PackageInfo info;
  try {
    info = await PackageInfo.fromPlatform();
  } catch (_) {
    return _UpdateError(message: 'Could not read app version.');
  }

  const url =
      'https://api.github.com/repos/incognito-devraj/DIMI/releases/latest';

  http.Response response;
  try {
    response = await http
        .get(Uri.parse(url), headers: {'Accept': 'application/vnd.github+json'})
        .timeout(const Duration(seconds: 10));
  } on Exception {
    return _UpdateError(
      message:
          'Could not connect to GitHub. Please check your internet connection.',
    );
  }

  if (response.statusCode == 403 || response.statusCode == 429) {
    return _UpdateError(
      message: 'GitHub rate limit reached. Please try again later.',
    );
  }
  if (response.statusCode == 404) {
    return _UpdateError(message: 'No releases found yet. Check back soon!');
  }
  if (response.statusCode != 200) {
    return _UpdateError(
      message: 'Unexpected error (HTTP ${response.statusCode}). Try again.',
    );
  }

  Map<String, dynamic> json;
  try {
    json = jsonDecode(response.body) as Map<String, dynamic>;
  } catch (_) {
    return _UpdateError(message: 'Could not read the release data. Try again.');
  }

  final rawTag = (json['tag_name'] as String? ?? '').trim();
  final remoteVersion = rawTag.startsWith('v') ? rawTag.substring(1) : rawTag;
  final releaseNotes = (json['body'] as String? ?? '').trim();
  final localVersion = info.version;

  if (_isNewer(localVersion, remoteVersion)) {
    return _UpdateAvailable(
      version: remoteVersion,
      releaseNotes: releaseNotes.isEmpty
          ? 'No release notes provided.'
          : releaseNotes,
    );
  }
  return _AlreadyLatest(version: localVersion);
}

// ── Settings screen ───────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: DimiHero(
                title: 'Settings',
                subtitle: '        Small settings. Big progress.',
                height: 200,
                leading: DimiHeroCircleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 5)),
            _SectionHeader(title: 'Notifications'),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: _NotificationModeTile(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Data & Sync ───────────────────────────────────────────────
            _SectionHeader(title: 'Data & Sync'),
            _SectionCard(
              items: [
                _SettingsTile(
                  icon: Icons.cloud_outlined,
                  iconColor: AppColors.info,
                  label: 'Sync & Backup',
                  subtitle: 'Keep your data safe across devices',
                  onTap: () => _showComingSoon(context),
                ),
                _SettingsTile(
                  icon: Icons.storage_outlined,
                  iconColor: const Color(0xFF27AE60),
                  label: 'Manage Data',
                  subtitle: 'View, edit or clear your data',
                  onTap: () => _showComingSoon(context),
                ),
                _SettingsTile(
                  icon: Icons.download_outlined,
                  iconColor: const Color(0xFF1ABC9C),
                  label: 'Export Data',
                  subtitle: 'Download your data anytime',
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Support & About ───────────────────────────────────────────
            _SectionHeader(title: 'Support & About'),
            _SectionCard(
              items: [
                _SettingsTile(
                  icon: Icons.help_outline_rounded,
                  iconColor: AppColors.textSecondary,
                  label: 'Help & Support',
                  subtitle: 'Get help or contact us',
                  onTap: () => _showComingSoon(context),
                ),
                _SettingsTile(
                  icon: Icons.feedback_outlined,
                  iconColor: AppColors.textSecondary,
                  label: 'Feedback',
                  subtitle: 'Tell us how we can improve DIMI',
                  onTap: () => _showComingSoon(context),
                ),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  iconColor: AppColors.textSecondary,
                  label: 'Privacy Policy',
                  subtitle: 'How we handle your data',
                  onTap: () => _showComingSoon(context),
                ),
                _SettingsTile(
                  icon: Icons.verified_user_outlined,
                  iconColor: AppColors.textSecondary,
                  label: 'Terms of Service',
                  subtitle: 'Our terms and guidelines',
                  onTap: () => _showComingSoon(context),
                ),
                // ── Check for updates tile ────────────────────────────────
                const _CheckForUpdatesTile(),
                // ── About tile ────────────────────────────────────────────
                const _AboutTile(),
              ],
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Account ───────────────────────────────────────────────────
            _SectionHeader(title: 'Account'),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: Container(
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
                  child: const _AccountSection(),
                ),
              ),
            ),

            // ── DIMI wordmark footer ──────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: [
                    Text(
                      'DIMI',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Digital Interface For Monitoring and Improvement',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Created by incognito-devraj',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming in a future update'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── Check for updates tile ────────────────────────────────────────────────────

class _CheckForUpdatesTile extends StatefulWidget {
  const _CheckForUpdatesTile();

  @override
  State<_CheckForUpdatesTile> createState() => _CheckForUpdatesTileState();
}

class _CheckForUpdatesTileState extends State<_CheckForUpdatesTile> {
  bool _loading = false;
  String? _currentVersion;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _currentVersion = info.version);
    });
  }

  Future<void> _onTap() async {
    setState(() => _loading = true);
    final result = await _checkForUpdates();
    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case _UpdateAvailable(:final version, :final releaseNotes):
        await _showUpdateDialog(version, releaseNotes);
      case _AlreadyLatest(:final version):
        _showSnack('You\'re on the latest version ($version) 🎉');
      case _UpdateError(:final message):
        _showSnack(message);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showUpdateDialog(String version, String releaseNotes) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.system_update_rounded,
                size: 20,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Update available',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Version $version is available.',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Release notes',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Text(
                    releaseNotes,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Later',
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surfaceDark,
              foregroundColor: AppColors.surface,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
              elevation: 0,
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              const apkUrl =
                  'https://github.com/incognito-devraj/DIMI'
                  '/releases/latest/download/dimi-arm64.apk';
              final uri = Uri.parse(apkUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final versionLabel = _currentVersion != null
        ? 'Current version: $_currentVersion'
        : 'Check if a newer version is available';

    if (_loading) {
      return _SettingsTile(
        icon: Icons.update_rounded,
        iconColor: AppColors.accent,
        label: 'Check for updates',
        subtitle: 'Checking…',
        showChevron: false,
        trailing: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accent,
          ),
        ),
        onTap: null,
      );
    }

    return _SettingsTile(
      icon: Icons.update_rounded,
      iconColor: AppColors.accent,
      label: 'Check for updates',
      subtitle: versionLabel,
      onTap: _onTap,
    );
  }
}

// ── About tile ────────────────────────────────────────────────────────────────

class _AboutTile extends StatelessWidget {
  const _AboutTile();

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: Icons.info_outline_rounded,
      iconColor: AppColors.info,
      label: 'About DIMI',
      subtitle: 'Version info and creator credit',
      onTap: () => _showAbout(context),
    );
  }

  void _showAbout(BuildContext context) {
    PackageInfo.fromPlatform().then((info) {
      if (!context.mounted) return;
      showAboutDialog(
        context: context,
        applicationName: 'DIMI',
        applicationVersion: info.version,
        applicationIcon: const _DimiAboutIcon(),
        applicationLegalese: '© 2026 incognito-devraj',
        children: [
          const SizedBox(height: 16),
          const Text(
            'Created by incognito-devraj',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Digital Interface For Monitoring and Improvement.\n'
            'A local-first student productivity app.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      );
    });
  }
}

class _DimiAboutIcon extends StatelessWidget {
  const _DimiAboutIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: const Text(
        'D',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: AppColors.accent,
        ),
      ),
    );
  }
}

// ── Account section (needs StatefulWidget for async logout) ──────────────────

class _NotificationModeTile extends StatefulWidget {
  const _NotificationModeTile();

  @override
  State<_NotificationModeTile> createState() => _NotificationModeTileState();
}

class _NotificationModeTileState extends State<_NotificationModeTile> {
  late Future<bool> _mode;

  @override
  void initState() {
    super.initState();
    _mode = NotificationService.instance.isFullScreenModeEnabled();
  }

  Future<void> _choose(bool fullScreen) async {
    await NotificationService.instance.setNotificationMode(
      fullScreen
          ? DimiNotificationMode.fullScreen
          : DimiNotificationMode.normal,
    );
    if (!mounted) return;
    setState(() => _mode = Future.value(fullScreen));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _mode,
      builder: (context, snapshot) {
        final fullScreen = snapshot.data ?? false;
        return _SettingsTile(
          icon: Icons.notifications_active_outlined,
          iconColor: AppColors.accent,
          label: 'Notification Type',
          subtitle: fullScreen
              ? 'Full Screen Notification'
              : 'Normal Notification',
          onTap: () async {
            final selected = await showDialog<bool>(
              context: context,
              builder: (context) => SimpleDialog(
                title: const Text('Notification Type'),
                children: [
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Normal Notification'),
                  ),
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Full Screen Notification'),
                  ),
                ],
              ),
            );
            if (selected != null) await _choose(selected);
          },
        );
      },
    );
  }
}

class _AccountSection extends StatefulWidget {
  const _AccountSection();

  @override
  State<_AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends State<_AccountSection> {
  bool _loggingOut = false;

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        title: const Text(
          'Log Out?',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'This will sign you out. Your local data is NOT deleted.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    if (!mounted) return;

    setState(() => _loggingOut = true);

    // Clear offline mode flag regardless of auth method.
    SupabaseBootstrap.offlineMode = false;

    // Sign out from Supabase if an active session exists.
    if (SupabaseBootstrap.client?.auth.currentSession != null) {
      try {
        await AuthService.instance.signOut(
          ProviderScope.containerOf(
            context,
            listen: false,
          ).read(databaseProvider),
        );
      } catch (_) {
        // Ignore errors — we still navigate to login.
      }
    }
    if (!mounted) return;
    setState(() => _loggingOut = false);
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: Icons.logout_rounded,
      iconColor: AppColors.danger,
      label: _loggingOut ? 'Signing out…' : 'Log Out',
      subtitle: 'Sign out from your account',
      labelColor: AppColors.danger,
      onTap: _loggingOut ? null : _confirmLogout,
      showChevron: false,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          0,
          AppSpacing.screenHorizontal,
          8,
        ),
        child: DimiSectionHeading(
          icon: _iconForTitle(title),
          title: title,
          subtitle: _subtitleForTitle(title),
        ),
      ),
    );
  }

  IconData _iconForTitle(String title) {
    final icons = <String, IconData>{
      'Data & Sync': Icons.storage_rounded,
      'Support & About': Icons.help_outline_rounded,
      'Account': Icons.person_outline_rounded,
      'Developer': Icons.code_rounded,
    };
    return icons[title] ?? Icons.settings_outlined;
  }

  String? _subtitleForTitle(String title) {
    const subtitles = <String, String>{
      'Data & Sync': 'Your data, your control.',
      'Support & About': 'We\'re here for you.',
      'Account': 'Manage your account.',
      'Developer': 'Advanced tools.',
    };
    return subtitles[title];
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.items});
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
        ),
        child: Container(
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
          child: Column(
            children: List.generate(items.length, (i) {
              final isLast = i == items.length - 1;
              return Column(
                children: [
                  items[i],
                  if (!isLast)
                    const Divider(
                      height: 1,
                      indent: 54,
                      endIndent: 0,
                      color: AppColors.divider,
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Settings tile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.subtitle,
    this.trailing,
    this.labelColor,
    this.onTap,
    this.showChevron = true,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final Color? labelColor;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon container
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
            // Labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: labelColor ?? AppColors.textPrimary,
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
            if (trailing != null) ...[trailing!, const SizedBox(width: 4)],
            if (showChevron)
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
