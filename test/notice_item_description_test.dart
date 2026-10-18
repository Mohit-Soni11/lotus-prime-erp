import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/girvi/notice_pdf/notice_item_description.dart';

void main() {
  test('shows item names and accurate purity without invoice metadata', () {
    const description =
        'Serial Number 1 - Necklace | Gold | 22KT | 1 piece | Net Weight 10.000 g\n'
        'Serial Number 2 - Ring | Gold | 18KT | 1 piece | Net Weight 3.000 g';
    expect(NoticeItemDescription.itemNames(description), 'Necklace, Ring');
    expect(NoticeItemDescription.purity(description),
        '22KT (91.6%), 18KT (75.0%)');
  });

  test('does not invent a percentage for an unknown purity', () {
    expect(NoticeItemDescription.itemNames('#1 ring | Gold | Custom'), 'ring');
    expect(NoticeItemDescription.purity('Plain item', fallback: 'Custom'),
        'Custom');
  });
}
