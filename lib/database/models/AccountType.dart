import 'dart:collection';

import 'package:flutter/material.dart';

enum AccountType {
  debit("Debit"),
  creditCard("Credit card");

  const AccountType(this.displayName);

  final String displayName;

  static final List<DropdownMenuEntry<AccountType>> entries =
      UnmodifiableListView<DropdownMenuEntry<AccountType>>(
        values
            .map(
              (e) => DropdownMenuEntry<AccountType>(
                value: e,
                label: e.displayName,
              ),
            )
            .toList(),
      );
}
