import 'package:material_ui/material_ui.dart';

/// SharkHire colour tokens, for the light and the dark theme.
///
/// Every brand colour is sampled from the official Scale Shark logo
/// (assets/images/brand/scale_shark_logo.jpg) or taken from the design
/// tokens of thescaleshark.io. Reference these tokens (or
/// `Theme.of(context).colorScheme`) and never hard-code hex values in widgets.
///
/// Theme-dependent tokens are getters: they answer for the active theme,
/// which the app root sets with [useDark] before building the widget tree
/// (and rebuilds the tree when it changes). Brand constants ([navy],
/// [white], …) stay the same in both themes: use them for branded navy
/// panels and the text on them, and use [ink] / [surface] for ordinary
/// text and cards.
abstract final class AppColors {
  static bool _dark = false;

  /// Whether the dark palette is active.
  static bool get isDark => _dark;

  /// Switches the palette. Called by the app root only.
  static void useDark(bool dark) => _dark = dark;

  static Color _pick(Color light, Color dark) => _dark ? dark : light;

  // ── Brand constants (same in both themes) ───────────────────────────────
  /// Website primary (hsl 211 57% 13%) and the logo's shark outline.
  /// Branded panels (hero headers, splash); not for body text.
  static const Color navy = Color(0xFF0E2134);

  /// Darkest ink in the logo; deep layers on navy surfaces.
  static const Color navyDeep = Color(0xFF071628);

  /// Raised layer on navy surfaces (pills, stat tiles in headers).
  static const Color navySoft = Color(0xFF1A3049);

  /// Logo cyan – small highlights on dark surfaces (never decoration).
  static const Color cyan = Color(0xFF10AFEE);

  /// Website accent (hsl 188 78% 43%) – the "Hire" in the wordmark.
  static const Color teal = Color(0xFF18ACC3);

  /// Pure white: text and icons on navy or ocean panels, logo tiles.
  static const Color white = Color(0xFFFFFFFF);
  static const Color textOnDark = white;
  static const Color textOnDarkMuted = Color(0xFFAFC0D0);

  // ── Text & strong fills ─────────────────────────────────────────────────
  /// Main text and icons; also the fill of selected chips and the primary
  /// button (with [onInk] on top).
  static Color get ink => _pick(navy, const Color(0xFFE8EEF4));

  /// Text and icons on an [ink] fill.
  static Color get onInk => _pick(white, navy);

  static Color get textPrimary => ink;

  /// Website muted foreground (hsl 208 24% 35%).
  static Color get textSecondary =>
      _pick(const Color(0xFF445A6F), const Color(0xFFA9B9C9));

  /// Meets WCAG AA (4.5:1) on the surface and the canvas in both themes.
  static Color get textTertiary =>
      _pick(const Color(0xFF5E7082), const Color(0xFF8B9DB0));

  // ── Accents ─────────────────────────────────────────────────────────────
  /// Logo ocean blue, main interactive accent (links, focus, selection).
  /// Lightened on dark so it keeps 4.5:1 contrast.
  static Color get ocean =>
      _pick(const Color(0xFF066CBE), const Color(0xFF5AAEF0));

  /// Strong / pressed states of [ocean].
  static Color get oceanDeep =>
      _pick(const Color(0xFF064B92), const Color(0xFF9ACBF5));

  /// Logo shark body slate – avatars and neutral illustration tones.
  static Color get slate =>
      _pick(const Color(0xFF356891), const Color(0xFF8DB0CF));

  // ── Tints ───────────────────────────────────────────────────────────────
  static Color get oceanTint =>
      _pick(const Color(0xFFE6F1FA), const Color(0xFF13304A));
  static Color get oceanTintStrong =>
      _pick(const Color(0xFFCCE3F5), const Color(0xFF1A4163));
  static Color get cyanTint =>
      _pick(const Color(0xFFE3F6FD), const Color(0xFF10313F));

  // ── Surfaces ────────────────────────────────────────────────────────────
  /// Cards, sheets, bars and inputs.
  static Color get surface => _pick(white, const Color(0xFF121E2A));

  /// App canvas behind cards.
  static Color get canvas =>
      _pick(const Color(0xFFF5F7F9), const Color(0xFF0A131C));

  /// Tinted brand panels (website page background).
  static Color get mist =>
      _pick(const Color(0xFFF0FAFF), const Color(0xFF102233));

  static Color get surfaceSubtle =>
      _pick(const Color(0xFFF7F9FB), const Color(0xFF0F1A25));

  /// Quiet filled areas (neutral chips, placeholders, read rows).
  static Color get surfaceMuted =>
      _pick(const Color(0xFFEDF2F6), const Color(0xFF1B2938));

  // ── Lines ───────────────────────────────────────────────────────────────
  static Color get border =>
      _pick(const Color(0xFFE3EAF0), const Color(0xFF223346));
  static Color get borderStrong =>
      _pick(const Color(0xFFC3D0DB), const Color(0xFF34495F));

  // ── Semantic (status only, never decoration) ────────────────────────────
  static Color get success =>
      _pick(const Color(0xFF12924A), const Color(0xFF45C784));
  static Color get successTint =>
      _pick(const Color(0xFFE2F5EA), const Color(0xFF10291D));
  static Color get warning =>
      _pick(const Color(0xFFC27803), const Color(0xFFEDB14E));
  static Color get warningTint =>
      _pick(const Color(0xFFFDF1DC), const Color(0xFF2E2410));
  static Color get error =>
      _pick(const Color(0xFFC0352A), const Color(0xFFF27D71));
  static Color get errorTint =>
      _pick(const Color(0xFFFCE7E4), const Color(0xFF341816));

  // ── Elevation ───────────────────────────────────────────────────────────
  /// Cards are defined by a hairline border; the shadow only lifts them a
  /// hair off the canvas (none on dark, where borders do the work).
  static List<BoxShadow> get cardShadow => _dark
      ? const []
      : const [
          BoxShadow(
            color: Color(0x0A0E2134),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ];

  /// Menus, sheets and other surfaces that really float.
  static List<BoxShadow> get raisedShadow => _dark
      ? const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x140E2134),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ];
}
