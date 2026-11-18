import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Match strength tiers (aligned with the guide: 80+ strong, 65+ good).
enum MatchTier {
  strong('Strong match', AppColors.success, AppColors.successTint),
  good('Good match', AppColors.ocean, AppColors.oceanTint),
  fair('Fair match', AppColors.warning, AppColors.warningTint);

  const MatchTier(this.label, this.color, this.tint);
  final String label;
  final Color color;
  final Color tint;

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
                  color: AppColors.navy,
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
