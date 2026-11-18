/// Central registry of asset paths. Never type asset strings inline.
abstract final class AssetPaths {
  static const String _brand = 'assets/images/brand';

  /// Official Scale Shark logo (1254×1254) from thescaleshark.io.
  static const String scaleSharkLogo = '$_brand/scale_shark_logo.jpg';

  /// Official 128×128 Scale Shark mark (website favicon) for small sizes.
  static const String scaleSharkMark = '$_brand/scale_shark_mark_128.png';
}
