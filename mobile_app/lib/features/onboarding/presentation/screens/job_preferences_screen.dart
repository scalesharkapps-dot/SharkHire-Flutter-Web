import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../shared/models/domain_enums.dart';
import '../../../../shared/widgets/bottom_action_bar.dart';
import '../../../../shared/widgets/fade_in_up.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../../../profile/data/models/job_preferences.dart';
import '../../../profile/presentation/providers/current_user_provider.dart';
import '../../../profile/data/repositories/profile_repository.dart';

/// Job preferences (guide §3.5, mockup 4.1). Used once during onboarding
/// and later from Profile to edit preferences.
class JobPreferencesScreen extends ConsumerStatefulWidget {
  const JobPreferencesScreen({super.key, this.isOnboarding = true});

  final bool isOnboarding;

  @override
  ConsumerState<JobPreferencesScreen> createState() =>
      _JobPreferencesScreenState();
}

enum _Region { pakistan, international }

class _JobPreferencesScreenState extends ConsumerState<JobPreferencesScreen> {
  late JobPreferences _prefs = ref.read(jobPreferencesProvider);
  bool _saving = false;

  Set<_Region> get _regions => {
    if (_prefs.includePakistan) _Region.pakistan,
    if (_prefs.includeInternational) _Region.international,
  };

  Future<void> _save() async {
    if (!_prefs.isValid) {
      AppFeedback.show(
        context,
        'Choose at least one location and one job category.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).savePreferences(_prefs);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppFeedback.show(context, friendlyErrorMessage(e));
      return;
    }
    ref.read(jobPreferencesProvider.notifier).save(_prefs);
    if (!mounted) return;
    setState(() => _saving = false);
    if (widget.isOnboarding) {
      ref.read(sessionProvider.notifier).completeOnboarding();
      context.go(AppRoutes.cvUploadOnboarding);
    } else {
      AppFeedback.show(context, 'Preferences saved. Your matches will update.');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final firstName = ref.watch(currentUserProvider).firstName;

    Widget section(String title, String hint, Widget child, int i) => FadeInUp(
      delay: Duration(milliseconds: 50 * i),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: text.titleMedium),
            const SizedBox(height: 2),
            Text(hint, style: text.bodySmall),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: !widget.isOnboarding),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                0,
                AppSpacing.screenHorizontal,
                AppSpacing.xxl,
              ),
              children: [
                if (!widget.isOnboarding) ...[
                  Semantics(
                    header: true,
                    child: Text('Job preferences', style: text.headlineLarge),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (widget.isOnboarding) ...[
                  Text(
                    'STEP 1 OF 2',
                    style: text.labelSmall?.copyWith(
                      color: AppColors.ocean,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'What are you looking for, $firstName?',
                    style: text.headlineLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'We use this with your CV to find and rank jobs. You can change it any time.',
                    style: text.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
                section(
                  'Preferred job location',
                  'Pick one or both.',
                  ChoiceChipGroup<_Region>(
                    options: _Region.values,
                    selected: _regions,
                    labelOf: (r) =>
                        r == _Region.pakistan ? 'Pakistan' : 'International',
                    onChanged: (s) => setState(
                      () => _prefs = _prefs.copyWith(
                        includePakistan: s.contains(_Region.pakistan),
                        includeInternational: s.contains(_Region.international),
                      ),
                    ),
                  ),
                  0,
                ),
                section(
                  'Job categories',
                  'Choose the fields you want to work in.',
                  ChoiceChipGroup<String>(
                    options: JobPreferences.allCategories,
                    selected: _prefs.categories,
                    labelOf: (c) => c,
                    onChanged: (s) =>
                        setState(() => _prefs = _prefs.copyWith(categories: s)),
                  ),
                  1,
                ),
                section(
                  'Employment type',
                  'Leave empty to see every type.',
                  ChoiceChipGroup<EmploymentType>(
                    options: EmploymentType.values,
                    selected: _prefs.employmentTypes,
                    labelOf: (e) => e.label,
                    onChanged: (s) => setState(
                      () => _prefs = _prefs.copyWith(employmentTypes: s),
                    ),
                  ),
                  2,
                ),
                section(
                  'Work mode',
                  'Remote, hybrid or on-site.',
                  ChoiceChipGroup<WorkMode>(
                    options: WorkMode.values,
                    selected: _prefs.workModes,
                    labelOf: (w) => w.label,
                    onChanged: (s) =>
                        setState(() => _prefs = _prefs.copyWith(workModes: s)),
                  ),
                  3,
                ),
                section(
                  'Experience level',
                  'Choose the one that fits you best.',
                  ChoiceChipGroup<ExperienceLevel>(
                    options: const [
                      ExperienceLevel.internship,
                      ExperienceLevel.entry,
                      ExperienceLevel.junior,
                      ExperienceLevel.mid,
                      ExperienceLevel.senior,
                      ExperienceLevel.lead,
                      ExperienceLevel.executive,
                      ExperienceLevel.any,
                    ],
                    selected: {_prefs.experienceLevel},
                    multiSelect: false,
                    labelOf: (e) => e.label,
                    onChanged: (s) => setState(
                      () => _prefs = _prefs.copyWith(experienceLevel: s.first),
                    ),
                  ),
                  4,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: LoadingButton(
          label: widget.isOnboarding ? 'Continue' : 'Save preferences',
          loading: _saving,
          onPressed: _save,
        ),
      ),
    );
  }
}
