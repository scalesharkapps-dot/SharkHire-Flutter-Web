import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../../../shared/widgets/bottom_action_bar.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../data/models/resume_models.dart';
import '../providers/cv_provider.dart';

/// Review and correct the profile extracted from the CV before it is used
/// for matching (guide §3.5, mockup 4.2).
class CvReviewScreen extends ConsumerStatefulWidget {
  const CvReviewScreen({super.key});

  @override
  ConsumerState<CvReviewScreen> createState() => _CvReviewScreenState();
}

class _CvReviewScreenState extends ConsumerState<CvReviewScreen> {
  ParsedProfile? _draft;
  Object? _loadError;
  bool _saving = false;
  final _skill = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _skill.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final p = await ref.read(cvProvider.notifier).loadProfile();
      if (mounted) setState(() => _draft = p);
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  void _addSkill() {
    final v = _skill.text.trim();
    final d = _draft;
    if (v.isEmpty || d == null) return;
    if (d.skills.any((s) => s.toLowerCase() == v.toLowerCase())) {
      AppFeedback.show(context, '$v is already in your skills');
    } else {
      setState(() => _draft = d.copyWith(skills: [...d.skills, v]));
    }
    _skill.clear();
  }

  Future<void> _confirm() async {
    final d = _draft;
    if (d == null) return;
    if (d.skills.isEmpty) {
      AppFeedback.show(
        context,
        'Add at least one skill so we can match jobs to you.',
      );
      return;
    }
    setState(() => _saving = true);
    await ref.read(cvProvider.notifier).saveProfile(d);
    if (!mounted) return;
    setState(() => _saving = false);
    AppFeedback.show(context, 'Profile saved. Your matches are updated.');
    context.go(AppRoutes.home);
  }

  Future<void> _editExperience([int? index]) async {
    final d = _draft!;
    final current = index == null ? null : d.experience[index];
    final result = await showModalBottomSheet<_EditResult<ExperienceEntry>>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => _EntrySheet(
        title: index == null ? 'Add experience' : 'Edit experience',
        labels: const ['Job title', 'Company', 'Period'],
        values: [current?.jobTitle, current?.organization, current?.period],
        canDelete: index != null,
        build: (v) =>
            ExperienceEntry(jobTitle: v[0]!, organization: v[1], period: v[2]),
      ),
    );
    if (result == null) return;
    final list = [...d.experience];
    if (result.deleted) {
      list.removeAt(index!);
    } else if (index == null) {
      list.add(result.value!);
    } else {
      list[index] = result.value!;
    }
    setState(() => _draft = d.copyWith(experience: list));
  }

  Future<void> _editEducation([int? index]) async {
    final d = _draft!;
    final current = index == null ? null : d.education[index];
    final result = await showModalBottomSheet<_EditResult<EducationEntry>>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => _EntrySheet(
        title: index == null ? 'Add education' : 'Edit education',
        labels: const ['Qualification', 'Institution', 'Period'],
        values: [current?.qualification, current?.institution, current?.period],
        canDelete: index != null,
        build: (v) => EducationEntry(
          qualification: v[0]!,
          institution: v[1],
          period: v[2],
        ),
      ),
    );
    if (result == null) return;
    final list = [...d.education];
    if (result.deleted) {
      list.removeAt(index!);
    } else if (index == null) {
      list.add(result.value!);
    } else {
      list[index] = result.value!;
    }
    setState(() => _draft = d.copyWith(education: list));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final d = _draft;

    Widget body;
    if (_loadError != null) {
      body = ErrorStateView(onRetry: _load);
    } else if (d == null) {
      body = ListView(
        padding: AppSpacing.screenPadding,
        children: const [
          Shimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 180, height: 18),
                SizedBox(height: AppSpacing.lg),
                Skeleton(height: 90, radius: 16),
                SizedBox(height: AppSpacing.lg),
                Skeleton(height: 120, radius: 16),
                SizedBox(height: AppSpacing.lg),
                Skeleton(height: 90, radius: 16),
              ],
            ),
          ),
        ],
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          0,
          AppSpacing.screenHorizontal,
          AppSpacing.xxl,
        ),
        children: [
          Text(
            'Check what we found in your CV. Tap any item to correct it.',
            style: text.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          const InlineBanner(
            tone: BannerTone.warning,
            title: 'Automatic reading can miss details',
            message:
                'Please correct anything that\'s wrong before we use it to match jobs.',
          ),
          const SizedBox(height: AppSpacing.xl),

          // Basics
          AppSurface(
            child: Row(
              children: [
                Expanded(
                  child: _Fact(label: 'Name', value: d.fullName),
                ),
                Expanded(
                  child: _Fact(
                    label: 'Location',
                    value: d.location ?? 'Not found',
                  ),
                ),
                Expanded(
                  child: _Fact(
                    label: 'Experience',
                    value: d.yearsOfExperience == null
                        ? 'Not stated'
                        : '${d.yearsOfExperience!.toStringAsFixed(0)} yrs',
                  ),
                ),
              ],
            ),
          ),

          _Section(
            title: 'Skills',
            subtitle: '${d.skills.length} found · tap × to remove',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final s in d.skills)
                      InputChip(
                        label: Text(s),
                        labelStyle: text.labelMedium?.copyWith(
                          color: AppColors.oceanDeep,
                        ),
                        backgroundColor: AppColors.oceanTint,
                        side: BorderSide.none,
                        deleteIconColor: AppColors.oceanDeep,
                        deleteButtonTooltipMessage: 'Remove $s',
                        onDeleted: () => setState(
                          () => _draft = d.copyWith(
                            skills: [...d.skills]..remove(s),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _skill,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addSkill(),
                        decoration: const InputDecoration(
                          hintText: 'Add a skill, e.g. Riverpod',
                          prefixIcon: Icon(Icons.add_rounded, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: _addSkill,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                      ),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          _Section(
            title: 'Experience',
            action: TextButton.icon(
              onPressed: () => _editExperience(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
            ),
            child: d.experience.isEmpty
                ? const _EmptyLine(
                    'No experience found. Add your roles so matching is accurate.',
                  )
                : Column(
                    children: [
                      for (var i = 0; i < d.experience.length; i++)
                        _EntryCard(
                          title: d.experience[i].jobTitle,
                          subtitle: [
                            d.experience[i].organization,
                            d.experience[i].period,
                          ].whereType<String>().join('  ·  '),
                          onTap: () => _editExperience(i),
                        ),
                    ],
                  ),
          ),

          _Section(
            title: 'Education',
            action: TextButton.icon(
              onPressed: () => _editEducation(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
            ),
            child: d.education.isEmpty
                ? const _EmptyLine('No education found.')
                : Column(
                    children: [
                      for (var i = 0; i < d.education.length; i++)
                        _EntryCard(
                          title: d.education[i].qualification,
                          subtitle: [
                            d.education[i].institution,
                            d.education[i].period,
                          ].whereType<String>().join('  ·  '),
                          onTap: () => _editEducation(i),
                        ),
                    ],
                  ),
          ),

          _Section(
            title: 'Certifications and projects',
            child: (d.certifications.isEmpty && d.projects.isEmpty)
                ? const _EmptyLine('None found.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final c in d.certifications)
                        _Bullet(
                          icon: Icons.workspace_premium_outlined,
                          text: c,
                        ),
                      for (final p in d.projects)
                        _Bullet(icon: Icons.folder_open_outlined, text: p),
                    ],
                  ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Review your profile')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: body,
          ),
        ),
      ),
      bottomNavigationBar: d == null
          ? null
          : BottomActionBar(
              child: LoadingButton(
                label: 'Confirm and find jobs',
                icon: Icons.check_rounded,
                loading: _saving,
                onPressed: _confirm,
              ),
            ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.titleMedium),
                    if (subtitle != null)
                      Text(subtitle!, style: text.bodySmall),
                  ],
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: text.labelSmall?.copyWith(
            color: AppColors.textTertiary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: text.titleSmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppSurface(
        onTap: onTap,
        elevated: false,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleSmall),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: text.bodySmall),
                ],
              ),
            ),
            Icon(Icons.edit_outlined, size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.ocean),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    ),
  );
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.bodySmall);
}

