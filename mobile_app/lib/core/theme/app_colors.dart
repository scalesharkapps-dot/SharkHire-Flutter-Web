import 'package:material_ui/material_ui.dart';

/// SharkHire colour tokens.
///
/// Every brand colour is sampled from the official Scale Shark logo
/// (assets/images/brand/scale_shark_logo.jpg) or taken from the design
/// tokens of thescaleshark.io. Reference these tokens (or
/// `Theme.of(context).colorScheme`) and never hard-code hex values in widgets.
abstract final class AppColors {
  // ── Brand core ──────────────────────────────────────────────────────────
  /// Website primary (hsl 211 57% 13%) and the logo's shark outline.
  static const Color navy = Color(0xFF0E2134);

  /// Darkest ink in the logo; deep layers on navy surfaces.
  static const Color navyDeep = Color(0xFF071628);

  /// Raised layer on navy surfaces (pills, stat tiles in headers).
  static const Color navySoft = Color(0xFF1A3049);

  /// Logo ocean blue (#0874CA), deepened a touch to reach WCAG AA 4.5:1
  /// for text on white – main interactive accent (links, focus, selection).
  static const Color ocean = Color(0xFF066CBE);

  /// Logo deep water – pressed/strong states of [ocean].
  static const Color oceanDeep = Color(0xFF064B92);

  /// Logo cyan – small highlights on dark surfaces (never decoration).
  static const Color cyan = Color(0xFF10AFEE);

  /// Website accent (hsl 188 78% 43%) – the "Hire" in the wordmark.
  static const Color teal = Color(0xFF18ACC3);

  /// Logo shark body slate – avatars and neutral illustration tones.
  static const Color slate = Color(0xFF356891);

  // ── Brand tints (derived from ocean/cyan for backgrounds) ───────────────
  static const Color oceanTint = Color(0xFFE6F1FA);
  static const Color oceanTintStrong = Color(0xFFCCE3F5);
  static const Color cyanTint = Color(0xFFE3F6FD);

  // ── Surfaces ────────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);

  /// App canvas behind cards – a cool off-white.
  static const Color canvas = Color(0xFFF5F7F9);

  /// Website page background (hsl 198 100% 97%) – tinted brand panels.
  static const Color mist = Color(0xFFF0FAFF);

  static const Color surfaceSubtle = Color(0xFFF7F9FB);

  // ── Text ────────────────────────────────────────────────────────────────
  static const Color textPrimary = navy;

  /// Website muted foreground (hsl 208 24% 35%).
  static const Color textSecondary = Color(0xFF445A6F);

  /// Meets WCAG AA (4.5:1) on white and on the canvas.
  static const Color textTertiary = Color(0xFF5E7082);
  static const Color textOnDark = white;
  static const Color textOnDarkMuted = Color(0xFFAFC0D0);

  // ── Lines ───────────────────────────────────────────────────────────────
  static const Color border = Color(0xFFE3EAF0);
  static const Color borderStrong = Color(0xFFC3D0DB);

  // ── Semantic (status only, never decoration) ────────────────────────────
  static const Color success = Color(0xFF12924A);
  static const Color successTint = Color(0xFFE2F5EA);
  static const Color warning = Color(0xFFC27803);
  static const Color warningTint = Color(0xFFFDF1DC);
  static const Color error = Color(0xFFC0352A);
  static const Color errorTint = Color(0xFFFCE7E4);

  // ── Elevation ───────────────────────────────────────────────────────────
  /// Cards are defined by a hairline border; the shadow only lifts them a
  /// hair off the canvas (no floating "AI card" look).
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0A0E2134), blurRadius: 2, offset: Offset(0, 1)),
  ];

  /// Menus, sheets and other surfaces that really float.
  static const List<BoxShadow> raisedShadow = [
    BoxShadow(color: Color(0x140E2134), blurRadius: 16, offset: Offset(0, 6)),
  ];
}
