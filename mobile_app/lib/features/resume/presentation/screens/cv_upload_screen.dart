import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/bottom_action_bar.dart';
import '../../../../shared/widgets/fade_in_up.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../../shared/widgets/pressable.dart';
import '../../data/models/resume_models.dart';
import '../../data/repositories/resume_repository.dart';
import '../providers/cv_provider.dart';

/// Upload CV (guide §3.5, mockup 4.2): pick a PDF/DOCX, validate it, then
/// follow the processing steps until the extracted profile is ready.
class CvUploadScreen extends ConsumerStatefulWidget {
  const CvUploadScreen({super.key, this.fromOnboarding = false});

  final bool fromOnboarding;

  @override
  ConsumerState<CvUploadScreen> createState() => _CvUploadScreenState();
}

class _CvUploadScreenState extends ConsumerState<CvUploadScreen> {
  PickedCvFile? _file;
  String? _error;

  /// Why the last upload failed. Unlike [_error] (a problem with the file
  /// itself) it keeps the file selected so the user can simply retry.
  String? _uploadError;
  CvProcessingStage? _stage;
  StreamSubscription<CvProcessingStage>? _sub;

  bool get _processing => _stage != null && _stage != CvProcessingStage.done;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _pick() async {
    if (_processing) return;
    try {
      final file = await ref.read(cvPickerProvider)();
      if (file == null || !mounted) return;
      setState(() {
        _file = file;
        _error = CvRules.validate(file);
        _uploadError = null;
        _stage = null;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'We couldn\'t open that file. Try choosing it again.',
        );
      }
    }
  }

  void _upload() {
    final file = _file;
    if (file == null || _error != null) return;
    _sub?.cancel();
    setState(() {
      _stage = CvProcessingStage.uploading;
      _uploadError = null;
    });
    _sub = ref
        .read(resumeRepositoryProvider)
        .uploadAndProcess(file)
        .listen(
          (stage) {
            if (!mounted) return;
            setState(() => _stage = stage);
            if (stage == CvProcessingStage.done) {
              ref.read(cvProvider.notifier).markUploaded(file);
              context.pushReplacement(AppRoutes.cvReview);
            }
          },
          onError: (Object e) {
            if (!mounted) return;
            setState(() {
              _stage = null;
              // The server's reason (file rejected, storage unavailable,
              // offline…) instead of always blaming the connection.
              _uploadError = friendlyErrorMessage(e);
            });
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final canUpload = _file != null && _error == null && !_processing;

    return Scaffold(
      appBar: AppBar(
        title: widget.fromOnboarding ? null : const Text('Upload your CV'),
        automaticallyImplyLeading: !widget.fromOnboarding,
        actions: [
          if (widget.fromOnboarding && !_processing)
            TextButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Skip for now'),
            ),
        ],
      ),
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
                if (widget.fromOnboarding) ...[
                  Text(
                    'Step 2 of 2',
                    style: text.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Upload your CV', style: text.headlineLarge),
                  const SizedBox(height: AppSpacing.sm),
                ],
                Text(
                  'We read your skills, experience and education to rank jobs for you. '
                  'You\'ll review everything before it\'s used.',
                  style: text.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FadeInUp(
                  child: _DropZone(
                    file: _file,
                    error: _error,
                    onTap: _processing ? null : _pick,
                  ),
                ),
                if ((_error ?? _uploadError) != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  InlineBanner(
                    message: (_error ?? _uploadError)!,
                    tone: BannerTone.error,
                  ),
                ],
                if (_stage != null) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  Text('Processing', style: text.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  _ProcessingSteps(current: _stage!),
                ],
                const SizedBox(height: AppSpacing.xxl),
                const InlineBanner(
                  tone: BannerTone.info,
                  showMark: false,
                  title: 'Your CV stays private',
                  message:
                      'It\'s stored securely and only shared with an employer when you apply to their job.',
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: LoadingButton(
          label: _file == null ? 'Choose a file' : 'Upload and analyse',
          icon: _file == null
              ? Icons.folder_open_rounded
              : Icons.upload_file_outlined,
          loading: _processing,
          onPressed: _file == null ? _pick : (canUpload ? _upload : null),
        ),
      ),
    );
  }
}

class _DropZone extends StatelessWidget {
  const _DropZone({
    required this.file,
    required this.error,
    required this.onTap,
  });

  final PickedCvFile? file;
  final String? error;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final hasFile = file != null;
    final ok = hasFile && error == null;
    final borderColor = error != null
        ? AppColors.error
        : ok
        ? AppColors.success
        : AppColors.textSecondary;

    return Semantics(
      button: true,
      label: hasFile
          ? 'Selected ${file!.name}. Tap to choose a different file'
          : 'Choose your CV file',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.medium,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xxl,
          ),
          decoration: BoxDecoration(
            color: error != null
                ? AppColors.errorTint
                : (ok ? AppColors.successTint : AppColors.surface),
            borderRadius: AppRadius.xlAll,
            border: Border.all(
              color: error != null || ok
                  ? borderColor.withValues(alpha: 0.6)
                  : AppColors.borderStrong,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(
                  !hasFile
                      ? Icons.upload_file_rounded
                      : (ok ? Icons.description_rounded : Icons.block_rounded),
                  color: borderColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                hasFile ? file!.name : 'Tap to choose your CV',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                hasFile
                    ? '${CvRules.formatSize(file!.sizeBytes)} · tap to choose a different file'
                    : 'PDF or DOCX · up to ${CvRules.maxSizeLabel}',
                textAlign: TextAlign.center,
                style: text.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProcessingSteps extends StatelessWidget {
  const _ProcessingSteps({required this.current});

  final CvProcessingStage current;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final steps = CvProcessingStage.values
        .where((s) => s != CvProcessingStage.done)
        .toList();
    return Column(
      children: [
        for (final s in steps)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 24,
                  child: AnimatedSwitcher(
                    duration: AppDurations.medium,
                    child: s.index < current.index
                        ? Icon(
                            Icons.check_circle_rounded,
                            key: ValueKey('done'),
                            color: AppColors.success,
                            size: 24,
                          )
                        : s == current
                        ? const Padding(
                            key: ValueKey('busy'),
                            padding: EdgeInsets.all(3),
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : Icon(
                            Icons.radio_button_unchecked_rounded,
                            key: ValueKey('todo'),
                            color: AppColors.borderStrong,
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    s.label,
                    style: text.bodyLarge?.copyWith(
                      color: s.index <= current.index
                          ? AppColors.ink
                          : AppColors.textTertiary,
                      fontWeight: s == current
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
