import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared sunrise hero treatment for the Profile and Settings experiences.
class DimiHero extends StatelessWidget {
  const DimiHero({
    super.key,
    required this.title,
    required this.subtitle,
    this.leading,
    this.trailing,
    this.quote,
    this.compactQuote = false,
    this.height = 300,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget? trailing;
  final String? quote;
  final bool compactQuote;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/Greeting/GreetingsBG.png',
              width: double.infinity,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withAlpha(190),
                    AppColors.background.withAlpha(30),
                    AppColors.background.withAlpha(220),
                  ],
                  stops: const [0, .42, 1],
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (leading != null) leading!,
                        if (leading != null) const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.displayLarge
                                ?.copyWith(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        if (trailing != null) trailing!,
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color.fromARGB(255, 0, 0, 0),
                        fontSize: 12,
                      ),
                    ),
                    if (quote != null && quote!.trim().isNotEmpty) ...[
                      const Spacer(),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 380),
                        padding: EdgeInsets.symmetric(
                          horizontal: compactQuote ? 12 : 16,
                          vertical: compactQuote ? 9 : 13,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withAlpha(205),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.surface.withAlpha(150),
                          ),
                        ),
                        child: Text(
                          quote!,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                                fontSize: compactQuote ? 12 : null,
                                height: 1.25,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DimiSectionHeading extends StatelessWidget {
  const DimiSectionHeading({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
        children: [
          Icon(icon, size: 21, color: AppColors.textPrimary),
          const SizedBox(width: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (subtitle != null) ...[
            const Spacer(),
            Flexible(
              child: Text(
                subtitle!,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DimiSurface extends StatelessWidget {
  const DimiSurface({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(245),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C1C1C1E),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class DimiHeroCircleButton extends StatelessWidget {
  const DimiHeroCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface.withAlpha(235),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 10),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }
}
