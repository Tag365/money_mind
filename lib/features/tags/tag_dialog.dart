import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/tags/widgets/tag_color_picker.dart';

/// Add dialog when [tag] is null, edit dialog otherwise. Pops with the full
/// name ("Parent : Child") and color, or null when cancelled. [tags] are the
/// existing ones, so a name cannot be used twice. [parent] is preselected as
/// a new tag's parent.
///
/// Owns its controller so it is disposed only after the dialog's closing
/// animation, not while the TextField is still on screen.
class TagDialog extends StatefulWidget {
  final Tag? tag;
  final List<Tag> tags;
  final String? parent;

  const TagDialog({
    super.key,
    required this.tag,
    required this.tags,
    this.parent,
  });

  @override
  State<TagDialog> createState() => _TagDialogState();
}

class _TagDialogState extends State<TagDialog> {
  static const _sep = DatabaseService.tagSeparator;
  static const _noParent = '';

  late final String? _ownParent = widget.tag == null
      ? null
      : DatabaseService.tagParent(widget.tag!.name);

  /// The name without its parent.
  late final String _ownName = _ownParent == null
      ? widget.tag?.name ?? ''
      : widget.tag!.name.substring(_ownParent.length + _sep.length);

  late final nameController = TextEditingController(text: _ownName);
  late String parent = _ownParent ?? widget.parent ?? _noParent;
  late Color color = widget.tag == null
      ? _colorOf(widget.parent) ?? tagColors.first
      : Color(widget.tag!.color);
  String? error;

  Color? _colorOf(String? name) {
    for (final t in widget.tags) {
      if (t.name == name) return Color(t.color);
    }
    return null;
  }

  // Only one level nests, so a tag with sub-tags cannot get a parent.
  late final bool _hasChildren =
      widget.tag != null &&
      widget.tags.any((t) => t.name.startsWith('${widget.tag!.name}$_sep'));

  /// The top-level tags, and the tag's own parent even if it no longer exists.
  late final List<String> _parents = {
    for (final t in widget.tags)
      if (DatabaseService.tagParent(t.name) == null && t.id != widget.tag?.id)
        t.name,
    ?_ownParent,
  }.toList();

  void _save() {
    final name = nameController.text.trim();
    if (name.contains(_sep) && name != _ownName) {
      setState(() => error = 'Choose the parent below instead of typing ":"');
      return;
    }
    final fullName = parent == _noParent ? name : '$parent$_sep$name';
    // Case-insensitive like the tag filter (SQL LIKE), so "food" and "Food"
    // never both exist.
    final taken = widget.tags.any(
      (t) =>
          t.name.toLowerCase() == fullName.toLowerCase() &&
          t.id != widget.tag?.id,
    );
    if (name.isEmpty || taken) {
      setState(
        () =>
            error = name.isEmpty ? 'Please enter a name' : 'Tag already exists',
      );
      return;
    }
    Navigator.pop(context, (fullName, color));
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
              errorMaxLines: 2,
              prefixIcon: Icon(Icons.circle, color: color),
            ),
            // Statements store tags comma-joined.
            inputFormatters: [FilteringTextInputFormatter.deny(',')],
          ),
          DropdownMenu<String>(
            expandedInsets: EdgeInsets.zero,
            label: const Text('Parent tag'),
            enabled: !_hasChildren,
            helperText: _hasChildren
                ? 'It has sub-tags, so it cannot have a parent.'
                : null,
            initialSelection: parent,
            dropdownMenuEntries: [
              const DropdownMenuEntry(value: _noParent, label: 'None'),
              for (final name in _parents)
                DropdownMenuEntry(value: name, label: name),
            ],
            onSelected: (selected) => setState(() {
              parent = selected ?? _noParent;
              // A new sub-tag starts with its parent's color.
              if (widget.tag == null) color = _colorOf(parent) ?? color;
            }),
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
