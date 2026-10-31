import 'package:flutter/material.dart';
import 'package:money_mind/features/tags/tag_dialog.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';

/// Bottom sheet listing all tags; tap one to edit it, + to add one.
class ManageTagsSheet extends StatefulWidget {
  const ManageTagsSheet({super.key});

  @override
  State<ManageTagsSheet> createState() => _ManageTagsSheetState();
}

class _ManageTagsSheetState extends State<ManageTagsSheet> {
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          // Same insets as ListTile, so + lines up with the delete icons.
          padding: const EdgeInsetsDirectional.only(start: 16, end: 24),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Manage tags',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                tooltip: 'Add tag',
                onPressed: () => _edit(null),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        Flexible(
          child: StreamBuilder<List<Tag>>(
            stream: _tags,
            builder: (context, snapshot) {
              tags = snapshot.data ?? [];
              if (tags.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Text('No tags yet.'),
                );
              }
              return ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 16),
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
        ),
      ],
    );
  }
}
