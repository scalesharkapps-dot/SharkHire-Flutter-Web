import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../shared/models/domain_enums.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../../../shared/widgets/bottom_action_bar.dart';
import '../../../../shared/widgets/company_logo.dart';
import '../../../../shared/widgets/fade_in_up.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../../shared/widgets/match_score_badge.dart';
import '../../../../shared/widgets/person_avatar.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../providers/employer_providers.dart';
import 'employer_overview_screen.dart' show ApplicantRow;

/// Applicants grouped by status (mockup 4.5 "Applications").
class EmployerApplicantsScreen extends ConsumerStatefulWidget {
  const EmployerApplicantsScreen({super.key});

  @override
  ConsumerState<EmployerApplicantsScreen> createState() =>
      _EmployerApplicantsScreenState();
}

class _EmployerApplicantsScreenState
    extends ConsumerState<EmployerApplicantsScreen> {
  static const _tabs = [
    ApplicationStatus.submitted,
    ApplicationStatus.underReview,
    ApplicationStatus.shortlisted,
    ApplicationStatus.interview,
    ApplicationStatus.rejected,
  ];
  ApplicationStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final all = ref.watch(applicantsProvider);
    final shown =
        (_filter == null ? all : all.where((a) => a.status == _filter).toList())
          ..sort((a, b) => (b.matchScore ?? 0).compareTo(a.matchScore ?? 0));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
            AppSpacing.screenHorizontal,
            AppSpacing.xxxl,
          ),
          children: [
            Text('Applicants', style: text.headlineMedium),
            const SizedBox(height: 2),
            Text(
              'Candidates who applied to your jobs, best matches first.',
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            ChoiceChipGroup<ApplicationStatus?>(
              options: [null, ..._tabs],
              selected: {_filter},
              multiSelect: false,
              labelOf: (s) {
                final n = s == null
                    ? all.length
                    : all.where((a) => a.status == s).length;
                final label = s == null
                    ? 'All'
                    : (s == ApplicationStatus.submitted ? 'New' : s.label);
                return '$label ($n)';
              },
              onChanged: (s) => setState(() => _filter = s.first),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (shown.isEmpty)
              const EmptyStateView(
                compact: true,
                icon: Icons.groups_outlined,
                title: 'No candidates here',
                message:
                    'Candidates move between these lists as you review them.',
              )
            else
              for (var i = 0; i < shown.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: FadeInUp(
                    delay: Duration(milliseconds: 40 * i.clamp(0, 6)),
                    child: ApplicantRow(applicant: shown[i]),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Candidate details with status change (mockup 4.5).
class CandidateDetailsScreen extends ConsumerStatefulWidget {
  const CandidateDetailsScreen({super.key, required this.applicantId});

  final String applicantId;

  @override
  ConsumerState<CandidateDetailsScreen> createState() =>
      _CandidateDetailsScreenState();
}

class _CandidateDetailsScreenState
    extends ConsumerState<CandidateDetailsScreen> {
  static const _choices = [
    ApplicationStatus.underReview,
    ApplicationStatus.shortlisted,
    ApplicationStatus.interview,
    ApplicationStatus.rejected,
    ApplicationStatus.accepted,
  ];
  ApplicationStatus? _selected;
  final _note = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    final s = _selected;
    if (s == null) return;
    setState(() => _saving = true);
    await ref
        .read(applicantsProvider.notifier)
        .setStatus(widget.applicantId, s, note: _note.text);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _selected = null;
    });
    _note.clear();
    AppFeedback.show(
      context,
      'Status updated. The candidate has been notified.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final a = ref.watch(
      applicantsProvider.select(
        (l) => l.where((x) => x.id == widget.applicantId).firstOrNull,
      ),
    );
    if (a == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyStateView(
          icon: Icons.person_off_outlined,
          title: 'Candidate not found',
          message: 'This application may have been withdrawn.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Candidate')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.sm,
              AppSpacing.screenHorizontal,
              AppSpacing.xxl,
            ),
            children: [
              Center(child: PersonAvatar(initials: a.initials, size: 72)),
              const SizedBox(height: AppSpacing.md),
              Text(
                a.name,
                textAlign: TextAlign.center,
                style: text.headlineSmall,
              ),
              if (a.headline != null)
                Text(
                  a.headline!,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium,
                ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Applied for ${a.jobTitle}',
                textAlign: TextAlign.center,
                style: text.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Center(child: StatusChip.application(a.status)),
              const SizedBox(height: AppSpacing.xl),
              if (a.matchScore != null)
                AppSurface(
                  elevated: false,
                  child: Row(
                    children: [
                      MatchScoreRing(score: a.matchScore!, size: 52),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          '${MatchTier.of(a.matchScore!).label} for this job, based on skills, experience and location.',
                          style: text.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              _Heading('Skills'),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final s in a.skills)
                    InfoPill(
                      label: s,
                      background: AppColors.oceanTint,
                      foreground: AppColors.oceanDeep,
                    ),
                ],
              ),
              if (a.experienceSummary != null || a.education != null) ...[
                _Heading('Experience and education'),
                AppSurface(
                  elevated: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (a.experienceSummary != null)
                        Text(a.experienceSummary!, style: text.bodyMedium),
                      if (a.experienceSummary != null && a.education != null)
                        const Divider(height: AppSpacing.xl),
                      if (a.education != null)
                        Text(a.education!, style: text.bodyMedium),
                    ],
                  ),
                ),
              ],
              _Heading('CV'),
              AppSurface(
                elevated: false,
                onTap: () => AppFeedback.show(
                  context,
                  'Opening CV through a secure link that expires shortly',
                ),
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_outlined, color: AppColors.ocean),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.cvFileName ?? 'CV', style: text.titleSmall),
                          Text(
                            'Secure link · shared because they applied',
                            style: text.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
              if (a.coverLetter != null) ...[
                _Heading('Cover letter'),
                Text(a.coverLetter!, style: text.bodyLarge),
              ],
              if (a.notes.isNotEmpty) ...[
                _Heading('Your notes'),
                for (final n in a.notes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: InlineBanner(message: n),
                  ),
              ],
              _Heading('Change status'),
              ChoiceChipGroup<ApplicationStatus>(
                options: _choices,
                selected: {?_selected},
                multiSelect: false,
                labelOf: (s) => s.label,
                onChanged: (s) => setState(() => _selected = s.first),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Note',
                optional: true,
                controller: _note,
                hint: 'Private note, e.g. interview time',
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        maxWidth: 640,
        child: LoadingButton(
          label: _selected == null
              ? 'Choose a new status'
              : 'Update status to ${_selected!.label}',
          loading: _saving,
          onPressed: _selected == null || _selected == a.status
              ? null
              : _update,
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.md),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}
