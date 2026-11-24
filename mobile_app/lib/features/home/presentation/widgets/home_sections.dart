import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../../../shared/widgets/pressable.dart';

/// Prompt to upload a CV – the key action that unlocks AI matching.
class CvPromptCard extends StatelessWidget {
  const CvPromptCard({
    super.key,
    required this.profileCompletion,
    required this.onUpload,
  });

  final double profileCompletion;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final percent = (profileCompletion * 100).round();

    // Quiet: one line icon in the text color, no tinted tile, no progress
    // bar; the job cards below carry the page.
    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Upload your CV for sharper matches',
                  style: text.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'PDF or DOCX. Profile $percent% complete',
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: onUpload,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
            child: const Text('Upload CV'),
          ),
        ],
      ),
    );
  }
}

/// Horizontal list of job category tiles.
class CategoryStrip extends StatelessWidget {
  const CategoryStrip({
    super.key,
    required this.categories,
    required this.onTap,
  });

  final List<String> categories;
  final ValueChanged<String> onTap;

  static IconData iconFor(String category) => switch (category) {
    'Software' => Icons.code_rounded,
    'Data / AI' => Icons.insights_rounded,
    'Design' => Icons.brush_outlined,
    'Marketing' => Icons.campaign_outlined,
    'Finance' => Icons.account_balance_outlined,
    'Operations' => Icons.settings_suggest_outlined,
    _ => Icons.work_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screenPadding,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm + 2),
        itemBuilder: (context, i) {
          final c = categories[i];
          return Pressable(
            onTap: () => onTap(c),
            child: Container(
              width: 96,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.xlAll,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(iconFor(c), color: AppColors.ocean, size: 24),
                  Text(
                    c,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelMedium,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Saved job alert summary row.
class JobAlertCard extends StatelessWidget {
  const JobAlertCard({
    super.key,
    required this.title,
    required this.meta,
    this.onTap,
  });

  final String title;
  final String meta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppSurface(
      onTap: onTap,
      color: AppColors.mist,
      borderColor: AppColors.oceanTintStrong,
      elevated: false,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_active_outlined, color: AppColors.ocean),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleSmall),
                Text(meta, style: text.bodySmall),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}
