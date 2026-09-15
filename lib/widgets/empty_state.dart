import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Generic empty-state widget used whenever a list has no data.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.asset,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? asset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: asset == null ? 72 : 112,
              height: asset == null ? 72 : 112,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                shape: BoxShape.circle,
              ),
              child: asset == null
                  ? Icon(icon, size: 34, color: AppColors.accent)
                  : Padding(
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(asset!, fit: BoxFit.contain),
                    ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
