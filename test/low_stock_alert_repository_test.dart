import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/application/low_stock_alert_controller.dart';
import 'package:lotus_erp/features/stock/shared/data/repositories/low_stock_alert_repository.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/low_stock_alert/low_stock_alert_models.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart'
    as stock;

void main() {
  late AppDatabase database;
  late LowStockAlertRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = LowStockAlertRepository(database);
  });

  tearDown(() => database.close());

  test('dashboard uses auto stock history and flags critical low stock',
      () async {
    final now = DateTime.now();
    final stockItemId = await _insertStockItem(
      database,
      sku: 'LJ-GOLD-LOW-001',
      itemName: 'Gold Ring',
      subCategory: 'Ring',
      metal: 'Gold',
      createdAt: now,
    );
    for (var index = 1; index <= 10; index++) {
      await _insertStockUnit(
        database,
        stockItemId: stockItemId,
        unitCode: 'UNIT-GOLD-LOW-${index.toString().padLeft(3, '0')}',
        metal: 'Gold',
        itemType: 'Ring',
        itemName: 'Gold Ring',
        netWeight: 7.5,
        status: index <= 2
            ? stock.StockStatus.available.label
            : stock.StockStatus.sold.label,
        createdAt: now,
      );
    }

    final dashboard = await repository.loadDashboard();

    expect(dashboard.rules, isEmpty);
    expect(dashboard.summary.watchedGroups, 1);
    expect(dashboard.summary.availableUnits, 2);
    expect(dashboard.metalCards, hasLength(1));
    expect(dashboard.gradeCards, hasLength(1));
    expect(dashboard.itemGroupCards, hasLength(1));
    expect(dashboard.itemTypeCards, hasLength(1));

    final gold = dashboard.itemTypeCards.firstWhere(
      (card) => card.metalType == 'Gold',
    );
    expect(gold.ruleMode, LowStockRuleMode.auto);
    expect(gold.availableUnits, 2);
    expect(gold.totalUnits, 10);
    expect(gold.soldUnits, 8);
    expect(gold.riskLevel, LowStockRiskLevel.critical);
    expect(gold.criticalUnits, 3);
    expect(gold.thresholdUnits, 5);
    expect(gold.targetUnits, 10);
    expect(gold.suggestedReorderUnits, 8);
  });

  test('silver item type card combines the same item across grades', () async {
    final now = DateTime.now();
    final firstItemId = await _insertStockItem(
      database,
      sku: 'LJ-SIL-PAYAL-001',
      itemName: 'Dulhan Payal',
      subCategory: 'Payal',
      metal: 'Silver',
      createdAt: now,
    );
    final secondItemId = await _insertStockItem(
      database,
      sku: 'LJ-SIL-PAYAL-002',
      itemName: 'Fancy Payal',
      subCategory: 'Payal',
      metal: 'Silver',
      createdAt: now,
    );
    await _insertStockUnit(
      database,
      stockItemId: firstItemId,
      unitCode: 'UNIT-SIL-PAYAL-001',
      metal: 'Silver',
      itemType: 'Payal',
      itemName: 'Dulhan Payal',
      netWeight: 200,
      purityPercent: 925,
      createdAt: now,
    );
    await _insertStockUnit(
      database,
      stockItemId: secondItemId,
      unitCode: 'UNIT-SIL-PAYAL-002',
      metal: 'Silver',
      itemType: 'Payal',
      itemName: 'Fancy Payal',
      netWeight: 150,
      purityPercent: 800,
      status: stock.StockStatus.sold.label,
      createdAt: now,
    );

    final dashboard = await repository.loadDashboard();

    expect(dashboard.rules, isEmpty);
    expect(dashboard.metalCards, hasLength(1));
    expect(dashboard.itemGroupCards, hasLength(1));

    final payal = dashboard.itemGroupCards.single;
    expect(payal.metalType, 'Silver');
    expect(payal.itemType, 'Payal');
    expect(payal.unitLabel, 'pair');
    expect(payal.totalUnits, 2);
    expect(payal.availableUnits, 1);
    expect(payal.soldUnits, 1);

    final silverDetails = dashboard.itemTypeCards
        .where((card) => card.metalType == 'Silver' && card.itemType == 'Payal')
        .toList(growable: false);
    expect(silverDetails, hasLength(2));
  });

  test('item type cards merge duplicate casing in the same grade', () async {
    final now = DateTime.now();
    final firstItemId = await _insertStockItem(
      database,
      sku: 'LJ-GOLD-CHAIN-CASE-001',
      itemName: 'Gold Chain Upper',
      subCategory: 'Chain',
      metal: 'Gold',
      createdAt: now,
    );
    final secondItemId = await _insertStockItem(
      database,
      sku: 'LJ-GOLD-CHAIN-CASE-002',
      itemName: 'Gold Chain Lower',
      subCategory: 'chain',
      metal: 'Gold',
      createdAt: now,
    );
    await _insertStockUnit(
      database,
      stockItemId: firstItemId,
      unitCode: 'UNIT-GOLD-CHAIN-CASE-001',
      metal: 'Gold',
      itemType: 'Chain',
      itemName: 'Gold Chain Upper',
      netWeight: 18,
      purityPercent: 91.6,
      createdAt: now,
    );
    await _insertStockUnit(
      database,
      stockItemId: secondItemId,
      unitCode: 'UNIT-GOLD-CHAIN-CASE-002',
      metal: 'Gold',
      itemType: 'chain',
      itemName: 'Gold Chain Lower',
      netWeight: 15,
      purityPercent: 91.6,
      createdAt: now,
    );

    final dashboard = await repository.loadDashboard();

    expect(dashboard.gradeCards, hasLength(1));
    expect(dashboard.itemTypeCards, hasLength(1));
    expect(dashboard.itemTypeCards.single.itemType, 'Chain');
    expect(dashboard.itemTypeCards.single.totalUnits, 2);
    expect(dashboard.itemTypeCards.single.availableUnits, 2);
    expect(dashboard.itemTypeCards.single.totalNetWeight, 33);

    final controller = LowStockAlertController(repository);
    await controller.load();

    expect(controller.autoRuleMetalCards, hasLength(1));
    expect(controller.alertMetalCards, isEmpty);
  });

  test('smart alert cards include only low stock items', () async {
    final now = DateTime.now();
    final lowRingId = await _insertStockItem(
      database,
      sku: 'LJ-GOLD-ALERT-RING-001',
      itemName: 'Low Ring',
      subCategory: 'Ring',
      metal: 'Gold',
      createdAt: now,
    );
    final healthyChainId = await _insertStockItem(
      database,
      sku: 'LJ-GOLD-ALERT-CHAIN-001',
      itemName: 'Healthy Chain',
      subCategory: 'Chain',
      metal: 'Gold',
      createdAt: now,
    );

    for (var index = 1; index <= 10; index++) {
      await _insertStockUnit(
        database,
        stockItemId: lowRingId,
        unitCode: 'UNIT-GOLD-ALERT-RING-${index.toString().padLeft(3, '0')}',
        metal: 'Gold',
        itemType: 'Ring',
        itemName: 'Low Ring',
        netWeight: 5,
        status: index <= 2
            ? stock.StockStatus.available.label
            : stock.StockStatus.sold.label,
        createdAt: now,
      );
    }
    for (var index = 1; index <= 4; index++) {
      await _insertStockUnit(
        database,
        stockItemId: healthyChainId,
        unitCode: 'UNIT-GOLD-ALERT-CHAIN-${index.toString().padLeft(3, '0')}',
        metal: 'Gold',
        itemType: 'Chain',
        itemName: 'Healthy Chain',
        netWeight: 8,
        createdAt: now,
      );
    }

    final controller = LowStockAlertController(repository);
    await controller.load();

    expect(controller.autoRuleMetalCards, hasLength(1));
    expect(controller.dashboard.itemTypeCards, hasLength(2));

    final alertMetal = controller.alertMetalCards.single;
    expect(alertMetal.metalType, 'Gold');
    expect(alertMetal.availableUnits, 2);
    expect(alertMetal.soldUnits, 8);
    expect(alertMetal.riskLevel, LowStockRiskLevel.critical);

    final alertGrade = controller.alertGroupCardsForMetal('Gold').single;
    final alertItems = controller.alertDetailCardsForGroup(alertGrade);

    expect(alertItems, hasLength(1));
    expect(alertItems.single.itemType, 'Ring');
    expect(alertItems.single.requiresAction, isTrue);
  });

  test('rule studio counts lot stock by inventory quantity', () async {
    final now = DateTime.now();
    final stockItemId = await _insertStockItem(
      database,
      sku: 'LJ-SIL-LOT-PAYAL-001',
      itemName: 'Lot Payal',
      subCategory: 'Payal',
      metal: 'Silver',
      quantity: 50,
      createdAt: now,
    );
    await _insertStockUnit(
      database,
      stockItemId: stockItemId,
      unitCode: 'UNIT-SIL-LOT-PAYAL-001-LOT',
      metal: 'Silver',
      itemType: 'Payal',
      itemName: 'Lot Payal',
      netWeight: 500,
      purityPercent: 925,
      createdAt: now,
    );

    final controller = LowStockAlertController(repository);
    await controller.load();

    expect(controller.inventoryRuleMetalCards.single.availableUnits, 50);
    expect(controller.inventoryRuleMetalCards.single.totalUnits, 50);
    expect(controller.inventoryRuleGroupCardsForMetal('Silver').single.itemType,
        'Payal');
    expect(
        controller.inventoryRuleGroupCardsForMetal('Silver').single.unitLabel,
        'pair');
    expect(
        controller
            .inventoryRuleGroupCardsForMetal('Silver')
            .single
            .availableUnits,
        50);
    expect(controller.alertMetalCards, isEmpty);
  });

  test('gold rule cards use jewellery unit labels', () async {
    final now = DateTime.now();
    final jhumkaId = await _insertStockItem(
      database,
      sku: 'LJ-GOLD-JHUMKA-UNIT-001',
      itemName: 'Gold Jhumka',
      subCategory: 'Jhumka',
      metal: 'Gold',
      createdAt: now,
    );
    final haarId = await _insertStockItem(
      database,
      sku: 'LJ-GOLD-HAAR-UNIT-001',
      itemName: 'Gold Haar',
      subCategory: 'Haar',
      metal: 'Gold',
      createdAt: now,
    );
    final nosePinId = await _insertStockItem(
      database,
      sku: 'LJ-GOLD-NOSEPIN-UNIT-001',
      itemName: 'Gold Nose Pin',
      subCategory: 'Nose Pin',
      metal: 'Gold',
      createdAt: now,
    );

    await _insertStockUnit(
      database,
      stockItemId: jhumkaId,
      unitCode: 'UNIT-GOLD-JHUMKA-UNIT-001',
      metal: 'Gold',
      itemType: 'Jhumka',
      itemName: 'Gold Jhumka',
      netWeight: 10,
      createdAt: now,
    );
    await _insertStockUnit(
      database,
      stockItemId: haarId,
      unitCode: 'UNIT-GOLD-HAAR-UNIT-001',
      metal: 'Gold',
      itemType: 'Haar',
      itemName: 'Gold Haar',
      netWeight: 20,
      createdAt: now,
    );
    await _insertStockUnit(
      database,
      stockItemId: nosePinId,
      unitCode: 'UNIT-GOLD-NOSEPIN-UNIT-001',
      metal: 'Gold',
      itemType: 'Nose Pin',
      itemName: 'Gold Nose Pin',
      netWeight: 2,
      createdAt: now,
    );

    final controller = LowStockAlertController(repository);
    await controller.load();
    final grade = controller.inventoryRuleGroupCardsForMetal('Gold').single;
    final items = controller.inventoryRuleItemCardsForGroup(grade);

    expect(items.singleWhere((card) => card.itemType == 'Jhumka').unitLabel,
        'pair');
    expect(
        items.singleWhere((card) => card.itemType == 'Haar').unitLabel, 'set');
    expect(items.singleWhere((card) => card.itemType == 'Nose Pin').unitLabel,
        'pcs');
  });

  test('auto rules group gold by grade and silver by item type', () async {
    final now = DateTime.now();
    final goldRingId = await _insertStockItem(
      database,
      sku: 'LJ-GOLD-RING-001',
      itemName: '18K Ring',
      subCategory: 'Ring',
      metal: 'Gold',
      createdAt: now,
    );
    final goldChainId = await _insertStockItem(
      database,
      sku: 'LJ-GOLD-CHAIN-001',
      itemName: '18K Chain',
      subCategory: 'Chain',
      metal: 'Gold',
      createdAt: now,
    );
    final silverPayalId = await _insertStockItem(
      database,
      sku: 'LJ-SIL-PAYAL-GROUP-001',
      itemName: 'Silver Payal',
      subCategory: 'Payal',
      metal: 'Silver',
      createdAt: now,
    );

    await _insertStockUnit(
      database,
      stockItemId: goldRingId,
      unitCode: 'UNIT-GOLD-RING-GROUP-001',
      metal: 'Gold',
      itemType: 'Ring',
      itemName: '18K Ring',
      netWeight: 8,
      purityPercent: 75,
      createdAt: now,
    );
    await _insertStockUnit(
      database,
      stockItemId: goldChainId,
      unitCode: 'UNIT-GOLD-CHAIN-GROUP-001',
      metal: 'Gold',
      itemType: 'Chain',
      itemName: '18K Chain',
      netWeight: 12,
      purityPercent: 75,
      createdAt: now,
    );
    await _insertStockUnit(
      database,
      stockItemId: silverPayalId,
      unitCode: 'UNIT-SIL-PAYAL-GROUP-001',
      metal: 'Silver',
      itemType: 'Payal',
      itemName: 'Silver Payal 925',
      netWeight: 100,
      purityPercent: 925,
      createdAt: now,
    );
    await _insertStockUnit(
      database,
      stockItemId: silverPayalId,
      unitCode: 'UNIT-SIL-PAYAL-GROUP-002',
      metal: 'Silver',
      itemType: 'Payal',
      itemName: 'Silver Payal 800',
      netWeight: 90,
      purityPercent: 800,
      createdAt: now,
    );

    final controller = LowStockAlertController(repository);
    await controller.load();

    final autoMetals = controller.autoRuleMetalCards;
    final goldGroups = controller.autoRuleGroupCards
        .where((card) => card.metalType == 'Gold')
        .toList(growable: false);
    final silverGroups = controller.autoRuleGroupCards
        .where((card) => card.metalType == 'Silver')
        .toList(growable: false);
    final silverItems = controller.autoRuleGroupCardsForMetal('Silver');

    expect(autoMetals.map((card) => card.metalType),
        containsAll(['Gold', 'Silver']));
    expect(autoMetals.every((card) => card.level == LowStockCardLevel.metal),
        isTrue);
    expect(goldGroups, hasLength(1));
    expect(goldGroups.single.level, LowStockCardLevel.grade);
    expect(goldGroups.single.gradeLabel, '18KT (75%)');
    expect(goldGroups.single.totalUnits, 2);

    expect(silverGroups, hasLength(1));
    expect(silverGroups.single.level, LowStockCardLevel.itemGroup);
    expect(silverGroups.single.itemType, 'Payal');
    expect(silverGroups.single.totalUnits, 2);
    expect(silverItems, hasLength(1));
    expect(silverItems.single.itemType, 'Payal');
  });

  test('silver metal card opens item type cards', () async {
    final now = DateTime.now();
    final payalId = await _insertStockItem(
      database,
      sku: 'LJ-SIL-GRADE-PAYAL-001',
      itemName: 'Silver Payal Grade Flow',
      subCategory: 'Payal',
      metal: 'Silver',
      createdAt: now,
    );
    await _insertStockUnit(
      database,
      stockItemId: payalId,
      unitCode: 'UNIT-SIL-GRADE-PAYAL-001',
      metal: 'Silver',
      itemType: 'Payal',
      itemName: 'Silver Payal 925',
      netWeight: 100,
      purityPercent: 925,
      createdAt: now,
    );
    await _insertStockUnit(
      database,
      stockItemId: payalId,
      unitCode: 'UNIT-SIL-GRADE-PAYAL-002',
      metal: 'Silver',
      itemType: 'Payal',
      itemName: 'Silver Payal 800',
      netWeight: 90,
      purityPercent: 800,
      createdAt: now,
    );

    final controller = LowStockAlertController(repository);
    await controller.load();

    final silverGroups = controller.groupCardsForMetal('Silver');

    expect(silverGroups, hasLength(1));
    expect(silverGroups.single.level, LowStockCardLevel.itemGroup);
    expect(silverGroups.single.itemType, 'Payal');

    final itemDetails = controller.detailCardsForGroup(silverGroups.single);

    expect(itemDetails, isEmpty);
  });

  test('manual gold grade rule applies across item types', () async {
    final now = DateTime.now();
    final ringId = await _insertStockItem(
      database,
      sku: 'LJ-GOLD-GRADE-RING-001',
      itemName: '18K Grade Ring',
      subCategory: 'Ring',
      metal: 'Gold',
      createdAt: now,
    );
    final chainId = await _insertStockItem(
      database,
      sku: 'LJ-GOLD-GRADE-CHAIN-001',
      itemName: '18K Grade Chain',
      subCategory: 'Chain',
      metal: 'Gold',
      createdAt: now,
    );
    await _insertStockUnit(
      database,
      stockItemId: ringId,
      unitCode: 'UNIT-GOLD-GRADE-RING-001',
      metal: 'Gold',
      itemType: 'Ring',
      itemName: '18K Grade Ring',
      netWeight: 8,
      purityPercent: 75,
      createdAt: now,
    );
    await _insertStockUnit(
      database,
      stockItemId: chainId,
      unitCode: 'UNIT-GOLD-GRADE-CHAIN-001',
      metal: 'Gold',
      itemType: 'Chain',
      itemName: '18K Grade Chain',
      netWeight: 12,
      purityPercent: 75,
      createdAt: now,
    );

    await repository.saveManualRule(
      const LowStockManualRuleDraft(
        metalType: 'Gold',
        gradeLabel: '18KT (75%)',
        itemType: '',
        criticalUnits: 3,
        thresholdUnits: 6,
        targetUnits: 10,
        criticalNetWeight: 0,
        thresholdNetWeight: 0,
        targetNetWeight: 0,
        targetSets: 0,
        targetPackets: 0,
        preferredSupplierName: '',
      ),
    );

    final dashboard = await repository.loadDashboard();
    final goldItems = dashboard.itemTypeCards
        .where((card) => card.metalType == 'Gold')
        .toList(growable: false);
    final gradeCard = dashboard.gradeCards.single;

    expect(dashboard.rules.single.scopeLabel, 'Gold / 18KT (75%)');
    expect(goldItems, hasLength(2));
    expect(goldItems.every((card) => card.ruleMode == LowStockRuleMode.manual),
        isTrue);
    expect(goldItems.every((card) => card.targetUnits == 10), isTrue);
    expect(gradeCard.ruleMode, LowStockRuleMode.manual);

    final controller = LowStockAlertController(repository);
    await controller.load();

    expect(controller.inventoryRuleMetalCards, hasLength(1));
    expect(controller.inventoryRuleGroupCardsForMetal('Gold'), hasLength(1));
    expect(
      controller.inventoryRuleItemCardsForGroup(gradeCard),
      hasLength(2),
    );
  });

  test('manual rule overrides auto stock thresholds for an item', () async {
    final now = DateTime.now();
    final stockItemId = await _insertStockItem(
      database,
      sku: 'LJ-SIL-BICHHIYA-001',
      itemName: 'Raj Bichhiya',
      subCategory: 'Bichhiya',
      metal: 'Silver',
      createdAt: now,
    );
    for (var index = 1; index <= 5; index++) {
      await _insertStockUnit(
        database,
        stockItemId: stockItemId,
        unitCode: 'UNIT-SIL-BIC-${index.toString().padLeft(3, '0')}',
        metal: 'Silver',
        itemType: 'Bichhiya',
        itemName: 'Raj Bichhiya',
        netWeight: 25,
        purityPercent: 925,
        createdAt: now,
      );
    }

    await repository.saveManualRule(
      const LowStockManualRuleDraft(
        metalType: 'Silver',
        gradeLabel: '',
        itemType: 'Bichhiya',
        criticalUnits: 4,
        thresholdUnits: 8,
        targetUnits: 12,
        criticalNetWeight: 0,
        thresholdNetWeight: 0,
        targetNetWeight: 0,
        targetSets: 0,
        targetPackets: 0,
        preferredSupplierName: '',
      ),
    );

    final dashboard = await repository.loadDashboard();
    final card = dashboard.itemTypeCards.single;

    expect(dashboard.rules, hasLength(1));
    expect(card.ruleMode, LowStockRuleMode.manual);
    expect(card.thresholdUnits, 8);
    expect(card.targetUnits, 12);
    expect(card.suggestedReorderUnits, 7);
    expect(card.riskLevel, LowStockRiskLevel.low);
  });
}

