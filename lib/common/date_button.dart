import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Shows the day of [date] (Oct 31, 2026) and opens a date picker. Only the
/// calendar day changes; the time of day is kept.
class DateButton extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const DateButton(this.date, {super.key, required this.onChanged});

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Localizations.override(
        context: context,
        delegates: const [_MondayFirstLocalizations.delegate],
        child: child,
      ),
    );
    if (picked == null) return;
    onChanged(
      DateTime(picked.year, picked.month, picked.day, date.hour, date.minute),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _pick(context),
      icon: const Icon(Icons.calendar_today),
      label: Text(MaterialLocalizations.of(context).formatShortDate(date)),
    );
  }
}

/// The app's English localizations, but weeks start on Monday (German usage).
class _MondayFirstLocalizations extends DefaultMaterialLocalizations {
  const _MondayFirstLocalizations();

  static const LocalizationsDelegate<MaterialLocalizations> delegate =
      _MondayFirstDelegate();

  @override
  int get firstDayOfWeekIndex => 1;
}

class _MondayFirstDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _MondayFirstDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture(const _MondayFirstLocalizations());

  @override
  bool shouldReload(_MondayFirstDelegate old) => false;
}
