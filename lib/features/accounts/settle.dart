import 'dart:math';

import 'package:flutter/material.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/accounts/transfer_form.dart';

/// Start of the day after the newest closing day on or before [now], i.e.
/// the end of the last billing period that has closed. A [closingDay] of
/// null, or past the end of a month, means that month's last day.
DateTime lastPeriodEnd(int? closingDay, DateTime now) {
  DateTime end(int year, int month) {
    final days = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, min(closingDay ?? days, days) + 1);
  }

  final thisMonth = end(now.year, now.month);
  return thisMonth.isAfter(now) ? end(now.year, now.month - 1) : thisMonth;
}

/// Opens the transfer sheet to settle credit card [card] from one of the
/// other [open] accounts: the one that settled it last, and the amount owed
/// for the last closed billing period.
Future<void> settleCard(
  BuildContext context,
  Account card,
  List<Account> open,
) async {
  final service = DatabaseService.instance;
  final periodEnd = lastPeriodEnd(card.closingDay, DateTime.now());
  final due = await service.amountDue(card.id, periodEnd);
  final sourceId = await service.lastTransferSource(card.id);
  final others = [
    for (final a in open)
      if (a.id != card.id) a,
  ];
  if (!context.mounted || others.isEmpty) return;
  final closed = periodEnd.subtract(const Duration(days: 1));
  showModalBottomSheet(
    isScrollControlled: true,
    showDragHandle: true,
    context: context,
    builder: (context) => TransferForm(
      accounts: open,
      from: others.firstWhere(
        (a) => a.id == sourceId,
        orElse: () => others.first,
      ),
      to: card,
      amount: due > 0 ? due : null,
      title: 'Settle ${card.name}',
      amountHelper:
          'Owed when it closed on '
          '${MaterialLocalizations.of(context).formatMediumDate(closed)}',
    ),
  );
}