Future<int> _insertStockItem(
  AppDatabase database, {
  required String sku,
  required String itemName,
  required String subCategory,
  required String metal,
  int quantity = 1,
  required DateTime createdAt,
}) {
  return database.into(database.stockItems).insert(
        StockItemsCompanion.insert(
          createdAt: drift.Value(createdAt),
          sku: sku,
          itemName: itemName,
          category: metal,
          subCategory: subCategory,
          metalType: drift.Value(metal),
          purity: const drift.Value(''),
          grossWeight: const drift.Value(0),
          netWeight: const drift.Value(0),
          quantity: drift.Value(quantity),
          status: drift.Value(stock.StockStatus.available.label),
          isActive: const drift.Value(true),
        ),
      );
}

Future<void> _insertStockUnit(
  AppDatabase database, {
  required int stockItemId,
  required String unitCode,
  required String metal,
  required String itemType,
  required String itemName,
  required double netWeight,
  double purityPercent = 91.6,
  String? status,
  required DateTime createdAt,
}) {
  return database.customStatement(
    '''
    INSERT INTO stock_item_units (
      stock_item_id,
      batch_code,
      unit_code,
      piece_no,
      metal_type,
      item_type,
      segment,
      item_name,
      gross_weight,
      less_weight,
      net_weight,
      purity_percent,
      actual_fine_weight,
      supplier_name,
      status,
      created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    [
      stockItemId,
      'BATCH-$unitCode',
      unitCode,
      1,
      metal,
      itemType,
      'General',
      itemName,
      netWeight,
      0.0,
      netWeight,
      purityPercent,
      netWeight * (purityPercent / 100),
      'Lotus Supplier',
      status ?? stock.StockStatus.available.label,
      createdAt.millisecondsSinceEpoch,
    ],
  );
}
