import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/sales_pos/application/services/pos_invoice_preview_cache.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart';

void main() {
  test('reuses a ready metal preview until the invoice changes', () async {
    final cache = PosInvoicePreviewCache();
    var builds = 0;
    Future<Uint8List> build() async {
      builds++;
      return Uint8List.fromList([builds]);
    }

    final first = await cache.load(MetalType.gold, build);
    expect(await cache.load(MetalType.gold, build), same(first));
    expect(builds, 1);

    cache.invalidate();
    expect(await cache.load(MetalType.gold, build), isNot(same(first)));
    expect(builds, 2);
  });

  test('shares an in-flight build and discards stale completion', () async {
    final cache = PosInvoicePreviewCache();
    final pending = Completer<Uint8List>();
    var builds = 0;
    Future<Uint8List> build() {
      builds++;
      return pending.future;
    }

    final first = cache.load(MetalType.silver, build);
    final second = cache.load(MetalType.silver, build);
    expect(builds, 1);
    cache.invalidate();
    pending.complete(Uint8List.fromList([1]));
    await Future.wait([first, second]);

    final current = await cache.load(
      MetalType.silver,
      () async => Uint8List.fromList([2]),
    );
    expect(current, [2]);
  });
}
