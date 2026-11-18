import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../../../shared/widgets/state_views.dart';
import '../providers/notifications_provider.dart';

/// In-app notifications (guide §3.5, mockup 4.4).
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static (IconData, Color, Color) styleOf(NotificationKind k) => switch (k) {
    NotificationKind.newMatches => (
      Icons.work_outline_rounded,
      AppColors.ocean,
      AppColors.oceanTint,
    ),
    NotificationKind.applicationUpdate => (
      Icons.trending_up_rounded,
      AppColors.success,
      AppColors.successTint,
    ),
    NotificationKind.savedReminder => (
      Icons.schedule_rounded,
      AppColors.warning,
      AppColors.warningTint,
    ),
    NotificationKind.employerResponse => (
      Icons.forum_outlined,
      AppColors.oceanDeep,
      AppColors.cyanTint,
    ),
    NotificationKind.system => (
      Icons.info_outline_rounded,
      AppColors.slate,
      Color(0xFFEDF2F6),
    ),
  };

  void _open(BuildContext context, WidgetRef ref, AppNotification n) {
    ref.read(notificationsProvider.notifier).markRead(n.id);
    final id = n.relatedId;
    if (id == null) return;
    switch (n.kind) {
      case NotificationKind.newMatches:
      case NotificationKind.savedReminder:
        context.push(AppRoutes.jobDetails(id));
      case NotificationKind.applicationUpdate:
      case NotificationKind.employerResponse:
        context.push(AppRoutes.applicationDetails(id));
      case NotificationKind.system:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadNotificationsProvider);
    final today = items
        .where((n) => DateTime.now().difference(n.createdAt).inHours < 24)
        .toList();
    final earlier = items.where((n) => !today.contains(n)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllRead(),
              child: const Text('Mark all as read'),
            ),
          IconButton(
            tooltip: 'Job alerts',
            onPressed: () => context.push(AppRoutes.jobAlerts),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: items.isEmpty
          ? const EmptyStateView(
              icon: Icons.notifications_none_rounded,
              title: 'You\'re all caught up',
              message: 'New matches and application updates will show up here.',
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
                    if (today.isNotEmpty) ...[
                      const _GroupTitle('New'),
                      for (final n in today)
                        _Tile(n: n, onTap: () => _open(context, ref, n)),
                    ],
                    if (earlier.isNotEmpty) ...[
                      const _GroupTitle('Earlier'),
                      for (final n in earlier)
                        _Tile(n: n, onTap: () => _open(context, ref, n)),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Swipe left on a notification to remove it.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      top: AppSpacing.md,
      bottom: AppSpacing.sm,
      left: AppSpacing.xs,
    ),
    child: Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.textTertiary,
        letterSpacing: 1.2,
      ),
    ),
  );
}

class _Tile extends ConsumerWidget {
  const _Tile({required this.n, required this.onTap});

  final AppNotification n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final (icon, fg, bg) = NotificationsScreen.styleOf(n.kind);
    final age = DateFormatters.relativeAge(n.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Dismissible(
        key: ValueKey(n.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.xl),
          decoration: const BoxDecoration(
            color: AppColors.errorTint,
            borderRadius: AppRadius.xlAll,
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.error,
          ),
        ),
        onDismissed: (_) {
          // Capture the controller now: this tile is gone by the time Undo is tapped.
          final controller = ref.read(notificationsProvider.notifier);
          final removed = controller.dismiss(n.id);
          AppFeedback.show(
            context,
            'Notification removed',
            actionLabel: 'Undo',
            onAction: () {
              if (removed != null) controller.restore(removed);
            },
          );
        },
        child: AppSurface(
          onTap: onTap,
          color: n.isRead ? AppColors.white : AppColors.mist,
          borderColor: n.isRead ? AppColors.border : AppColors.oceanTintStrong,
          elevated: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, color: fg, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(n.title, style: text.titleSmall)),
                        Text(
                          age == 'Just now' ? age : '$age ago',
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      n.message,
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!n.isRead) ...[
                const SizedBox(width: AppSpacing.sm),
                Semantics(
                  label: 'Unread',
                  child: Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.ocean,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
