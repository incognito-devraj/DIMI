import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/update_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dimi_hero.dart';

// ─── State machine ────────────────────────────────────────────────────────────

enum _UpdateState {
  idle,
  checking,
  upToDate,
  updateAvailable,
  downloading,
  error,
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  _UpdateState _state = _UpdateState.idle;
  String _currentVersion = '';
  UpdateResultAvailable? _updateResult;
  String _errorMessage = '';
  double _downloadProgress = 0.0;
  bool _cancelDownload = false;
  DateTime? _lastChecked;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _currentVersion = info.version);
    });
  }

  // ── Check ──────────────────────────────────────────────────────────────────

  Future<void> _doCheck() async {
    setState(() => _state = _UpdateState.checking);
    final result = await UpdateService.instance.checkForUpdates();
    if (!mounted) return;
    setState(() {
      _lastChecked = DateTime.now();
      switch (result) {
        case UpdateResultUpToDate(:final currentVersion):
          _currentVersion = currentVersion;
          _state = _UpdateState.upToDate;
        case final UpdateResultAvailable available:
          _updateResult = available;
          _currentVersion = available.currentVersion;
          _state = _UpdateState.updateAvailable;
        case UpdateResultError(:final message):
          _errorMessage = message;
          _state = _UpdateState.error;
      }
    });
  }

  // ── Download ───────────────────────────────────────────────────────────────

  Future<void> _doDownload() async {
    final release = _updateResult!;
    if (release.apkAssetUrl == null) {
      setState(() {
        _errorMessage = 'No APK asset attached to this release.';
        _state = _UpdateState.error;
      });
      return;
    }

    setState(() {
      _state = _UpdateState.downloading;
      _downloadProgress = 0.0;
      _cancelDownload = false;
    });

    try {
      final file = await UpdateService.instance.downloadApk(
        release.apkAssetUrl!,
        onProgress: (p) {
          if (mounted) setState(() => _downloadProgress = p);
        },
        isCancelled: () => _cancelDownload,
      );
      if (!mounted) return;

      // Trigger the Android package installer.
      // Files on getExternalStorageDirectory() are accessible directly without
      // a FileProvider — REQUEST_INSTALL_PACKAGES permission handles the rest.
      final uri = Uri.file(file.path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        // Return to updateAvailable so user can retry if installer is dismissed.
        if (mounted) setState(() => _state = _UpdateState.updateAvailable);
      } else {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Could not launch the installer. APK saved at: ${file.path}';
            _state = _UpdateState.error;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      if (_cancelDownload) {
        setState(() => _state = _UpdateState.updateAvailable);
      } else {
        setState(() {
          _errorMessage = 'Download failed: ${e.toString()}';
          _state = _UpdateState.error;
        });
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  ButtonStyle get _darkButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: AppColors.surfaceDark,
    foregroundColor: AppColors.surface,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
    ),
    elevation: 0,
    textStyle: const TextStyle(
      fontFamily: 'Inter',
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
  );

  // ── Version card ───────────────────────────────────────────────────────────

  Widget _versionCard() {
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: AppColors.surfaceDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.system_update_rounded,
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Installed version',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentVersion.isEmpty ? 'Loading…' : 'v$_currentVersion',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Action area ────────────────────────────────────────────────────────────

  Widget _actionArea() {
    switch (_state) {
      case _UpdateState.idle:
        return _idleArea();
      case _UpdateState.checking:
        return _checkingArea();
      case _UpdateState.upToDate:
        return _upToDateArea();
      case _UpdateState.updateAvailable:
        return _updateAvailableArea();
      case _UpdateState.downloading:
        return _downloadingArea();
      case _UpdateState.error:
        return _errorArea();
    }
  }

  Widget _idleArea() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: _darkButtonStyle,
        onPressed: _doCheck,
        child: const Text('Check for Updates'),
      ),
    );
  }

  Widget _checkingArea() {
    return _card(
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.accent),
          SizedBox(height: 16),
          Text(
            'Checking for updates…',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _upToDateArea() {
    final timeLabel = _lastChecked != null
        ? 'Last checked: ${_formatTime(_lastChecked!)}'
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.success,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'You\'re on the latest version',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'v$_currentVersion',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              if (timeLabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  timeLabel,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: _darkButtonStyle,
            onPressed: _doCheck,
            child: const Text('Check Again'),
          ),
        ),
      ],
    );
  }

  Widget _updateAvailableArea() {
    final release = _updateResult!;
    return _card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amber banner
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  size: 22,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Update available',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                    Text(
                      'v${release.latestVersion} is ready to install',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          _versionRow(
            'Current version',
            'v$_currentVersion',
            AppColors.textSecondary,
          ),
          const SizedBox(height: 4),
          _versionRow(
            'Latest version',
            'v${release.latestVersion}',
            AppColors.accent,
          ),
          // Release notes
          if (release.releaseNotes.isNotEmpty &&
              release.releaseNotes != 'No release notes provided.') ...[
            const SizedBox(height: 16),
            const Text(
              'What\'s New',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: SingleChildScrollView(
                child: Text(
                  release.releaseNotes,
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
          const SizedBox(height: 20),
          if (release.apkAssetUrl != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: _darkButtonStyle,
                onPressed: _doDownload,
                child: const Text('Download & Install'),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'APK not found in this release. Download manually on GitHub.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => launchUrl(
                Uri.parse(release.releasePageUrl),
                mode: LaunchMode.externalApplication,
              ),
              child: const Text(
                'View on GitHub',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.info,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _doCheck,
              child: const Text(
                'Check Again',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _downloadingArea() {
    final knownProgress = _downloadProgress >= 0;
    return _card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Downloading update…',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: knownProgress ? _downloadProgress : null,
            backgroundColor: AppColors.divider,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
          ),
          const SizedBox(height: 8),
          if (knownProgress)
            Text(
              '${(_downloadProgress * 100).toStringAsFixed(0)}%',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() => _cancelDownload = true),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorArea() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.danger,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: _darkButtonStyle,
            onPressed: _doCheck,
            child: const Text('Try Again'),
          ),
        ),
      ],
    );
  }

  // ── Small helpers ──────────────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: child,
    );
  }

  Widget _versionRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
                title: 'Updates',
                subtitle: 'Keep DIMI fresh',
                height: 200,
                leading: DimiHeroCircleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => context.pop(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: _versionCard(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: _actionArea(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}
