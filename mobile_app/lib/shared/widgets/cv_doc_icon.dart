import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Small CV document mark: a page with a folded corner, three text lines
/// and a teal "CV" tab. Used on the Profile CV card.
class CvDocIcon extends StatelessWidget {
  const CvDocIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark;
    final paper = dark ? const Color(0xFFE9F0F6) : AppColors.white;
    final rule = dark ? const Color(0xFF9AA8B6) : const Color(0xFFB4C0CC);

    Widget line(double top, double width) => Positioned(
      left: 8,
      top: top,
      child: Container(
        width: width,
        height: 3,
        decoration: BoxDecoration(
          color: rule,
          borderRadius: const BorderRadius.all(Radius.circular(2)),
        ),
      ),
    );

    return ExcludeSemantics(
      child: SizedBox(
        width: 44,
        height: 52,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              right: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: paper,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                  border: dark
                      ? null
                      : Border.all(color: const Color(0xFFDCE3EA)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x14000000), offset: Offset(0, 1)),
                    BoxShadow(
                      color: Color(0x2E000000),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 4,
              child: CustomPaint(
                size: const Size(12, 12),
                painter: _FoldPainter(),
              ),
            ),
            line(14, 20),
            line(21, 24),
            line(28, 16),
            Positioned(
              right: 0,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: const BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                ),
                child: const Text(
                  'CV',
                  style: TextStyle(
                    fontFamily: AppFonts.label,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    letterSpacing: 0.3,
                    height: 1.2,
                    color: Color(0xFF05121A),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(3, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - 3)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFC9D3DD));
  }

  @override
  bool shouldRepaint(_FoldPainter oldDelegate) => false;
}
