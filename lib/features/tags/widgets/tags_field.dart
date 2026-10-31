import 'package:flutter/material.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/features/tags/widgets/tag_label.dart';

/// Form field showing the [selected] tag names as colored labels; tapping it
/// calls [onTap]. Names not in [tags] (deleted, or "Auto-generated") are grey.
class TagsField extends StatelessWidget {
  final List<Tag> tags;
  final Set<String> selected;
  final VoidCallback onTap;

  const TagsField({
    super.key,
    required this.tags,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unknown = selected.where((name) => !tags.any((t) => t.name == name));
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Tags',
          prefixIcon: Icon(Icons.label_outline),
          suffixIcon: Icon(Icons.arrow_drop_down),
        ),
        isEmpty: selected.isEmpty,
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final tag in tags)
              if (selected.contains(tag.name))
                TagLabel(tag.name, Color(tag.color)),
            for (final name in unknown)
              TagLabel(
                name,
                Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
          ],
        ),
      ),
    );
  }
}
