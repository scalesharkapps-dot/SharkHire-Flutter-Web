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
/// edge of a job card ("92 / % FIT").
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
            Text(
              '${score.clamp(0, 100)}',
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
              '% FIT',
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

/// The fit score as a big number with a thin bar of ten ticks beside it
/// ("92 ▮▮▮▮▮▮▮▮▮▯"). The score is the screen's one accent when it is a
/// strong fit (90+).
class FitScoreInline extends StatelessWidget {
  const FitScoreInline({
    super.key,
    required this.score,
    this.fontSize = 22,
    this.label,
  });

  final int score;
  final double fontSize;

  /// Optional words beside the ticks, e.g. "Strong fit with your CV".
  final String? label;

  @override
  Widget build(BuildContext context) {
    final s = score.clamp(0, 100);
    final strong = s >= 90;
    final ticks = FitTicks(score: s);
    return Semantics(
      label: '$s percent fit with your CV',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$s',
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: fontSize,
              height: 1,
              color: strong ? AppColors.ocean : AppColors.ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          SizedBox(width: fontSize >= 40 ? 14 : 10),
          if (label == null)
            ticks
          else
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label!, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  ticks,
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Ten small ticks, one per 10% of fit.
class FitTicks extends StatelessWidget {
  const FitTicks({super.key, required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final on = (score.clamp(0, 100) / 10).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 10; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          Container(
            width: 6,
            height: 12,
            decoration: BoxDecoration(
              color: i < on ? AppColors.teal : AppColors.surfaceMuted,
              borderRadius: const BorderRadius.all(Radius.circular(2)),
            ),
          ),
        ],
      ],
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
