import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Draws MediaPipe hand landmark skeleton on top of the camera preview.
///
/// [landmarks] — list of normalised (x, y) pairs (0.0–1.0).
///   MediaPipe returns 21 landmarks per hand. Pass flattened as
///   List<Offset> with values normalised to the canvas size.
///
/// When [landmarks] is empty nothing is drawn — the canvas is transparent.
class LandmarkPainter extends CustomPainter {
  final List<Offset> landmarks; // normalised 0..1 → will be scaled
  final Size previewSize;       // camera preview resolution

  static const _connections = [
    // Wrist
    [0, 1],
    // Thumb
    [1, 2],[2, 3],[3, 4],
    // Index
    [0, 5],[5, 6],[6, 7],[7, 8],
    // Middle
    [0, 9],[9, 10],[10, 11],[11, 12],
    // Ring
    [0, 13],[13, 14],[14, 15],[15, 16],
    // Pinky
    [0, 17],[17, 18],[18, 19],[19, 20],
    // Palm connections
    [5, 9],[9, 13],[13, 17],
  ];

  const LandmarkPainter({
    required this.landmarks,
    required this.previewSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.isEmpty) return;

    final linePaint = Paint()
      ..color = AppColors.mint.withOpacity(0.85)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = AppColors.mint
      ..style = PaintingStyle.fill;

    final dotGlowPaint = Paint()
      ..color = AppColors.mint.withOpacity(0.25)
      ..style = PaintingStyle.fill;

    // Scale normalised coords to canvas pixels
    Offset scale(Offset n) => Offset(n.dx * size.width, n.dy * size.height);

    // Draw connections
    for (final conn in _connections) {
      if (conn[0] < landmarks.length && conn[1] < landmarks.length) {
        canvas.drawLine(scale(landmarks[conn[0]]), scale(landmarks[conn[1]]), linePaint);
      }
    }

    // Draw landmark dots
    for (final pt in landmarks) {
      final scaled = scale(pt);
      canvas.drawCircle(scaled, 6.0, dotGlowPaint);
      canvas.drawCircle(scaled, 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(LandmarkPainter oldDelegate) =>
      oldDelegate.landmarks != landmarks;
}
