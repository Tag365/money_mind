// A number may leave out the leading 0: ",21" is 0,21.
const _number = r'(\d+(\.\d+)?|\.\d+)';
final _expression = RegExp('^[+-]?$_number([+-]$_number)*\$');
final _term = RegExp('[+-]?$_number');

/// Sum of an amount like "12,50 + 3.2 - 1", or null if it is not valid.
/// Accepts comma or dot as decimal separator.
double? evaluateAmount(String input) {
  final text = input.replaceAll(',', '.').replaceAll(' ', '');
  if (!_expression.hasMatch(text)) return null;
  return _term
      .allMatches(text)
      .map((m) => double.parse(m.group(0)!))
      .fold<double>(0, (sum, term) => sum + term);
}
