import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';

import '../../../../core/utils/feedback.dart';
import '../../../../shared/models/job_summary.dart';
import '../../../../shared/widgets/job_card.dart';
import '../providers/saved_jobs_provider.dart';

/// [JobCard] wired to the saved-jobs state, with save/undo feedback.
/// Use this anywhere a job appears so bookmarking behaves identically.
class SavedAwareJobCard extends ConsumerWidget {
  const SavedAwareJobCard({super.key, required this.job});

  final JobSummary job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaved = ref.watch(
      savedJobIdsProvider.select((ids) => ids.contains(job.id)),
    );
    final notifier = ref.read(savedJobIdsProvider.notifier);

    return JobCard(
      job: job,
      isSaved: isSaved,
      onTap: () => context.push(AppRoutes.jobDetails(job.id)),
      onToggleSave: () {
        notifier.toggle(job.id);
        AppFeedback.show(
          context,
          isSaved ? 'Removed from saved jobs' : 'Saved to your jobs',
          actionLabel: 'Undo',
          onAction: () => notifier.toggle(job.id),
        );
      },
    );
  }
}
