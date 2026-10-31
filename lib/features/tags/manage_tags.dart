import 'package:flutter/material.dart';
import 'package:money_mind/features/tags/tag_dialog.dart';
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
      builder: (_) => TagDialog(tag: tag, tags: tags),
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
