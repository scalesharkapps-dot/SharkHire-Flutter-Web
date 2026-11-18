import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/brand_logo.dart';
import '../../../authentication/presentation/providers/session_provider.dart';

/// Branded launch screen: the shark mark rises in, the wordmark follows,
/// then the app continues to Home.
///
/// Later this is where session/onboarding checks will decide the next route.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  late final Animation<double> _markFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.6, curve: Curves.easeOut),
  );
  late final Animation<Offset> _markSlide =
      Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0, 0.7, curve: Curves.easeOutCubic),
        ),
      );
  late final Animation<double> _textFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.35, 1, curve: Curves.easeOut),
  );

  static const double _badgeSize = 132;

  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    // Decode the logo first so it never fades in as an empty circle.
    // Start anyway after 400ms so a slow load can't stall the launch.
    final logoReady = precacheImage(
      SharkMark.providerFor(context, _badgeSize * 0.7),
      context,
    );
    Future.any([
      logoReady,
      Future<void>.delayed(const Duration(milliseconds: 400)),
    ]).whenComplete(() {
      if (!mounted) return;
      _controller.forward();
      // Restore a saved sign-in while the brand animation plays; never wait
      // more than 12 s (a sleeping server must not trap the user here).
      final restored = ProviderScope.containerOf(context, listen: false)
          .read(sessionProvider.notifier)
          .restore()
          .timeout(const Duration(seconds: 12), onTimeout: () {});
      _timer = Timer(AppDurations.splash, () async {
        await restored;
        if (mounted) context.go(AppRoutes.home);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                const Spacer(flex: 5),
                FadeTransition(
                  opacity: _markFade,
                  child: SlideTransition(
                    position: _markSlide,
                    child: const SharkBadge(size: _badgeSize),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                FadeTransition(
                  opacity: _textFade,
                  child: Column(
                    children: [
                      const SharkHireWordmark(fontSize: 38, onDark: true),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Upload your CV. Get matched.\nFind your next job.',
                        textAlign: TextAlign.center,
                        style: text.bodyLarge?.copyWith(
                          color: AppColors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 6),
                FadeTransition(
                  opacity: _textFade,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                    child: Text(
                      'by ${AppConstants.companyName}'.toUpperCase(),
                      style: text.labelSmall?.copyWith(
                        color: AppColors.white.withValues(alpha: 0.5),
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
