import 'package:flutter/material.dart';
import 'package:money_mind/common/money_text.dart';
import 'package:money_mind/common/share_bar.dart';
import 'package:money_mind/features/analysis/tag_breakdown.dart';

/// [title] with the [total] of a month and how [shares] split it, the
/// largest three named and the rest as "Other". Tapping it calls [onTap].
class BreakdownCard extends StatelessWidget {
  final String title;
  final double total;
  final List<TagShare> shares;
  final Map<String, Color> colors;
  final VoidCallback onTap;

  const BreakdownCard({
    super.key,
    required this.title,
    required this.total,
    required this.shares,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    // Four named fit; with more, the fourth on is merged into "Other".
    final shown = shares.length <= 4
        ? [for (final s in shares) (s.tag, tagColor(colors, s.tag), s.amount)]
        : [
            for (final s in shares.take(3))
              (s.tag, tagColor(colors, s.tag), s.amount),
            (
              null,
              muted.withValues(alpha: 0.5),
              shares.skip(3).fold(0.0, (sum, s) => sum + s.amount),
            ),
          ];
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(color: muted),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: muted),
                ],
              ),
              MoneyText(total),
              ShareBar([
                for (final (_, color, amount) in shown) (color, amount),
              ]),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  for (final (tag, color, _) in shown)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: [
                        Icon(Icons.circle, size: 8, color: color),
                        Text(switch (tag) {
                          null => "Other",
                          untagged => "No tag",
                          _ => tag,
                        }, style: theme.textTheme.bodySmall),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
