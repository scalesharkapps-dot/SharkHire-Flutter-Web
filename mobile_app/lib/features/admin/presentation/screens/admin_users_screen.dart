import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../../shared/widgets/person_avatar.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../data/models/admin_models.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';

/// User management: view, block, deactivate (guide §3.7).
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _query = '';
  AppRole? _role;

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final users = ref
        .watch(adminUsersProvider)
        .where(
          (u) =>
              (_role == null || u.role == _role) &&
              (q.isEmpty ||
                  u.name.toLowerCase().contains(q) ||
                  u.email.toLowerCase().contains(q)),
        )
        .toList();

    return AdminPage(
      title: 'Users',
      showBack: false,
      intro:
          'Admin roles are granted only through a trusted process, never from here.',
      children: [
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: const InputDecoration(
            hintText: 'Search name or email',
            prefixIcon: Icon(Icons.search_rounded, size: 20),
          ),
        ),
        ChoiceChipGroup<AppRole?>(
          options: const [null, AppRole.jobSeeker, AppRole.employer],
          selected: {_role},
          multiSelect: false,
          labelOf: (r) => r == null ? 'All' : '${r.label}s',
          onChanged: (s) => setState(() => _role = s.first),
        ),
        if (users.isEmpty)
          const EmptyStateView(
            compact: true,
            icon: Icons.person_search_outlined,
            title: 'No users found',
            message: 'Try a different name or email.',
          )
        else
          for (final u in users) _UserCard(user: u),
      ],
    );
  }
}

class _UserCard extends ConsumerWidget {
  const _UserCard({required this.user});

  final AdminUserRecord user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final u = user;
    final initials = u.name
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0])
        .join();
    return AppSurface(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          PersonAvatar(initials: initials, size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u.name, style: text.titleSmall),
                Text(
                  u.email,
                  style: text.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    StatusChip(label: u.role.label, tone: StatusTone.info),
                    StatusChip(
                      label: u.status.label,
                      tone: switch (u.status) {
                        AccountStatus.active => StatusTone.positive,
                        AccountStatus.blocked => StatusTone.negative,
                        AccountStatus.deactivated => StatusTone.neutral,
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<AccountStatus>(
            tooltip: 'Actions for ${u.name}',
            icon: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
            onSelected: (s) {
              ref.read(adminUsersProvider.notifier).setStatus(u.id, s);
              AppFeedback.show(context, '${u.name}: ${s.label.toLowerCase()}');
            },
            itemBuilder: (_) => [
              if (u.status != AccountStatus.active)
                const PopupMenuItem(
                  value: AccountStatus.active,
                  child: Text('Reactivate'),
                ),
              if (u.status != AccountStatus.blocked)
                const PopupMenuItem(
                  value: AccountStatus.blocked,
                  child: Text('Block'),
                ),
              if (u.status != AccountStatus.deactivated)
                const PopupMenuItem(
                  value: AccountStatus.deactivated,
                  child: Text('Deactivate'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
