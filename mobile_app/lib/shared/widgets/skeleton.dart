import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'app_surface.dart';

/// Drives a soft, synchronized pulse for every [Skeleton] below it.
/// Wrap a whole loading layout in one [Shimmer].
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _ShimmerScope(notifier: _c, child: widget.child);
}

class _ShimmerScope extends InheritedNotifier<AnimationController> {
  const _ShimmerScope({required super.notifier, required super.child});

  static double valueOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_ShimmerScope>()
          ?.notifier
          ?.value ??
      0;
}

/// A rounded placeholder block that pulses when inside a [Shimmer].
class Skeleton extends StatelessWidget {
  const Skeleton({super.key, this.width, this.height = 12, this.radius = 6});

  final double? width;
  final double height;
  final double radius;

  static Color get _from =>
      AppColors.isDark ? const Color(0xFF1A2836) : const Color(0xFFE6EDF3);
  static Color get _to =>
      AppColors.isDark ? const Color(0xFF223345) : const Color(0xFFF2F6F9);

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeInOut.transform(_ShimmerScope.valueOf(context));
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Color.lerp(_from, _to, t),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Loading placeholder matching the JobCard layout.
class JobCardSkeleton extends StatelessWidget {
  const JobCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Skeleton(width: 44, height: 44, radius: 12),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(width: 180, height: 14),
                    SizedBox(height: AppSpacing.sm),
                    Skeleton(width: 110),
                  ],
                ),
              ),
              Skeleton(width: 46, height: 46, radius: 23),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          Skeleton(width: 200),
          SizedBox(height: AppSpacing.sm),
          Skeleton(width: 120),
          SizedBox(height: AppSpacing.sm),
          Skeleton(width: 160),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Skeleton(width: 96, height: 24, radius: 12),
              Spacer(),
              Skeleton(width: 20, height: 22, radius: 4),
            ],
          ),
        ],
      ),
    );
  }
}

/// A vertical list of [count] job skeletons with standard spacing.
class JobListSkeleton extends StatelessWidget {
  const JobListSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            const JobCardSkeleton(),
          ],
        ],
      ),
    );
  }
}
