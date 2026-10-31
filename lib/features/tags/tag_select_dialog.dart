import 'package:flutter/material.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/features/tags/manage_tags.dart';
import 'package:money_mind/features/tags/widgets/tag_label.dart';

/// Checkbox list of [tags]. Pops with the selected names, or null when
/// cancelled or when the user goes to Manage tags instead.
class TagSelectDialog extends StatefulWidget {
  final List<Tag> tags;
  final Set<String> selected;

  const TagSelectDialog({
    super.key,
    required this.tags,
    required this.selected,
  });

  @override
  State<TagSelectDialog> createState() => _TagSelectDialogState();
}

class _TagSelectDialogState extends State<TagSelectDialog> {
  late final Set<String> _selection = {...widget.selected};

  void _manageTags() {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(MaterialPageRoute(builder: (_) => const ManageTagsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select tags'),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      content: SizedBox(
        width: double.maxFinite,
        child: widget.tags.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text('No tags yet. Add them in Manage tags.'),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final tag in widget.tags)
                    CheckboxListTile(
                      title: TagLabel(tag.name, Color(tag.color), expand: true),
                      value: _selection.contains(tag.name),
                      onChanged: (checked) => setState(() {
                        checked!
                            ? _selection.add(tag.name)
                            : _selection.remove(tag.name);
                      }),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(onPressed: _manageTags, child: const Text('Manage tags')),
        TextButton(
          onPressed: () => setState(_selection.clear),
          child: const Text('Clear'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selection),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
