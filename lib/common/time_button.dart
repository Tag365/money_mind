import 'package:flutter/material.dart';

/// Shows the time of [date] (14:05) and opens a time picker. Only the time
/// of day changes; the calendar day is kept.
class TimeButton extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const TimeButton(this.date, {super.key, required this.onChanged});

  Future<void> _pick(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(date),
    );
    if (picked == null) return;
    onChanged(
      DateTime(date.year, date.month, date.day, picked.hour, picked.minute),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _pick(context),
      icon: const Icon(Icons.schedule),
      label: Text(
        MaterialLocalizations.of(context).formatTimeOfDay(
          TimeOfDay.fromDateTime(date),
          alwaysUse24HourFormat: true,
        ),
      ),
    );
  }
}
