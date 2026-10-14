import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

class DimiSocialLinks extends StatelessWidget {
  const DimiSocialLinks({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SocialButton(
          tooltip: 'GitHub: incognito-devraj',
          icon: FontAwesomeIcons.github,
          url: 'https://github.com/incognito-devraj',
        ),
        const SizedBox(width: 8),
        _SocialButton(
          tooltip: 'Instagram: devraj.om',
          icon: FontAwesomeIcons.instagram,
          url: 'https://instagram.com/devraj.om',
        ),
        const SizedBox(width: 8),
        _SocialButton(
          tooltip: 'LinkedIn: SecretSanju.om',
          icon: FontAwesomeIcons.linkedin,
          url: 'https://www.linkedin.com/in/SecretSanju.om',
        ),
        const SizedBox(width: 8),
        _SocialButton(
          tooltip: 'X: @SecretSanju',
          icon: FontAwesomeIcons.xTwitter,
          url: 'https://x.com/SecretSanju',
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.tooltip,
    required this.icon,
    required this.url,
  });

  final String tooltip;
  final FaIconData icon;
  final String url;

  Future<void> _open() async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: Ink(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.divider),
          ),
          child: InkWell(
            onTap: _open,
            customBorder: const CircleBorder(),
            child: Center(
              child: FaIcon(
                icon,
                size: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
