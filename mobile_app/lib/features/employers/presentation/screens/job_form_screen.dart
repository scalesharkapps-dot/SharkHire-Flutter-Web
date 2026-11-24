import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/domain_enums.dart';
import '../../../../shared/widgets/bottom_action_bar.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../data/models/employer_models.dart';
import '../providers/employer_providers.dart';

/// Create or edit a job (guide §3.6 job posting form, mockup 4.5).
/// Saving submits it for admin approval, so it becomes Pending.
class JobFormScreen extends ConsumerStatefulWidget {
  const JobFormScreen({super.key, this.jobId});

  final String? jobId;

  @override
  ConsumerState<JobFormScreen> createState() => _JobFormScreenState();
}

class _JobFormScreenState extends ConsumerState<JobFormScreen> {
  final _form = GlobalKey<FormState>();
  late final EmployerJob? _existing = widget.jobId == null
      ? null
      : ref.read(employerJobsProvider.notifier).byId(widget.jobId!);

  late final _title = TextEditingController(text: _existing?.title);
  late final _location = TextEditingController(text: _existing?.location);
  late final _education = TextEditingController(text: _existing?.education);
  late final _salaryMin = TextEditingController(
    text: _existing?.salaryMin?.toString(),
  );
  late final _salaryMax = TextEditingController(
    text: _existing?.salaryMax?.toString(),
  );
  late final _vacancies = TextEditingController(
    text: '${_existing?.vacancies ?? 1}',
  );
  late final _description = TextEditingController(text: _existing?.description);
  late final _instructions = TextEditingController(
    text: _existing?.instructions,
  );
  final _skill = TextEditingController();

  late List<String> _skills = [...?_existing?.requiredSkills];
  late WorkMode _workMode = _existing?.workMode ?? WorkMode.onsite;
  late EmploymentType _type =
      _existing?.employmentType ?? EmploymentType.fullTime;
  late ExperienceLevel _experience =
      _existing?.experienceLevel ?? ExperienceLevel.any;
  late String _currency = _existing?.salaryCurrency ?? 'PKR';
  late DateTime? _deadline = _existing?.deadline;
  bool _saving = false;
  String? _skillsError;

