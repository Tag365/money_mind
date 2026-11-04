import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';

/// [tags] as shown nested: the top-level ones and, by the name of their
/// parent, the children ("Auto : Laden"). A child whose parent tag doesn't
/// exist counts as top-level.
({List<Tag> roots, Map<String, List<Tag>> children}) tagTree(List<Tag> tags) {
  final names = {for (final tag in tags) tag.name};
  final roots = <Tag>[];
  final children = <String, List<Tag>>{};
  for (final tag in tags) {
    final parent = DatabaseService.tagParent(tag.name);
    if (parent != null && names.contains(parent)) {
      children.putIfAbsent(parent, () => []).add(tag);
    } else {
      roots.add(tag);
    }
  }
  return (roots: roots, children: children);
}