class _EditResult<T> {
  const _EditResult.saved(T this.value) : deleted = false;
  const _EditResult.deleted() : value = null, deleted = true;

  final T? value;
  final bool deleted;
}

/// Bottom sheet with three text fields (title required) for an entry.
class _EntrySheet<T> extends StatefulWidget {
  const _EntrySheet({
    required this.title,
    required this.labels,
    required this.values,
    required this.build,
    required this.canDelete,
  });

  final String title;
  final List<String> labels;
  final List<String?> values;
  final T Function(List<String?> values) build;
  final bool canDelete;

  @override
  State<_EntrySheet<T>> createState() => _EntrySheetState<T>();
}

class _EntrySheetState<T> extends State<_EntrySheet<T>> {
  final _form = GlobalKey<FormState>();
  late final _controllers = [
    for (final v in widget.values) TextEditingController(text: v ?? ''),
  ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!(_form.currentState?.validate() ?? false)) return;
    final values = [
      for (final c in _controllers)
        c.text.trim().isEmpty ? null : c.text.trim(),
    ];
    Navigator.of(context).pop(_EditResult<T>.saved(widget.build(values)));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            0,
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
          ),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.title, style: text.headlineSmall),
                const SizedBox(height: AppSpacing.lg),
                for (var i = 0; i < widget.labels.length; i++) ...[
                  AppTextField(
                    label: widget.labels[i],
                    controller: _controllers[i],
                    optional: i > 0,
                    textCapitalization: TextCapitalization.sentences,
                    validator: i == 0
                        ? (v) => (v == null || v.trim().isEmpty)
                              ? '${widget.labels[0]} is required'
                              : null
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                const SizedBox(height: AppSpacing.sm),
                FilledButton(onPressed: _save, child: const Text('Save')),
                if (widget.canDelete) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    onPressed: () =>
                        Navigator.of(context).pop(_EditResult<T>.deleted()),
                    child: const Text('Delete'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
