import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_typography.dart';

/// "Bold" look used by the welcome screens and the roles picker: near-black
/// ground, huge uppercase type, one teal accent, pill buttons. These screens
/// stay dark in both app themes, like a splash.
abstract final class Bold {
  static const Color ground = Color(0xFF05090E);
  static const Color raised = Color(0xFF0E1620);
  static const Color raisedLine = Color(0xFF1A2633);
  static const Color chip = Color(0xFF16202B);
  static const Color ink = Color(0xFFE9F0F6);
  static const Color muted = Color(0xFF93A6B8);
  static const Color faint = Color(0xFF7E91A4);
  static const Color accent = Color(0xFF18ACC3);
  static const Color onLight = Color(0xFF05090E);
}

/// Huge uppercase statement; [spans] marked `true` are drawn in the accent.
class BoldHeadline extends StatelessWidget {
  const BoldHeadline({
    super.key,
    required this.spans,
    required this.semanticsLabel,
    this.fontSize = 60,
  });

  final List<(String, bool)> spans;
  final String semanticsLabel;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text.rich(
          TextSpan(
            children: [
              for (final (t, accent) in spans)
                TextSpan(
                  text: t.toUpperCase(),
                  style: TextStyle(color: accent ? Bold.accent : Bold.ink),
                ),
            ],
          ),
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: fontSize,
            height: 0.92,
            letterSpacing: -1.2,
          ),
        ),
      ),
    );
  }
}

/// Brand row at the top of the bold screens: two accent bars + wordmark,
/// or a small label on the left.
class BoldTopBar extends StatelessWidget {
  const BoldTopBar({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (label == null)
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_Bar(width: 40), SizedBox(height: 6), _Bar(width: 26)],
          )
        else
          Expanded(
            child: Text(
              label!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppFonts.label,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 2,
                color: Bold.muted,
              ),
            ),
          ),
        const SizedBox(width: 12),
        if (label == null) const Spacer(),
        const Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Shark'),
              TextSpan(
                text: 'Hire',
                style: TextStyle(color: Bold.accent),
              ),
            ],
          ),
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 16,
            color: Bold.ink,
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 5,
    decoration: const BoxDecoration(
      color: Bold.accent,
      borderRadius: BorderRadius.all(Radius.circular(3)),
    ),
  );
}

ButtonStyle _boldStyle(Color bg, Color fg) => FilledButton.styleFrom(
  backgroundColor: bg,
  foregroundColor: fg,
  minimumSize: const Size(64, 58),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(18)),
  ),
  textStyle: const TextStyle(
    fontFamily: AppFonts.label,
    fontWeight: FontWeight.w800,
    fontSize: 16,
  ),
);

/// Light (or accent) pill button on the dark ground.
class BoldPrimaryButton extends StatelessWidget {
  const BoldPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingArrow = false,
    this.accent = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool trailingArrow;

  /// Fills the button with the accent instead of the light ink.
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final style = _boldStyle(accent ? Bold.accent : Bold.ink, Bold.onLight);
    if (!trailingArrow) {
      return FilledButton(
        onPressed: onPressed,
        style: style,
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      );
    }
    return FilledButton(
      onPressed: onPressed,
      style: style.copyWith(
        padding: const WidgetStatePropertyAll(EdgeInsets.fromLTRB(22, 8, 8, 8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Bold.onLight,
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: Bold.accent,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dark raised pill button.
class BoldSecondaryButton extends StatelessWidget {
  const BoldSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: _boldStyle(Bold.chip, Bold.ink),
    child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
  );
}

/// Small rounded chip on the dark ground.
class BoldChip extends StatelessWidget {
  const BoldChip(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: const BoxDecoration(
      color: Bold.chip,
      borderRadius: BorderRadius.all(Radius.circular(15)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontFamily: AppFonts.label,
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: Bold.ink,
      ),
    ),
  );
}
