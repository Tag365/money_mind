import 'package:flutter/material.dart';
import 'package:money_mind/common/glass_background.dart';
import 'package:money_mind/common/money_text.dart';
import 'package:money_mind/common/share_bar.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/analysis/tag_breakdown.dart';
import 'package:money_mind/features/statements/statement_filter.dart';
import 'package:money_mind/features/statements/statement_list.dart';

/// Expenses (or income) of [month] per top-level tag, or with [parent] per
/// tag of that family. A tag with children opens their breakdown, any other
/// its statements.
class TagBreakdownPage extends StatefulWidget {
  final DateTime month;
  final bool income;
  final String? parent;

  const TagBreakdownPage({
    super.key,
    required this.month,
    required this.income,
    this.parent,
  });

  @override
  State<TagBreakdownPage> createState() => _TagBreakdownPageState();
}

class _TagBreakdownPageState extends State<TagBreakdownPage> {
  late final Stream<List<TagTotal>> _totals = DatabaseService.instance
      .watchTagTotals(
        widget.month,
        DateTime(widget.month.year, widget.month.month + 1),
      );
  late final Stream<List<Tag>> _tags = DatabaseService.instance.watchTags();

  void _open(List<TagTotal> totals, String tag) {
    final children = tagBreakdown(
      totals,
      income: widget.income,
      parent: tag,
    ).shares;
    final Widget page;
    if (widget.parent == null &&
        tag != untagged &&
        (children.length > 1 || children.single.tag != tag)) {
      page = TagBreakdownPage(
        month: widget.month,
        income: widget.income,
        parent: tag,
      );
    } else {
      page = ListWidget(
        title: tag == untagged ? "No tag" : tag,
        month: widget.month,
        filter: StatementFilter(
          tags: {tag},
          // The parent's own row is without its children, listed beside it.
          childTags: tag != widget.parent,
          transfers: false,
          income: widget.income,
          expense: !widget.income,
        ),
      );
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  String _label(String tag) {
    if (tag == untagged) return "No tag";
    final prefix = '${widget.parent}${DatabaseService.tagSeparator}';
    return tag.startsWith(prefix) ? tag.substring(prefix.length) : tag;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassBackground(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.parent ?? (widget.income ? "Income" : "Expenses")),
        ),
        body: StreamBuilder(
          stream: _tags,
          builder: (context, tagsSnapshot) => StreamBuilder(
            stream: _totals,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final colors = tagColors(tagsSnapshot.data ?? const []);
              final (:total, :shares) = tagBreakdown(
                snapshot.data!,
                income: widget.income,
                parent: widget.parent,
              );
              final parentColor = tagColor(colors, widget.parent ?? untagged);
              Color colorAt(int i) {
                final color = tagColor(colors, shares[i].tag);
                // Imported children share their parent's color; lighten them
                // by rank so the bar still shows the split.
                if (widget.parent == null || color != parentColor) return color;
                return Color.lerp(
                  color,
                  Colors.white,
                  (i * 0.15).clamp(0, 0.6),
                )!;
              }

              return ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: [
                        Text(
                          MaterialLocalizations.of(
                            context,
                          ).formatMonthYear(widget.month),
                          style: text.titleMedium,
                        ),
                        MoneyText(total, style: text.headlineSmall),
                        ShareBar([
                          for (final (i, s) in shares.indexed)
                            (colorAt(i), s.amount),
                        ]),
                      ],
                    ),
                  ),
                  if (shares.isEmpty)
                    const Center(child: Text("Nothing this month.")),
                  for (final (i, s) in shares.indexed)
                    ListTile(
                      leading: Icon(Icons.circle, size: 12, color: colorAt(i)),
                      title: Text(_label(s.tag)),
                      subtitle: Text("${(s.amount / total * 100).round()} %"),
                      trailing: MoneyText(s.amount),
                      onTap: () => _open(snapshot.data!, s.tag),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
