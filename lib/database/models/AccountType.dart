import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
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
