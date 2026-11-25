import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';

/// The SharkHire loader: a small teal fin that swims along a thin line.
///
/// Without [value] it loops (unknown wait). With [value] (0–1) the fin
/// glides to that point, for progress the app can measure.
class SharkSwim extends StatefulWidget {
  const SharkSwim({
    super.key,
    this.value,
    this.width = 120,
    this.finSize = 16,
    this.color,
    this.trackColor,
    this.semanticsLabel = 'Loading',
  });

  final double? value;
  final double width;
  final double finSize;
  final Color? color;
  final Color? trackColor;
  final String semanticsLabel;

  @override
  State<SharkSwim> createState() => _SharkSwimState();
}

class _SharkSwimState extends State<SharkSwim>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(SharkSwim old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.value == null && !still) {
      if (!_loop.isAnimating) _loop.repeat();
    } else {
      _loop.stop();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.teal;
    final track = widget.trackColor ?? AppColors.border;
    final fin = widget.finSize;
    final line = (fin * 0.2).clamp(2.0, 4.0);

    Widget paint(double t) => CustomPaint(
      size: Size(widget.width, fin + line + 1),
      painter: _SwimPainter(
        t: t,
        color: color,
        track: track,
        fin: fin,
        line: line,
      ),
    );

    final Widget body = widget.value != null
        ? TweenAnimationBuilder<double>(
            tween: Tween(end: widget.value!.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, t, _) => paint(t),
          )
        : AnimatedBuilder(
            animation: _loop,
            builder: (_, _) => paint(Curves.easeInOut.transform(_loop.value)),
          );

    return Semantics(
      label: widget.semanticsLabel,
      value: widget.value == null ? null : '${(widget.value! * 100).round()}%',
      child: ExcludeSemantics(child: body),
    );
  }
}

class _SwimPainter extends CustomPainter {
  _SwimPainter({
    required this.t,
    required this.color,
    required this.track,
    required this.fin,
    required this.line,
  });

  final double t;
  final Color color;
  final Color track;
  final double fin;
  final double line;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height - line;
    final r = Radius.circular(line / 2);
    canvas.drawRRect(
      RRect.fromLTRBR(0, y, size.width, y + line, r),
      Paint()..color = track,
    );
    final finW = fin * 1.35;
    final x = (size.width - finW) * t;
    canvas.drawRRect(
      RRect.fromLTRBR(0, y, x + finW * 0.6, y + line, r),
      Paint()..color = color,
    );
    // Dorsal fin: a curved front edge, a swept tip and a hollow back.
    final base = y - 0.5;
    final path = Path()
      ..moveTo(x, base)
      ..quadraticBezierTo(
        x + finW * 0.42,
        base - fin * 0.35,
        x + finW * 0.55,
        base - fin,
      )
      ..quadraticBezierTo(x + finW * 0.68, base - fin * 0.3, x + finW, base)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SwimPainter old) =>
      old.t != t || old.color != color || old.track != track;
}

/// A centred loader for a page or panel that is still loading.
class SharkLoader extends StatelessWidget {
  const SharkLoader({super.key, this.label});

  /// Optional short line under the fin, e.g. "Loading jobs".
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SharkSwim(width: 110, semanticsLabel: label ?? 'Loading'),
          if (label != null) ...[
            const SizedBox(height: 12),
            Text(
              label!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
