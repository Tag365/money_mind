import 'package:flutter/material.dart';

/// A bar split into rounded segments, each as wide as its share of the sum of
/// [shares]. An empty grey track when there is nothing to show.
class ShareBar extends StatelessWidget {
  final List<(Color, double)> shares;

  const ShareBar(this.shares, {super.key});

  @override
  Widget build(BuildContext context) {
    final sum = shares.fold(0.0, (s, e) => s + e.$2.abs());
    Widget segment(Color color, {int flex = 1}) => Expanded(
      flex: flex,
      child: Container(
        height: 8,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
    return Row(
      spacing: 3,
      children: [
        if (sum == 0)
          segment(Theme.of(context).colorScheme.surfaceContainerHighest)
        else
          for (final (color, value) in shares)
            // At least 1, so a tiny share still shows as a sliver.
            segment(color, flex: (value.abs() / sum * 1000).round() + 1),
      ],
    );
  }
}
