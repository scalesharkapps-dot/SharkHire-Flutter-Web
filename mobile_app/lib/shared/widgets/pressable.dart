import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_spacing.dart';

/// Gives any child a subtle scale-down while pressed – the tactile feel used
/// by cards and tiles across the app.
///
/// It listens to raw pointer events, so it never competes with an inner
/// `InkWell`/`IconButton` for the tap. Pass [onTap] only when the child has
/// no tap handler of its own.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.985,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    // The pointer can lift after the widget is gone (e.g. a dismissed item).
    if (mounted && v != _down) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    Widget child = AnimatedScale(
      scale: _down ? widget.scale : 1,
      duration: AppDurations.fast,
      curve: Curves.easeOut,
      child: widget.child,
    );

    if (widget.onTap != null) {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: child,
      );
    }

    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: child,
    );
  }
}
