import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../models/domain_enums.dart';

/// Visual tone of a status. Semantic colours only – never decoration.
enum StatusTone {
  neutral,
  info,
  progress,
  positive,
  negative;

  Color get fg => switch (this) {
    neutral => AppColors.textSecondary,
    info => AppColors.oceanDeep,
    progress => AppColors.warning,
    positive => AppColors.success,
    negative => AppColors.error,
  };

  Color get bg => switch (this) {
    neutral => AppColors.surfaceMuted,
    info => AppColors.oceanTint,
    progress => AppColors.warningTint,
    positive => AppColors.successTint,
    negative => AppColors.errorTint,
  };
}

StatusTone toneOfApplication(ApplicationStatus s) => switch (s) {
  ApplicationStatus.submitted => StatusTone.info,
  ApplicationStatus.underReview => StatusTone.progress,
  ApplicationStatus.shortlisted => StatusTone.positive,
  ApplicationStatus.interview => StatusTone.positive,
  ApplicationStatus.accepted => StatusTone.positive,
  ApplicationStatus.rejected => StatusTone.negative,
  ApplicationStatus.withdrawn => StatusTone.neutral,
};

StatusTone toneOfJob(JobStatus s) => switch (s) {
  JobStatus.draft => StatusTone.neutral,
  JobStatus.pending => StatusTone.progress,
  JobStatus.approved => StatusTone.positive,
  JobStatus.rejected => StatusTone.negative,
  JobStatus.closed => StatusTone.neutral,
  JobStatus.expired => StatusTone.neutral,
};

/// Compact rounded status label with a leading dot.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.tone});

  StatusChip.application(ApplicationStatus s, {super.key})
    : label = s.label,
      tone = toneOfApplication(s);

  StatusChip.job(JobStatus s, {super.key})
    : label = s.label,
      tone = toneOfJob(s);

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Status: $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: tone.bg,
          borderRadius: const BorderRadius.all(Radius.circular(6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: tone.fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontSize: 12, color: tone.fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
