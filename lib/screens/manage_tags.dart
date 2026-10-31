import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:money_mind/components/tag_color_picker.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';

class ManageTagsScreen extends StatefulWidget {
  const ManageTagsScreen({super.key});

  @override
  State<ManageTagsScreen> createState() => _ManageTagsScreenState();
}

class _ManageTagsScreenState extends State<ManageTagsScreen> {
  DatabaseService databaseService = DatabaseService.instance;
  late final Stream<List<Tag>> _tags = databaseService.watchTags();
  List<Tag> tags = [];

  /// Add dialog when [tag] is null, edit dialog otherwise.
  Future<void> _edit(Tag? tag) async {
    final result = await showDialog<(String, Color)>(
      context: context,
      builder: (_) => _TagDialog(tag: tag, tags: tags),
    );
    if (result == null) return;
    final (name, color) = result;
    if (tag == null) {
      await databaseService.addTag(name, color.toARGB32());
    } else {
      await databaseService.updateTag(tag, name, color.toARGB32());
    }
  }

  Future<void> _delete(Tag tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${tag.name}"?'),
        content: const Text('The tag is removed from all statements.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await databaseService.deleteTag(tag);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage tags')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add tag',
        onPressed: () => _edit(null),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Tag>>(
        stream: _tags,
        builder: (context, snapshot) {
          tags = snapshot.data ?? [];
          if (tags.isEmpty) {
            return const Center(child: Text('No tags yet.'));
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              for (final tag in tags)
                ListTile(
                  leading: Icon(Icons.label, color: Color(tag.color)),
                  title: Text(tag.name),
                  onTap: () => _edit(tag),
                  trailing: IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(tag),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Owns its controller so it is disposed only after the dialog's closing
/// animation, not while the TextField is still on screen.
class _TagDialog extends StatefulWidget {
  final Tag? tag;
  final List<Tag> tags;

  const _TagDialog({required this.tag, required this.tags});

  @override
  State<_TagDialog> createState() => _TagDialogState();
}

class _TagDialogState extends State<_TagDialog> {
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
