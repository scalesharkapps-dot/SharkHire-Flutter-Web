import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/company_logo.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../../shared/widgets/menu_group.dart';
import '../../../../shared/widgets/appearance_picker.dart';
import '../../../authentication/presentation/widgets/sign_out_sheet.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/employer_models.dart';
import '../providers/employer_providers.dart';

/// Company profile and employer account (guide §3.6).
class EmployerCompanyScreen extends ConsumerStatefulWidget {
  const EmployerCompanyScreen({super.key});

  @override
  ConsumerState<EmployerCompanyScreen> createState() =>
      _EmployerCompanyScreenState();
}

class _EmployerCompanyScreenState extends ConsumerState<EmployerCompanyScreen> {
  final _form = GlobalKey<FormState>();
  late final Company _c = ref.read(companyProvider);
  late final _name = TextEditingController(text: _c.name);
  late final _website = TextEditingController(text: _c.website);
  late final _industry = TextEditingController(text: _c.industry);
  late final _size = TextEditingController(text: _c.companySize);
  late final _hq = TextEditingController(text: _c.headquarters);
  late final _about = TextEditingController(text: _c.description);
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _website, _industry, _size, _hq, _about]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    await ref
        .read(companyProvider.notifier)
        .save(
          ref
              .read(companyProvider)
              .copyWith(
                name: _name.text.trim(),
                website: _website.text.trim(),
                industry: _industry.text.trim(),
                companySize: _size.text.trim(),
                headquarters: _hq.text.trim(),
                description: _about.text.trim(),
              ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    AppFeedback.show(context, 'Company profile saved');
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final company = ref.watch(companyProvider);
    final settings = ref.watch(settingsProvider);
    final setSettings = ref.read(settingsProvider.notifier).update;
    Widget gap() => const SizedBox(height: AppSpacing.lg);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.lg,
                  AppSpacing.screenHorizontal,
                  AppSpacing.xxxl,
                ),
                children: [
                  Text('Company', style: text.headlineLarge),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      CompanyLogo(name: company.name, size: 64),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(company.name, style: text.titleLarge),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                foregroundColor: AppColors.textSecondary,
                              ),
                              onPressed: () => AppFeedback.show(
                                context,
                                'Logo upload is available once storage is connected.',
                              ),
                              icon: const Icon(Icons.image_outlined, size: 18),
                              label: const Text('Change logo'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  gap(),
                  InlineBanner(
                    tone: switch (company.verification) {
                      VerificationStatus.verified => BannerTone.success,
                      VerificationStatus.pending => BannerTone.warning,
                      VerificationStatus.rejected => BannerTone.error,
                    },
                    title: switch (company.verification) {
                      VerificationStatus.verified => 'Verified employer',
                      VerificationStatus.pending => 'Verification in progress',
                      VerificationStatus.rejected =>
                        'Verification needs attention',
                    },
                    message: switch (company.verification) {
                      VerificationStatus.verified =>
                        'Candidates see a verified badge on your jobs.',
                      VerificationStatus.pending =>
                        'SharkHire is checking your company details. This usually takes one working day.',
                      VerificationStatus.rejected =>
                        'Update your company details and we\'ll check them again.',
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppTextField(
                    label: 'Company name',
                    sentenceCaseLabel: true,
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        Validators.required(v, field: 'Company name'),
                  ),
                  gap(),
                  AppTextField(
                    label: 'Website',
                    sentenceCaseLabel: true,
                    controller: _website,
                    optional: true,
                    keyboardType: TextInputType.url,
                    hint: 'https://',
                  ),
                  gap(),
                  AppTextField(
                    label: 'Industry',
                    sentenceCaseLabel: true,
                    controller: _industry,
                    optional: true,
                  ),
                  gap(),
                  AppTextField(
                    label: 'Size',
                    sentenceCaseLabel: true,
                    controller: _size,
                    optional: true,
                  ),
                  gap(),
                  AppTextField(
                    label: 'Headquarters',
                    sentenceCaseLabel: true,
                    controller: _hq,
                    optional: true,
                  ),
                  gap(),
                  AppTextField(
                    label: 'About the company',
                    sentenceCaseLabel: true,
                    controller: _about,
                    maxLines: 6,
                    minLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                  ),
                  gap(),
                  LoadingButton(
                    label: 'Save company profile',
                    loading: _saving,
                    onPressed: _save,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  MenuGroup(
                    title: 'Alerts',
                    normalCaseTitle: true,
                    items: [
                      MenuItem(
                        Icons.person_add_alt_outlined,
                        'New applications',
                        switchValue: settings.applicationUpdates,
                        onSwitch: (v) => setSettings(
                          (s) => s.copyWith(applicationUpdates: v),
                        ),
                      ),
                      MenuItem(
                        Icons.fact_check_outlined,
                        'Job approval updates',
                        switchValue: settings.employerMessages,
                        onSwitch: (v) =>
                            setSettings((s) => s.copyWith(employerMessages: v)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const AppearancePicker(),
                  const SizedBox(height: AppSpacing.xl),
                  MenuGroup(
                    items: [
                      MenuItem(
                        Icons.logout_rounded,
                        'Log out',
                        destructive: true,
                        onTap: () => confirmSignOut(context, ref),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Employers see a candidate\'s CV only after they apply.',
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
