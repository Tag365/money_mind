import 'package:flutter/material.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/tags/widgets/tag_label.dart';

/// The tag [names] as labels in their colors, kept up to date with the tags
/// table. Names not in the table (e.g. "Auto-generated") are grey.
class TagLabels extends StatefulWidget {
  final List<String> names;

  const TagLabels(this.names, {super.key});

  @override
  State<TagLabels> createState() => _TagLabelsState();
}

class _TagLabelsState extends State<TagLabels> {
  late final Stream<List<Tag>> _tags = DatabaseService.instance.watchTags();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _tags,
      builder: (context, snapshot) {
        final colors = {
          for (final t in snapshot.data ?? <Tag>[]) t.name: Color(t.color),
        };
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final name in widget.names)
              TagLabel(
                name,
                colors[name] ??
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
          ],
        );
      },
    );
  }
}
