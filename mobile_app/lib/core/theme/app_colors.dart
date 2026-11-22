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
  static Color get ink => _pick(navy, const Color(0xFFEAF0F6));

  /// Text and icons on an [ink] fill.
  static Color get onInk => _pick(white, const Color(0xFF062030));

  static Color get textPrimary => ink;

  /// Website muted foreground (hsl 208 24% 35%).
  static Color get textSecondary =>
      _pick(const Color(0xFF4A5E72), const Color(0xFFA9B9C9));

  /// Meets WCAG AA (4.5:1) on the surface and the canvas in both themes.
  static Color get textTertiary =>
      _pick(const Color(0xFF5E7082), const Color(0xFF8597AA));

  // ── Accents ─────────────────────────────────────────────────────────────
  /// Main interactive accent (links, focus, selection): the deep brand
  /// teal of the "Hire" wordmark, tuned for 4.5:1 text contrast in both
  /// themes (Signal design).
  static Color get ocean =>
      _pick(const Color(0xFF08707F), const Color(0xFF4BB8C6));

  /// Strong / pressed states of [ocean].
  static Color get oceanDeep =>
      _pick(const Color(0xFF075E6C), const Color(0xFF8AD3DD));

  /// Logo shark body slate – avatars and neutral illustration tones.
  static Color get slate =>
      _pick(const Color(0xFF356891), const Color(0xFF8DB0CF));

  // ── Tints ───────────────────────────────────────────────────────────────
  static Color get oceanTint =>
      _pick(const Color(0xFFE0F4F7), const Color(0xFF0F3340));
  static Color get oceanTintStrong =>
      _pick(const Color(0xFFC4E9EF), const Color(0xFF14475A));
  static Color get cyanTint =>
      _pick(const Color(0xFFE3F6FD), const Color(0xFF10313F));

  // ── Surfaces ────────────────────────────────────────────────────────────
  /// Cards, sheets, bars and inputs.
  static Color get surface => _pick(white, const Color(0xFF111F2D));

  /// App canvas behind cards.
  static Color get canvas =>
      _pick(const Color(0xFFF2F5F8), const Color(0xFF0A1520));

  /// Tinted brand panels (website page background).
  static Color get mist =>
      _pick(const Color(0xFFF0FAFF), const Color(0xFF102233));

  static Color get surfaceSubtle =>
      _pick(const Color(0xFFF7F9FB), const Color(0xFF0E1B28));

  /// Quiet filled areas (neutral chips, placeholders, read rows).
  static Color get surfaceMuted =>
      _pick(const Color(0xFFEEF2F6), const Color(0xFF172839));

  // ── Lines ───────────────────────────────────────────────────────────────
  static Color get border =>
      _pick(const Color(0xFFE0E7EE), const Color(0xFF20334A));
  static Color get borderStrong =>
      _pick(const Color(0xFFC9D5E0), const Color(0xFF2C445C));

  // ── Semantic (status only, never decoration) ────────────────────────────
  static Color get success =>
      _pick(const Color(0xFF0B7A3E), const Color(0xFF49C987));
  static Color get successTint =>
      _pick(const Color(0xFFE3F4EA), const Color(0xFF0F2B1F));
  static Color get warning =>
      _pick(const Color(0xFF9A5B00), const Color(0xFFEDB14E));
  static Color get warningTint =>
      _pick(const Color(0xFFFDF1DC), const Color(0xFF2E2410));
  static Color get error =>
      _pick(const Color(0xFFC0352A), const Color(0xFFF27D71));
  static Color get errorTint =>
      _pick(const Color(0xFFFCE7E4), const Color(0xFF341816));

  // ── Signal: navy bands, FIT blocks, bottom bar ──────────────────────────
  /// Navy header band at the top of the main screens.
  static Color get band => _pick(navy, const Color(0xFF0F2337));
  static Color get bandInk => _pick(white, const Color(0xFFEAF0F6));
  static Color get bandMuted =>
      _pick(const Color(0xFFC3D0DC), const Color(0xFFA9B9C9));
  static Color get bandLine =>
      _pick(const Color(0xFF2A4058), const Color(0xFF22394F));

  /// Raised controls on the band (icon buttons, search field on dark).
  static Color get bandSoft =>
      _pick(const Color(0xFF1A3049), const Color(0xFF18314A));

  /// Soft filled background of secondary buttons (no outline).
  static Color get tonal =>
      _pick(const Color(0xFFE3E9EF), const Color(0xFF1A2B3D));

  /// The "92 % FIT" block on job cards.
  static Color get fit => _pick(navy, const Color(0xFF18314A));
  static Color get fitInk => _pick(white, const Color(0xFFEAF0F6));
  static Color get fitLabel =>
      _pick(const Color(0xFF18ACC3), const Color(0xFF4BB8C6));

  /// Bottom navigation bar.
  static Color get nav => _pick(navy, const Color(0xFF0C1A28));
  static Color get navInk =>
      _pick(const Color(0xFFAFC0D0), const Color(0xFF8597AA));
  static Color get navOn => _pick(white, const Color(0xFFEAF0F6));

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
