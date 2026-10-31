import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/features/tags/widgets/tag_color_picker.dart';

/// Add dialog when [tag] is null, edit dialog otherwise. Pops with the name
/// and color, or null when cancelled. [tags] are the existing ones, so a
/// name cannot be used twice.
///
/// Owns its controller so it is disposed only after the dialog's closing
/// animation, not while the TextField is still on screen.
class TagDialog extends StatefulWidget {
  final Tag? tag;
  final List<Tag> tags;

  const TagDialog({super.key, required this.tag, required this.tags});

  @override
  State<TagDialog> createState() => _TagDialogState();
}

class _TagDialogState extends State<TagDialog> {
  late final nameController = TextEditingController(text: widget.tag?.name);
  late Color color = widget.tag == null
      ? tagColors.first
      : Color(widget.tag!.color);
  String? error;

  void _save() {
    final name = nameController.text.trim();
    // Case-insensitive like the tag filter (SQL LIKE), so "food" and "Food"
    // never both exist.
    final taken = widget.tags.any(
      (t) =>
          t.name.toLowerCase() == name.toLowerCase() && t.id != widget.tag?.id,
    );
    if (name.isEmpty || taken) {
      setState(
        () =>
            error = name.isEmpty ? 'Please enter a name' : 'Tag already exists',
      );
      return;
    }
    Navigator.pop(context, (name, color));
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.tag == null ? 'Add tag' : 'Edit tag'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Name',
              errorText: error,
              prefixIcon: Icon(Icons.circle, color: color),
            ),
            // Statements store tags comma-joined.
            inputFormatters: [FilteringTextInputFormatter.deny(',')],
          ),
          TagColorPicker(
            selected: color,
            onChanged: (c) => setState(() => color = c),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
