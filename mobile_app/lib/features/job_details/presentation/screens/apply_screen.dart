import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../../../shared/widgets/bottom_action_bar.dart';
import '../../../../shared/widgets/company_logo.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../applications/presentation/providers/applications_provider.dart';
import '../../../resume/data/models/resume_models.dart';
import '../../../resume/presentation/providers/cv_provider.dart';
import '../../data/models/job_details.dart';
import '../../data/repositories/job_details_repository.dart';

/// Internal apply form (guide §3.5 internal flow, mockup 4.3):
/// choose CV, optional cover letter, submit.
class ApplyScreen extends ConsumerWidget {
  const ApplyScreen({super.key, required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(jobDetailsProvider(jobId));
    return details.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorStateView(
          onRetry: () => ref.invalidate(jobDetailsProvider(jobId)),
        ),
      ),
      data: (d) => d.isInternal
          ? _ApplyForm(details: d)
          : Scaffold(
              appBar: AppBar(),
              body: const EmptyStateView(
                icon: Icons.open_in_new_rounded,
                title: 'Apply on the employer\'s site',
                message:
                    'This job is listed by another site, so you apply there.',
              ),
            ),
    );
  }
}

class _ApplyForm extends ConsumerStatefulWidget {
  const _ApplyForm({required this.details});

  final JobDetails details;

  @override
  ConsumerState<_ApplyForm> createState() => _ApplyFormState();
}

class _ApplyFormState extends ConsumerState<_ApplyForm> {
  final _cover = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _cover.dispose();
    super.dispose();
  }

  Future<void> _submit(Resume cv) async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final app = await ref
          .read(applicationsProvider.notifier)
          .apply(
            widget.details.summary,
            cvFileName: cv.fileName,
            coverLetter: _cover.text,
          );
      if (!mounted) return;
      context.pushReplacement(AppRoutes.applicationSent(app.id));
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Your application wasn\'t sent. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final s = widget.details.summary;
    final cv = ref.watch(cvProvider).active;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Apply to ${s.companyName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.sm,
              AppSpacing.screenHorizontal,
              AppSpacing.xxl,
            ),
            children: [
              AppSurface(
                elevated: false,
                child: Row(
                  children: [
                    CompanyLogo(name: s.companyName),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.title, style: text.titleSmall),
                          Text(
                            '${s.companyName} · ${s.location}',
                            style: text.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_error != null) ...[
                InlineBanner(message: _error!, tone: BannerTone.error),
                const SizedBox(height: AppSpacing.lg),
              ],
              const FieldLabel('CV'),
              if (cv == null)
                AppSurface(
                  elevated: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Upload a CV to apply', style: text.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Employers review your CV with your application.',
                        style: text.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: () => context.push(AppRoutes.cvUpload),
                        icon: const Icon(Icons.upload_rounded, size: 20),
                        label: const Text('Upload CV'),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.oceanTint,
                    borderRadius: AppRadius.lgAll,
                    border: Border.all(color: AppColors.ocean, width: 1.4),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.description_rounded,
                        color: AppColors.ocean,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cv.fileName,
                              style: text.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Active CV · uploaded ${DateFormatters.relativeAge(cv.uploadedAt).toLowerCase()}',
                              style: text.bodySmall?.copyWith(
                                color: AppColors.oceanDeep,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.ocean,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                label: 'Cover letter',
                optional: true,
                controller: _cover,
                hint: 'Write a short note to the employer…',
                maxLines: 8,
                minLines: 6,
                maxLength: 2000,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.md),
              const InlineBanner(
                tone: BannerTone.info,
                message:
                    'Your CV is shared with this employer only when you submit.',
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: LoadingButton(
          label: 'Submit application',
          loading: _submitting,
          onPressed: cv == null ? null : () => _submit(cv),
        ),
      ),
    );
  }
}

/// Confirmation after an internal application is submitted.
class ApplicationSentScreen extends ConsumerStatefulWidget {
  const ApplicationSentScreen({super.key, required this.applicationId});

  final String applicationId;

  @override
  ConsumerState<ApplicationSentScreen> createState() =>
      _ApplicationSentScreenState();
}

class _ApplicationSentScreenState extends ConsumerState<ApplicationSentScreen> {
  bool _notifySimilar = true;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final app = ref
        .watch(applicationsProvider.notifier)
        .byId(widget.applicationId);
    final job = app?.job;

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            children: [
              const SizedBox(height: AppSpacing.xxl),
              const Center(
                child: StateIllustration(
                  icon: Icons.check_rounded,
                  tone: AppColors.success,
                  tint: AppColors.successTint,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Application sent',
                style: text.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                job == null
                    ? 'The employer will review it soon.'
                    : '${job.companyName} will review your application for ${job.title}. '
                          'We\'ll let you know when the status changes.',
                style: text.bodyLarge?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              CheckboxListTile(
                value: _notifySimilar,
                onChanged: (v) => setState(() => _notifySimilar = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.navy,
                title: Text(
                  job == null
                      ? 'Notify me about similar jobs'
                      : 'Notify me about similar ${job.title} jobs',
                  style: text.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        maxWidth: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  context.go(AppRoutes.home);
                  context.push(AppRoutes.applications);
                },
                child: const Text('Track application'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => context.go(AppRoutes.explore),
                child: const Text('Keep exploring jobs'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
