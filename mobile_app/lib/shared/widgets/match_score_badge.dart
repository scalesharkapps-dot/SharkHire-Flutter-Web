import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Match strength tiers (aligned with the guide: 80+ strong, 65+ good).
enum MatchTier {
  strong('Strong match'),
  good('Good match'),
  fair('Fair match');

  const MatchTier(this.label);
  final String label;

  Color get color => switch (this) {
    strong => AppColors.success,
    good => AppColors.ocean,
    fair => AppColors.warning,
  };

  Color get tint => switch (this) {
    strong => AppColors.successTint,
    good => AppColors.oceanTint,
    fair => AppColors.warningTint,
  };

  static MatchTier of(int score) => score >= 80
      ? MatchTier.strong
      : score >= 65
      ? MatchTier.good
      : MatchTier.fair;
}

/// Circular progress ring showing a CV match percentage.
/// The ring animates from 0 the first time it appears.
class MatchScoreRing extends StatelessWidget {
  const MatchScoreRing({super.key, required this.score, this.size = 48});

  final int score;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tier = MatchTier.of(score);
    final value = score.clamp(0, 100) / 100;

    return Semantics(
      label: '$score percent match',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: v,
              color: tier.color,
              track: tier.tint,
            ),
            child: Center(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '${(v * 100).round()}'),
                    TextSpan(
                      text: '%',
                      style: TextStyle(
                        fontSize: size * 0.17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                style: TextStyle(
                  fontFamily: AppFonts.label,
                  fontWeight: FontWeight.w700,
                  fontSize: size * 0.27,
                  height: 1,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.085;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);

    canvas.drawCircle(
      rect.center,
      arcRect.width / 2,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

/// Signal "FIT" block: the match score as a solid navy column on the left
/// edge of a job card ("92%" over "FIT").
class FitScoreBlock extends StatelessWidget {
  const FitScoreBlock({super.key, required this.score, this.width = 76});

  final int score;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$score percent match',
      excludeSemantics: true,
      child: Container(
        width: width,
        color: AppColors.fit,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${score.clamp(0, 100)}'),
                  const TextSpan(text: '%', style: TextStyle(fontSize: 15)),
                ],
              ),
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 26,
                height: 1,
                color: AppColors.fitInk,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'FIT',
              style: TextStyle(
                fontFamily: AppFonts.label,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 1,
                color: AppColors.fitLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact pill variant: "92% match", tinted by tier.
class MatchScorePill extends StatelessWidget {
  const MatchScorePill({super.key, required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final tier = MatchTier.of(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tier.tint,
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$score% match',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontSize: 12, color: tier.color),
          ),
        ],
      ),
    );
  }
}

/// Ten small ticks showing a fit score (92 → nine lit ticks).
class FitTicks extends StatelessWidget {
  const FitTicks({super.key, required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final lit = (score.clamp(0, 100) / 10).round();
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 10; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Container(
              width: 6,
              height: 12,
              decoration: BoxDecoration(
                color: i < lit ? AppColors.teal : AppColors.surfaceMuted,
                borderRadius: const BorderRadius.all(Radius.circular(2)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Big "92%" fit number with the tier line and ticks: the fit card header
/// used on Job details and the employer's Candidate screen.
class FitScoreHeader extends StatelessWidget {
  const FitScoreHeader({super.key, required this.score, this.caption});

  final int score;

  /// Line under the number; defaults to "Strong fit with your CV".
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final word = MatchTier.of(score).label.split(' ').first;
    final line = caption ?? '$word fit with your CV';
    return Semantics(
      label: '$score percent fit. $line',
      excludeSemantics: true,
      child: Row(
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${score.clamp(0, 100)}'),
                const TextSpan(text: '%', style: TextStyle(fontSize: 22)),
              ],
            ),
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 40,
              height: 1,
              letterSpacing: -1,
              color: AppColors.isDark ? AppColors.teal : AppColors.ocean,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line, style: text.titleSmall),
                const SizedBox(height: 6),
                FitTicks(score: score),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
