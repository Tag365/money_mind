import 'package:flutter/material.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/features/tags/widgets/tag_labels.dart';

/// The dropdown of earlier statements below the Create form's title field:
/// each title with its tags, on a card like the rest of the form.
class TitleSuggestions extends StatelessWidget {
  final Iterable<Statement> options;
  final ValueChanged<Statement> onSelected;

  const TitleSuggestions({
    super.key,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: Card(
        margin: const EdgeInsets.only(top: 4),
        elevation: 6,
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 4),
            shrinkWrap: true,
            children: [
              for (final s in options)
                ListTile(
                  onTap: () => onSelected(s),
                  leading: const Icon(Icons.history),
                  title: Text(s.title, overflow: TextOverflow.ellipsis),
                  subtitle: s.tags.isEmpty
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: TagLabels(s.tags),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
