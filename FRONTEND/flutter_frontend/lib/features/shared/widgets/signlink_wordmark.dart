import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// "SIGN" in white + "LINK" in mint — always the same,
/// size is configurable.
class SignLinkWordmark extends StatelessWidget {
  final double size;
  final bool showIcon;

  const SignLinkWordmark({
    super.key,
    this.size = 20,
    this.showIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showIcon) ...[
          _SmallHandIcon(size: size * 1.1),
          const SizedBox(width: 6),
        ],
        Text(
          'SIGN',
          style: AppTextStyles.wordmarkBase(context, size: size),
        ),
        Text(
          'LINK',
          style: AppTextStyles.wordmarkAccent(context, size: size),
        ),
      ],
    );
  }
}

class _SmallHandIcon extends StatelessWidget {
  final double size;
  const _SmallHandIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MiniHandPainter()),
    );
  }
}

class _MiniHandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.mint
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    final path = Path();
    final fingerW = w * 0.22;
    final fingerX = w * 0.5 - fingerW / 2;
    path.addRRect(RRect.fromLTRBR(
      fingerX, h * 0.05, fingerX + fingerW, h * 0.55,
      Radius.circular(fingerW / 2),
    ));
    path.moveTo(w * 0.1, h * 0.52);
    path.quadraticBezierTo(w * 0.1, h * 0.95, w * 0.5, h * 0.95);
    path.quadraticBezierTo(w * 0.9, h * 0.95, w * 0.9, h * 0.52);
    path.lineTo(w * 0.1, h * 0.52);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
