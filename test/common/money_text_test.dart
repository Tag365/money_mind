import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/common/money_text.dart';

void main() {
  test('float drift around zero shows as 0.00', () {
    expect(formatMoney(0.3 - 0.1 - 0.2), '0.00 €');
    expect(formatMoney(-12.5), '-12.50 €');
  });
}
