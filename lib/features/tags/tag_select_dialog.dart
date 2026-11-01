import 'package:flutter/material.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
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

  static const _sep = DatabaseService.tagSeparator;

  /// Children ("Auto : Laden") by the name of their parent tag; a child whose
  /// parent tag doesn't exist is shown as a root with its full name.
  late final Map<String, List<Tag>> _children = () {
    final names = {for (final tag in widget.tags) tag.name};
    final children = <String, List<Tag>>{};
    for (final tag in widget.tags) {
      final i = tag.name.indexOf(_sep);
      if (i > 0 && names.contains(tag.name.substring(0, i))) {
        children.putIfAbsent(tag.name.substring(0, i), () => []).add(tag);
      }
    }
    return children;
  }();

  late final List<Tag> _roots = [
    for (final tag in widget.tags)
      if (!_children.values.any((c) => c.contains(tag))) tag,
  ];

  // Parents start folded, unless one of their children is selected.
  late final Set<String> _expanded = {
    for (final MapEntry(key: parent, value: children) in _children.entries)
      if (children.any((c) => _selection.contains(c.name))) parent,
  };

  Widget _tile(
    Tag tag,
    String label, {
    Widget? secondary,
    bool indent = false,
  }) {
    return CheckboxListTile(
      contentPadding: EdgeInsetsDirectional.only(
        start: indent ? 96 : 16,
        end: 24,
      ),
      secondary: secondary,
      title: TagLabel(label, Color(tag.color), expand: true),
      value: _selection.contains(tag.name),
      onChanged: (checked) => setState(() {
        checked! ? _selection.add(tag.name) : _selection.remove(tag.name);
      }),
    );
  }

  void _manageTags() {
    final navigator = Navigator.of(context);
    navigator.pop();
    showModalBottomSheet(
      isScrollControlled: true,
      showDragHandle: true,
      context: navigator.context,
      builder: (_) => const ManageTagsSheet(),
    );
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
                  for (final tag in _roots) ...[
                    _tile(
                      tag,
                      tag.name,
                      secondary: _children.containsKey(tag.name)
                          ? IconButton(
                              icon: Icon(
                                _expanded.contains(tag.name)
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                              ),
                              onPressed: () => setState(() {
                                _expanded.contains(tag.name)
                                    ? _expanded.remove(tag.name)
                                    : _expanded.add(tag.name);
                              }),
                            )
                          // Lines labels up with those next to an arrow.
                          : _children.isEmpty
                          ? null
                          : const SizedBox(width: 48),
                    ),
                    if (_expanded.contains(tag.name))
                      for (final child in _children[tag.name]!)
                        _tile(
                          child,
                          child.name.substring(tag.name.length + _sep.length),
                          indent: true,
                        ),
                  ],
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
