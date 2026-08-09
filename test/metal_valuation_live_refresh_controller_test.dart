import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/application/metal_valuation_controller.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/application/metal_valuation_grade_controller.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/data/metal_valuation_change_watcher.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/data/metal_valuation_grade_repository.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/data/metal_valuation_repository.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/domain/metal_valuation_grade_models.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/domain/metal_valuation_models.dart';

void main() {
  test('metal valuation controller silently refreshes on live DB changes',
      () async {
    final changes = StreamController<void>.broadcast();
    final repository = _FakeMetalValuationRepository([
      _snapshot(availableUnits: 1),
      _snapshot(availableUnits: 2),
    ]);
    final controller = MetalValuationController(
      repository: repository,
      changeWatcher: _FakeChangeWatcher(changes.stream),
    );

    controller.startLiveRefresh();
    await controller.load();
    expect(controller.snapshot.summary.availableUnits, 1);
    expect(repository.calls, 1);

    changes.add(null);
    await Future<void>.delayed(const Duration(milliseconds: 230));
    expect(repository.calls, 1);

    changes.add(null);
    await Future<void>.delayed(const Duration(milliseconds: 230));
    expect(controller.snapshot.summary.availableUnits, 2);
    expect(repository.calls, 2);

    controller.dispose();
    await changes.close();
  });

  test(
      'metal valuation grade controller refreshes movement cards on DB changes',
      () async {
    final changes = StreamController<void>.broadcast();
    final repository = _FakeMetalValuationGradeRepository([
      _gradeSnapshot(availableQuantity: 49),
      _gradeSnapshot(availableQuantity: 48),
    ]);
    final controller = MetalValuationGradeController(
      metalType: 'Silver',
      repository: repository,
      changeWatcher: _FakeChangeWatcher(changes.stream),
    );

    controller.startLiveRefresh();
    await controller.load();
    expect(
        controller.snapshot.grades.single.availableQuantityLabel, '49 pairs');
    expect(repository.snapshotCalls, 1);

    changes.add(null);
    await Future<void>.delayed(const Duration(milliseconds: 230));
    expect(repository.snapshotCalls, 1);

    changes.add(null);
    await Future<void>.delayed(const Duration(milliseconds: 230));
    expect(
        controller.snapshot.grades.single.availableQuantityLabel, '48 pairs');
    expect(repository.snapshotCalls, 2);

    controller.dispose();
    await changes.close();
  });
}

class _FakeChangeWatcher implements MetalValuationChangeStream {
  final Stream<void> _stream;

  _FakeChangeWatcher(this._stream);

  @override
  Stream<void> watch() => _stream;
}

class _FakeMetalValuationRepository implements MetalValuationSnapshotReader {
  final List<MetalValuationSnapshot> snapshots;
  int calls = 0;

  _FakeMetalValuationRepository(this.snapshots);

  @override
  Future<MetalValuationSnapshot> fetchSnapshot({
    MetalValuationFilter filter = MetalValuationFilter.all,
  }) async {
    final index = calls >= snapshots.length ? snapshots.length - 1 : calls;
    calls += 1;
    return snapshots[index];
  }
}

class _FakeMetalValuationGradeRepository implements MetalValuationGradeReader {
  final List<MetalValuationGradeSnapshot> snapshots;
  int snapshotCalls = 0;

  _FakeMetalValuationGradeRepository(this.snapshots);

  @override
  Future<MetalValuationGradeSnapshot> fetchGradeSnapshot(
    String metalType, {
    String? batchCode,
  }) async {
    final index = snapshotCalls >= snapshots.length
        ? snapshots.length - 1
        : snapshotCalls;
    snapshotCalls += 1;
    return snapshots[index];
  }

  @override
  Future<List<MetalValuationGradeBatchRow>> fetchGradeBatchRows(
    String metalType,
  ) async {
    return const [];
  }
}

MetalValuationSnapshot _snapshot({required int availableUnits}) {
  return MetalValuationSnapshot(
    summary: MetalValuationSummary(
      availableUnits: availableUnits,
      soldUnits: 0,
      availableCost: 0,
      soldCost: 0,
      saleValue: 0,
      profit: 0,
      availableNetWeight: 0,
      availableActualFine: 0,
      availableValuationFine: 0,
      availablePurityPercentValue: 0,
      availableWastagePercent: 0,
      soldNetWeight: 0,
      soldFineWeight: 0,
    ),
    breakdown: const [],
    batchSummaries: const [],
    availableStock: const [],
    soldStock: const [],
  );
}

MetalValuationGradeSnapshot _gradeSnapshot({
  required double availableQuantity,
}) {
  return MetalValuationGradeSnapshot(
    metalType: 'Silver',
    grades: [
      MetalValuationGradeRow(
        gradeLabel: 'Payal',
        availableUnits: 1,
        soldUnits: 1,
        availableQuantity: availableQuantity,
        soldQuantity: 1,
        quantityUnitLabel: 'pair',
        availableNetWeight: 0,
        soldNetWeight: 0,
        availableCost: 0,
        soldCost: 0,
        saleValue: 0,
        profit: 0,
      ),
    ],
  );
}
