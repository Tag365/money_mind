import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/common/money_text.dart';

void main() {
  test('float drift around zero shows as 0,00', () {
    expect(formatMoney(0.3 - 0.1 - 0.2), '0,00 €');
    expect(formatMoney(-12.5), '-12,50 €');
  });

  test('groups thousands with dots', () {
    expect(formatMoney(999.99), '999,99 €');
    expect(formatMoney(1656), '1.656,00 €');
    expect(formatMoney(-1234567.8), '-1.234.567,80 €');
  });
}
