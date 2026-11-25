import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_metal_weight.dart';

void main() {
  test('metal weights preserve gram precision when displayed in kilograms', () {
    expect(dayBookMetalWeight(999.999), '999.999 g');
    expect(dayBookMetalWeight(1000), '1.000 kg');
    expect(dayBookMetalWeight(1000.123), '1.000123 kg');
    expect(dayBookMetalWeight(1250.5), '1.2505 kg');
  });
}
