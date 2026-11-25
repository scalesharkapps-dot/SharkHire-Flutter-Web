import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../../../shared/widgets/fade_in_up.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../data/models/application.dart';
import '../providers/applications_provider.dart';
import '../../../../shared/widgets/shark_loader.dart';

enum _Filter { all, active, closed }

/// Application tracking (guide §3.5, mockup 4.4).
class ApplicationsScreen extends ConsumerStatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  ConsumerState<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends ConsumerState<ApplicationsScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(applicationsProvider);
    final active = all.where((a) => a.isActive).length;
    final shown = switch (_filter) {
      _Filter.all => all,
      _Filter.active => all.where((a) => a.isActive).toList(),
      _Filter.closed => all.where((a) => !a.isActive).toList(),
    }..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final load = ref.watch(applicationsLoadProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My applications')),
      body: all.isEmpty && load.isLoading
          ? const SharkLoader()
          : all.isEmpty && load.hasError
          ? ErrorStateView(
              message: friendlyErrorMessage(load.error!),
              onRetry: () => ref.read(applicationsProvider.notifier).reload(),
            )
          : all.isEmpty
          ? EmptyStateView(
              icon: Icons.send_outlined,
              title: 'No applications yet',
              message:
                  'When you apply to a job on SharkHire, you can follow every step here.',
              actionLabel: 'Find jobs to apply',
              onAction: () => context.go(AppRoutes.explore),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    0,
                    AppSpacing.screenHorizontal,
                    AppSpacing.xxxl,
                  ),
                  children: [
                    Text(
                      '$active active · ${all.length - active} closed',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ChoiceChipGroup<_Filter>(
                      options: _Filter.values,
                      selected: {_filter},
                      multiSelect: false,
                      labelOf: (f) => switch (f) {
                        _Filter.all => 'All',
                        _Filter.active => 'Active',
                        _Filter.closed => 'Closed',
                      },
                      onChanged: (s) => setState(() => _filter = s.first),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (shown.isEmpty)
                      const EmptyStateView(
                        compact: true,
                        icon: Icons.inbox_outlined,
                        title: 'Nothing here',
                        message: 'No applications match this filter.',
                      )
                    else
                      for (var i = 0; i < shown.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: FadeInUp(
                            delay: Duration(milliseconds: 50 * i.clamp(0, 6)),
                            child: ApplicationCard(application: shown[i]),
                          ),
                        ),
                    const SizedBox(height: AppSpacing.md),
                    const InlineBanner(
                      message:
                          'Applications to external jobs happen on the employer\'s site, '
                          'so they aren\'t tracked here.',
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class ApplicationCard extends StatelessWidget {
  const ApplicationCard({super.key, required this.application});

  final JobApplication application;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final a = application;
    return AppSurface(
      onTap: () => context.push(AppRoutes.applicationDetails(a.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.job.title,
                      style: text.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(a.job.companyName, style: text.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              StatusChip.application(a.status),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Updated ${DateFormatters.relativeAge(a.updatedAt).toLowerCase()}'
                  '${DateFormatters.relativeAge(a.updatedAt) == 'Just now' ? '' : ' ago'}',
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (a.history.last.note != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              a.history.last.note!,
              style: text.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
