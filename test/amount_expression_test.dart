import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/amount_expression.dart';

void main() {
  test('single amounts', () {
    expect(evaluateAmount('12'), 12);
    expect(evaluateAmount('12,50'), 12.5);
    expect(evaluateAmount('12.50'), 12.5);
  });

  test('sums and differences', () {
    expect(evaluateAmount('12,50 + 3,20 + 4'), closeTo(19.7, 1e-9));
    expect(evaluateAmount('10-2,5'), 7.5);
    expect(evaluateAmount('-5+10'), 5);
  });

  test('invalid input', () {
    expect(evaluateAmount(''), isNull);
    expect(evaluateAmount('12+'), isNull);
    expect(evaluateAmount('1++2'), isNull);
    expect(evaluateAmount('abc'), isNull);
    expect(evaluateAmount('1,2,3'), isNull);
  });
}
