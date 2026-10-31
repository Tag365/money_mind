import 'package:flutter/material.dart';

import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/models/recurrences.dart';

/// "Every month", "Every 2 weeks", ...
String describeInterval(RecurrenceUnit unit, int every) {
  final name = unit.displayName.toLowerCase();
  return every == 1 ? 'Every $name' : 'Every $every ${name}s';
}

/// Picks how a statement repeats: [onSave] gets the chosen interval and
/// [onTurnOff], offered while [recurrence] is set, stops it. [from] is the
/// payment date a new interval counts from: that of the newest statement of
/// the series (see `DatabaseService.latestInSeries`).
class RecurrenceDialog extends StatefulWidget {
  final DateTime from;
  final Recurrence? recurrence;
  final Future<void> Function(RecurrenceUnit unit, int every, bool ahead)
  onSave;
  final Future<void> Function() onTurnOff;

  const RecurrenceDialog({
    super.key,
    required this.from,
    required this.recurrence,
    required this.onSave,
    required this.onTurnOff,
  });

  @override
  State<RecurrenceDialog> createState() => _RecurrenceDialogState();
}

class _RecurrenceDialogState extends State<RecurrenceDialog> {
  late RecurrenceUnit _unit = widget.recurrence?.unit ?? RecurrenceUnit.month;
  late bool _ahead = widget.recurrence?.ahead ?? false;
  late final _every = TextEditingController(
    text: '${widget.recurrence?.every ?? 1}',
  );

  int? get _parsedEvery {
    final every = int.tryParse(_every.text.trim());
    return every != null && every > 0 ? every : null;
  }

  /// Mirrors `DatabaseService.setRecurrence`: an unchanged interval keeps its
  /// schedule, a new one counts from the newest statement.
  DateTime _next(int every) {
    final r = widget.recurrence;
    if (r != null && r.unit == _unit && r.every == every) {
      return r.unit.occurrence(r.start, r.every, r.generated);
    }
    return _unit.occurrence(widget.from, every, 1);
  }

  // Set for good: the dialog closes after saving. A second tap would save
  // again with stale data and could start a second series.
  bool _saving = false;

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    await widget.onSave(_unit, _parsedEvery!, _ahead);
    navigator.pop();
  }

  Future<void> _turnOff() async {
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    await widget.onTurnOff();
    navigator.pop();
  }

  @override
  void dispose() {
    _every.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final every = _parsedEvery;
    return AlertDialog(
      title: const Text('Recurring statement'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This statement will be repeated every'),
          const SizedBox(height: 16),
          Row(
            spacing: 8,
            children: [
              SizedBox(
                width: 72,
                child: TextField(
                  controller: _every,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Count',
                    errorText: every == null ? 'Min. 1' : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Expanded(
                child: DropdownMenu<RecurrenceUnit>(
                  initialSelection: _unit,
                  expandedInsets: EdgeInsets.zero,
                  label: const Text('Unit'),
                  dropdownMenuEntries: [
                    for (final unit in RecurrenceUnit.values)
                      DropdownMenuEntry(value: unit, label: unit.displayName),
                  ],
                  onSelected: (unit) => setState(() => _unit = unit ?? _unit),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (every != null)
            Text(
              'Next statement is due '
              '${_next(every).toIso8601String().substring(0, 10)}',
            ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _ahead,
            onChanged: (value) => setState(() => _ahead = value!),
            title: const Text('Add the next statement up to a month ahead'),
          ),
        ],
      ),
      actions: [
        if (widget.recurrence != null)
          TextButton(
            onPressed: _saving ? null : _turnOff,
            child: const Text('Turn off'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: every == null || _saving ? null : _save,
          child: const Text('OK'),
        ),
      ],
    );
  }
}
