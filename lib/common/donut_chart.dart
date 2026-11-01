import 'dart:math';

import 'package:flutter/material.dart';

/// A ring split into rounded arcs, each as long as its share of the sum of
/// [shares], clockwise from the top, with [center] inside. An empty grey ring
/// when there is nothing to show.
class DonutChart extends StatelessWidget {
  final List<(Color, double)> shares;
  final Widget? center;

  const DonutChart(this.shares, {super.key, this.center});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 220,
      child: CustomPaint(
        painter: _DonutPainter(
          shares,
          Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Center(child: center),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<(Color, double)> shares;
  final Color empty;

  _DonutPainter(this.shares, this.empty);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 18.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final radius = rect.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final sum = shares.fold(0.0, (s, e) => s + e.$2.abs());
    if (sum == 0 || shares.length == 1) {
      paint.color = sum == 0 ? empty : shares.single.$1;
      canvas.drawCircle(rect.center, radius, paint);
      return;
    }
    // Round caps reach half the stroke past each end; leave room for both
    // plus a visible gap.
    final gap = (stroke + 6) / radius;
    var start = -pi / 2;
    for (final (color, value) in shares) {
      final sweep = value.abs() / sum * 2 * pi;
      paint.color = color;
      // A share smaller than the gap still shows as a dot.
      canvas.drawArc(
        rect,
        start + gap / 2,
        max(sweep - gap, 0.001),
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.shares != shares || old.empty != empty;
}