  @override
  void dispose() {
    for (final c in [
      _title,
      _location,
      _education,
      _salaryMin,
      _salaryMax,
      _vacancies,
      _description,
      _instructions,
      _skill,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _addSkill() {
    final v = _skill.text.trim();
    if (v.isEmpty) return;
    if (!_skills.any((s) => s.toLowerCase() == v.toLowerCase())) {
      setState(() {
        _skills = [..._skills, v];
        _skillsError = null;
      });
    }
    _skill.clear();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  String? _salaryRangeError() {
    final min = int.tryParse(_salaryMin.text);
    final max = int.tryParse(_salaryMax.text);
    if (min != null && max != null && min > max) {
      return 'Minimum can\'t be more than maximum';
    }
    return null;
  }

  Future<void> _submit() async {
    final formOk = _form.currentState?.validate() ?? false;
    setState(
      () => _skillsError = _skills.isEmpty
          ? 'Add at least one required skill'
          : null,
    );
    if (!formOk || _skills.isEmpty) {
      AppFeedback.show(context, 'Check the highlighted fields');
      return;
    }
    setState(() => _saving = true);
    await ref
        .read(employerJobsProvider.notifier)
        .save(
          EmployerJob(
            id: _existing?.id ?? 'ej-${DateTime.now().millisecondsSinceEpoch}',
            title: _title.text.trim(),
            location: _location.text.trim(),
            workMode: _workMode,
            employmentType: _type,
            status: JobStatus.pending,
            createdAt: _existing?.createdAt ?? DateTime.now(),
            description: _description.text.trim(),
            requiredSkills: _skills,
            experienceLevel: _experience,
            education: _education.text.trim().isEmpty
                ? null
                : _education.text.trim(),
            salaryMin: int.tryParse(_salaryMin.text),
            salaryMax: int.tryParse(_salaryMax.text),
            salaryCurrency: _currency,
            deadline: _deadline,
            vacancies: int.tryParse(_vacancies.text) ?? 1,
            instructions: _instructions.text.trim().isEmpty
                ? null
                : _instructions.text.trim(),
            views: _existing?.views ?? 0,
          ),
        );
    if (!mounted) return;
    AppFeedback.show(
      context,
      'Submitted for approval. We\'ll notify you when it\'s live.',
    );
    context.go(AppRoutes.employerJobs);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    if (widget.jobId != null && _existing == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyStateView(
          icon: Icons.work_off_outlined,
          title: 'Job not found',
          message: 'It may have been deleted.',
        ),
      );
    }

    Widget gap([double h = AppSpacing.lg]) => SizedBox(height: h);
    final digits = [FilteringTextInputFormatter.digitsOnly];

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.sm,
                AppSpacing.screenHorizontal,
                AppSpacing.xxl,
              ),
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    _existing == null ? 'Create job' : 'Edit job',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (_existing?.status == JobStatus.rejected &&
                    _existing?.rejectionReason != null) ...[
                  InlineBanner(
                    tone: BannerTone.error,
                    title: 'Changes requested by SharkHire',
                    message: _existing!.rejectionReason!,
                  ),
                  gap(),
                ],
                AppTextField(
                  label: 'Job title',
                  sentenceCaseLabel: true,
                  controller: _title,
                  hint: 'Backend Developer',
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => Validators.required(v, field: 'Job title'),
                ),
                gap(),
                const FieldLabel('Required skills', sentenceCase: true),
                if (_skills.isNotEmpty) ...[
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final s in _skills)
                        InputChip(
                          label: Text(s),
                          backgroundColor: AppColors.oceanTint,
                          side: BorderSide.none,
                          labelStyle: text.labelMedium?.copyWith(
                            color: AppColors.oceanDeep,
                          ),
                          deleteIconColor: AppColors.oceanDeep,
                          deleteButtonTooltipMessage: 'Remove $s',
                          onDeleted: () =>
                              setState(() => _skills = [..._skills]..remove(s)),
                        ),
                    ],
                  ),
                  gap(AppSpacing.sm),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _skill,
                        onSubmitted: (_) => _addSkill(),
                        decoration: InputDecoration(
                          hintText: 'Add a skill',
                          errorText: _skillsError,
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
                gap(AppSpacing.xl),
                const FieldLabel('Experience', sentenceCase: true),
                ChoiceChipGroup<ExperienceLevel>(
                  options: ExperienceLevel.values,
                  selected: {_experience},
                  multiSelect: false,
                  labelOf: (e) => e.label,
                  onChanged: (s) => setState(() => _experience = s.first),
                ),
                gap(AppSpacing.xl),
                AppTextField(
                  label: 'Education',
                  sentenceCaseLabel: true,
                  optional: true,
                  controller: _education,
                  hint: 'Bachelor\'s in Computer Science',
                  textCapitalization: TextCapitalization.sentences,
                ),
                gap(),
                AppTextField(
                  label: 'Location',
                  sentenceCaseLabel: true,
                  controller: _location,
                  hint: 'City, Country',
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => Validators.required(v, field: 'Location'),
                ),
                gap(AppSpacing.xl),
                const FieldLabel('Work mode', sentenceCase: true),
                ChoiceChipGroup<WorkMode>(
                  options: WorkMode.values,
                  selected: {_workMode},
                  multiSelect: false,
                  labelOf: (w) => w.label,
                  onChanged: (s) => setState(() => _workMode = s.first),
                ),
                gap(AppSpacing.xl),
                const FieldLabel('Employment type', sentenceCase: true),
                ChoiceChipGroup<EmploymentType>(
                  options: EmploymentType.values,
                  selected: {_type},
                  multiSelect: false,
                  labelOf: (e) => e.label,
                  onChanged: (s) => setState(() => _type = s.first),
                ),
                gap(AppSpacing.xl),
                const FieldLabel(
                  'Salary range per month',
                  optional: true,
                  sentenceCase: true,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _currency,
                        items: const [
                          DropdownMenuItem(value: 'PKR', child: Text('PKR')),
                          DropdownMenuItem(value: 'USD', child: Text('USD')),
                        ],
                        onChanged: (v) =>
                            setState(() => _currency = v ?? 'PKR'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _salaryMin,
                        keyboardType: TextInputType.number,
                        inputFormatters: digits,
                        decoration: const InputDecoration(hintText: 'Min'),
                        validator: (_) => _salaryRangeError(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _salaryMax,
                        keyboardType: TextInputType.number,
                        inputFormatters: digits,
                        decoration: const InputDecoration(hintText: 'Max'),
                      ),
                    ),
                  ],
                ),
                gap(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FieldLabel(
                            'Deadline',
                            optional: true,
                            sentenceCase: true,
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              alignment: Alignment.centerLeft,
                            ),
                            onPressed: _pickDeadline,
                            icon: const Icon(Icons.event_outlined, size: 20),
                            label: Text(
                              _deadline == null
                                  ? 'Choose date'
                                  : '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(
                      width: 120,
                      child: AppTextField(
                        label: 'Vacancies',
                        sentenceCaseLabel: true,
                        controller: _vacancies,
                        keyboardType: TextInputType.number,
                        inputFormatters: digits,
                        validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1
                            ? 'At least 1'
                            : null,
                      ),
                    ),
                  ],
                ),
                gap(),
                AppTextField(
                  label: 'Job description',
                  sentenceCaseLabel: true,
                  controller: _description,
                  hint: 'What the role involves and who you\'re looking for',
                  maxLines: 8,
                  minLines: 5,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => (v == null || v.trim().length < 30)
                      ? 'Describe the role in at least 30 characters'
                      : null,
                ),
                gap(),
                AppTextField(
                  label: 'Application instructions',
                  sentenceCaseLabel: true,
                  optional: true,
                  controller: _instructions,
                  hint: 'Attach your CV and a short cover letter',
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                gap(AppSpacing.xl),
                const InlineBanner(
                  tone: BannerTone.warning,
                  message:
                      'Your job will be Pending until a SharkHire admin approves it. '
                      'Published jobs that you edit are reviewed again.',
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        maxWidth: 640,
        child: LoadingButton(
          label: 'Submit for approval',
          loading: _saving,
          onPressed: _submit,
        ),
      ),
    );
  }
}
