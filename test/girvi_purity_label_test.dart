import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/girvi/girvi_enums.dart';

void main() {
  test('gold purity uses KT labels and still reads legacy K values', () {
    expect(MetalPurity.k24.shortLabel, '24KT');
    expect(MetalPurity.k22.shortLabel, '22KT');
    expect(MetalPurity.k20.shortLabel, '20KT');
    expect(MetalPurity.k18.shortLabel, '18KT');
    expect(MetalPurity.k14.shortLabel, '14KT');

    expect(MetalPurity.fromDb('22K'), MetalPurity.k22);
    expect(MetalPurity.fromDb('22KT'), MetalPurity.k22);
    expect(MetalPurity.fromDb('20K'), MetalPurity.k20);
    expect(MetalPurity.fromDb('20KT'), MetalPurity.k20);
  });
}
