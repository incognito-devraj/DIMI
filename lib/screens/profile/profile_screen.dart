import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';

import '../../data/database.dart';
import '../../providers/class_providers.dart';
import '../../providers/profile_providers.dart';
import '../../providers/task_providers.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) => profile == null
              ? const Center(child: Text('No profile data yet.'))
              : _ProfileView(profile: profile),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

// ── View mode ─────────────────────────────────────────────────────────────────

class _ProfileView extends ConsumerWidget {
  const _ProfileView({required this.profile});
  final ProfileTableData profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTasksAsync = ref.watch(allTasksProvider);
    final allClassesAsync = ref.watch(allClassesProvider);

    final totalTasks = allTasksAsync.valueOrNull?.length ?? 0;
    final completedTasks =
        allTasksAsync.valueOrNull?.where((t) => t.isCompleted).length ?? 0;
    final totalClasses = allClassesAsync.valueOrNull?.length ?? 0;
    final goalPct = totalTasks == 0
        ? 0
        : ((completedTasks / totalTasks) * 100).round();

    return CustomScrollView(
      slivers: [
        // ── Header ────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              20,
              AppSpacing.screenHorizontal,
              0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profile',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                _EditButton(onTap: () => _openEditSheet(context, profile)),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // ── Avatar + name card ────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: _AvatarCard(profile: profile),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // ── Stats row ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: _StatsRow(
              tasks: totalTasks,
              classes: totalClasses,
              goalPct: goalPct,
              points: profile.points,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // ── Contact info card ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: _InfoCard(profile: profile),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // ── Quote card ────────────────────────────────────────────────────
        if (profile.quote != null && profile.quote!.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: _QuoteCard(quote: profile.quote!),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  void _openEditSheet(BuildContext context, ProfileTableData profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(profile: profile),
    );
  }
}

// ── Avatar card ───────────────────────────────────────────────────────────────

class _AvatarCard extends StatelessWidget {
  const _AvatarCard({required this.profile});
  final ProfileTableData profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.accent,
            backgroundImage: profile.photoPath != null
                ? FileImage(File(profile.photoPath!))
                : null,
            child: Text(
              profile.name.isNotEmpty
                  ? profile.name.substring(0, 1).toUpperCase()
                  : 'S',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.surfaceDark,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.surface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.role,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.accentSoft,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      size: 12,
                      color: AppColors.accentSoft,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${profile.college} · ${profile.semester}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.accentSoft,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, size: 13, color: AppColors.surfaceDark),
                const SizedBox(width: 4),
                Text('${profile.points}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.surfaceDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.tasks,
    required this.classes,
    required this.goalPct,
    required this.points,
  });
  final int tasks;
  final int classes;
  final int goalPct;
  final int points;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(label: 'Tasks', value: '$tasks'),
        ),
        const SizedBox(width: AppSpacing.cardGap),
        Expanded(
          child: _StatCard(label: 'Classes', value: '$classes'),
        ),
        const SizedBox(width: AppSpacing.cardGap),
        Expanded(
          child: _StatCard(label: 'Goal', value: '$goalPct%'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.profile});
  final ProfileTableData profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contact Info', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: profile.email,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: profile.phone,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.school_outlined,
            label: 'College',
            value: profile.college,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.layers_outlined,
            label: 'Semester',
            value: profile.semester,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Quote card ────────────────────────────────────────────────────────────────

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});
  final String quote;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.format_quote_rounded,
            size: 28,
            color: AppColors.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              quote,
              style: AppTextStyles.tagline(context).copyWith(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Edit button ───────────────────────────────────────────────────────────────

class _EditButton extends StatelessWidget {
  const _EditButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_outlined, size: 14, color: AppColors.surface),
            SizedBox(width: 6),
            Text(
              'Edit',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Edit Profile bottom sheet ─────────────────────────────────────────────────

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.profile});
  final ProfileTableData profile;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _roleCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _collegeCtrl;
  late final TextEditingController _semesterCtrl;
  late final TextEditingController _quoteCtrl;

  bool _saving = false;
  String? _photoPath;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p.name);
    _roleCtrl = TextEditingController(text: p.role);
    _emailCtrl = TextEditingController(text: p.email);
    _phoneCtrl = TextEditingController(text: p.phone);
    _collegeCtrl = TextEditingController(text: p.college);
    _semesterCtrl = TextEditingController(text: p.semester);
    _quoteCtrl = TextEditingController(text: p.quote ?? '');
    _photoPath = p.photoPath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roleCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _collegeCtrl.dispose();
    _semesterCtrl.dispose();
    _quoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final quoteText = _quoteCtrl.text.trim();
    await ref
        .read(profileDaoProvider)
        .upsertProfile(
          ProfileTableCompanion(
            id: const Value(1),
            name: Value(_nameCtrl.text.trim()),
            role: Value(_roleCtrl.text.trim()),
            email: Value(_emailCtrl.text.trim()),
            phone: Value(_phoneCtrl.text.trim()),
            college: Value(_collegeCtrl.text.trim()),
            semester: Value(_semesterCtrl.text.trim()),
            quote: Value(quoteText.isEmpty ? null : quoteText),
            // preserve existing photoPath and points
            photoPath: Value(_photoPath),
            points: Value(widget.profile.points),
          ),
        );

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _choosePhoto() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (image == null) return;
    final cropped = await ImageCropper().cropImage(
      sourcePath: image.path,
      compressQuality: 88,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop profile photo',
          toolbarColor: AppColors.surfaceDark,
          toolbarWidgetColor: AppColors.surface,
          activeControlsWidgetColor: AppColors.accent,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop profile photo'),
      ],
    );
    if (cropped != null && mounted) setState(() => _photoPath = cropped.path);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Profile',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.accentSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _choosePhoto,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 42,
                              backgroundColor: AppColors.accentSoft,
                              backgroundImage: _photoPath == null
                                  ? null
                                  : FileImage(File(_photoPath!)),
                              child: _photoPath == null
                                  ? Text(
                                      _nameCtrl.text.isEmpty
                                          ? 'S'
                                          : _nameCtrl.text[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.textPrimary,
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 15,
                                  color: AppColors.surface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Tap to choose your photo',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _FieldLabel('Name'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(hintText: 'Your name'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _FieldLabel('Role / Course'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _roleCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'e.g. CS Engineering Student',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FieldLabel('Email'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'your@email.com',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FieldLabel('Phone'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '+91 XXXXX XXXXX',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FieldLabel('College'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _collegeCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Your college/university',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FieldLabel('Semester'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _semesterCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Semester 5',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FieldLabel('Personal Quote (optional)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _quoteCtrl,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Something that inspires you…',
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save Changes'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: AppColors.textSecondary, fontSize: 12),
    );
  }
}
