import 'dart:collection';

import 'package:flutter/material.dart';

enum GroupingOption {
  none("No grouping"),
  monthly("Monthly"),
  yearly("Yearly");

  final String displayName;

  const GroupingOption(this.displayName);

  static final List<DropdownMenuEntry<GroupingOption>> entries =
      UnmodifiableListView<DropdownMenuEntry<GroupingOption>>(
        values
            .map(
              (e) => DropdownMenuEntry<GroupingOption>(
                value: e,
                label: e.displayName,
              ),
            )
            .toList(),
      );
}
