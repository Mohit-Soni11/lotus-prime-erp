import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/girvi/new_girvi_controller.dart';
import 'package:lotus_erp/models/girvi/girvi_persistence_models.dart';
import 'package:lotus_erp/repositories/girvi/girvi_details_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('structured Girvi persistence', () {
    late AppDatabase db;
    late GirviDetailsRepository repository;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repository = GirviDetailsRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('saves every item, photo and mixed disbursement atomically', () async {
      final customerId = await _insertCustomer(db);

      final loanId = await repository.createLoanWithDetails(
        loan: _loanInsert(
          ticketNo: 'GRV-0001',
          customerId: customerId,
          itemDescription: 'Ring and payal',
          loanAmount: 30000,
        ),
        items: _twoItems(),
        disbursements: _mixedDisbursements(),
        expectedLoanAmount: 30000,
      );

      final details = await repository.getLoanDetails(loanId);

      expect(details, isNotNull);
      expect(details!.items, hasLength(2));
      expect(details.items[0].item.itemName, 'Gold ring');
      expect(details.items[0].item.huidNumber, 'HUID-GOLD-1');
      expect(details.items[0].item.valuationPurityPercent, 91.6);
      expect(details.items[0].photos.map((photo) => photo.filePath),
          ['/photos/ring-front.jpg', '/photos/ring-back.jpg']);
      expect(details.items[1].item.itemName, 'Silver payal');
      expect(details.items[1].item.valuationMethod, 'DIRECT_RATE');
      expect(details.items[1].photos.single.filePath, '/photos/payal.jpg');
      expect(details.disbursements, hasLength(2));
      expect(details.disbursements[0].mode, 'Cash');
      expect(details.disbursements[0].amount, 10000);
      expect(details.disbursements[1].mode, 'UPI');
      expect(details.disbursements[1].amount, 20000);
    });

    test('update replaces item, photo and disbursement details together',
        () async {
      final customerId = await _insertCustomer(db);
      final loanId = await repository.createLoanWithDetails(
        loan: _loanInsert(
          ticketNo: 'GRV-0002',
          customerId: customerId,
          itemDescription: 'Original items',
          loanAmount: 30000,
        ),
        items: _twoItems(),
        disbursements: _mixedDisbursements(),
        expectedLoanAmount: 30000,
      );

      final updated = await repository.updateLoanWithDetails(
        loanId: loanId,
        loan: const GirviLoansCompanion(
          itemDescription: drift.Value('Updated chain'),
          itemCount: drift.Value(1),
          metalType: drift.Value('Gold'),
          metalPurity: drift.Value('22K'),
          grossWeight: drift.Value(12),
          stoneWeight: drift.Value(1),
          netWeight: drift.Value(11),
          ratePerGram: drift.Value(7000),
          totalValue: drift.Value(70532),
          loanAmount: drift.Value(25000),
          disbursementMode: drift.Value('Cheque Rs 25000.00'),
        ),
        items: const [
          GirviLoanItemInput(
            serialNo: 1,
            itemName: 'Gold chain',
            metalType: 'Gold',
            purity: '22K',
            purityFactor: 0.916,
            pieces: 1,
            grossWeight: 12,
            lessWeight: 1,
            netWeight: 11,
            valuationMethod: 'PURITY',
            valuationPurityPercent: 91.6,
            fineWeight: 10.076,
            ratePerGram: 7000,
            valuationAmount: 70532,
            photoPaths: ['/photos/chain.jpg'],
          ),
        ],
        disbursements: const [
          GirviDisbursementInput(
            sequenceNo: 1,
            mode: 'Cheque',
            displayLabel: 'Cheque',
            amount: 25000,
            referenceNo: 'CHQ-55',
          ),
        ],
        expectedLoanAmount: 25000,
      );

      final details = await repository.getLoanDetails(loanId);
      final allPhotos = await db.select(db.girviItemPhotos).get();

      expect(updated, isTrue);
      expect(details!.loan.itemDescription, 'Updated chain');
      expect(details.items, hasLength(1));
      expect(details.items.single.item.itemName, 'Gold chain');
      expect(details.items.single.photos.single.filePath, '/photos/chain.jpg');
      expect(allPhotos, hasLength(1));
      expect(details.disbursements.single.referenceNo, 'CHQ-55');
    });

    test('invalid update leaves the existing structured record untouched',
        () async {
      final customerId = await _insertCustomer(db);
      final loanId = await repository.createLoanWithDetails(
        loan: _loanInsert(
          ticketNo: 'GRV-0003',
          customerId: customerId,
          itemDescription: 'Original items',
          loanAmount: 30000,
        ),
        items: _twoItems(),
        disbursements: _mixedDisbursements(),
        expectedLoanAmount: 30000,
      );

      await expectLater(
        repository.updateLoanWithDetails(
          loanId: loanId,
          loan: const GirviLoansCompanion(
            itemDescription: drift.Value('Should not persist'),
          ),
          items: [_twoItems().first, _twoItems().first],
          disbursements: _mixedDisbursements(),
          expectedLoanAmount: 30000,
        ),
        throwsArgumentError,
      );

      final details = await repository.getLoanDetails(loanId);
      expect(details!.loan.itemDescription, 'Original items');
      expect(details.items, hasLength(2));
      expect(details.disbursements, hasLength(2));
    });

    test('New Girvi controller writes mixed item details to child tables',
        () async {
      final customerId = await _insertCustomer(db);
      final customer = await (db.select(db.customers)
            ..where((row) => row.id.equals(customerId)))
          .getSingle();
      final controller = NewGirviController(db);
      addTearDown(controller.dispose);
      await controller.initialize();
      controller.selectCustomer(customer);
      controller.onGrossWeightChanged('15');
      controller.onStoneWeightChanged('0');
      controller.onRatePerGramChanged('5000');
      controller.onLoanAmountChanged('30000');

      final saved = await controller.saveLoan(
        items: _twoItems(),
        disbursements: _mixedDisbursements(),
        invoiceGenerated: true,
        idProofNumber: 'KYC-123',
        idProofImagePath: '/kyc/card.jpg',
        notes: 'Keep in locker 2',
      );
      final details =
          await repository.getLoanDetailsByTicket(controller.ticketNo);

      expect(saved, isTrue);
      expect(details, isNotNull);
      final savedDetails = details!;
      expect(controller.lastSavedLoanId, savedDetails.loan.id);
      expect(savedDetails.loan.itemDescription,
          contains('Serial Number 1 - Gold ring'));
      expect(savedDetails.loan.itemDescription, isNot(contains('#1')));
      expect(savedDetails.loan.metalType, 'Mixed');
      expect(savedDetails.loan.metalPurity, 'Mixed');
      expect(savedDetails.loan.itemCount, 3);
      expect(savedDetails.loan.itemPhotoPath, '/photos/ring-front.jpg');
      expect(savedDetails.items, hasLength(2));
      expect(savedDetails.disbursements, hasLength(2));
    });

    test('New Girvi controller loads and updates an existing ticket', () async {
      final customerId = await _insertCustomer(db);
      final loanId = await repository.createLoanWithDetails(
        loan: _loanInsert(
          ticketNo: 'GRV-EDIT-1',
          customerId: customerId,
          itemDescription: 'Original items',
          loanAmount: 30000,
        ).copyWith(
          invoiceGenerated: const drift.Value(true),
          interestRate: const drift.Value(1.5),
          durationMonths: const drift.Value(6),
          idProofType: const drift.Value('Aadhaar Card'),
          idProofNumber: const drift.Value('AAD-001'),
          notes: const drift.Value('Original note'),
        ),
        items: _twoItems(),
        disbursements: _mixedDisbursements(),
        expectedLoanAmount: 30000,
      );
      final controller = NewGirviController(db);
      addTearDown(controller.dispose);

      final loaded = await controller.initializeForEdit(loanId);
      controller.onLoanAmountChanged('25000');
      final saved = await controller.saveLoan(
        items: const [
          GirviLoanItemInput(
            serialNo: 1,
            itemName: 'Edited gold chain',
            metalType: 'Gold',
            purity: '22K',
            purityFactor: 0.916,
            pieces: 1,
            grossWeight: 12,
            lessWeight: 1,
            netWeight: 11,
            valuationMethod: 'PURITY',
            valuationPurityPercent: 91.6,
            fineWeight: 10.076,
            ratePerGram: 7000,
            valuationAmount: 70532,
            photoPaths: ['/photos/edited-chain.jpg'],
          ),
        ],
        disbursements: const [
          GirviDisbursementInput(
            sequenceNo: 1,
            mode: 'Cheque',
            displayLabel: 'Cheque',
            amount: 25000,
            referenceNo: 'EDIT-CHQ-1',
          ),
        ],
        invoiceGenerated: false,
        idProofNumber: 'AAD-EDIT',
        idProofImagePath: '/kyc/edited-card.jpg',
        notes: 'Edited note',
      );

      final loans = await db.select(db.girviLoans).get();
      final details = await repository.getLoanDetails(loanId);

      expect(loaded, isTrue);
      expect(controller.isEditMode, isTrue);
      expect(controller.ticketNo, 'GRV-EDIT-1');
      expect(controller.selectedCustomer?.id, customerId);
      expect(saved, isTrue);
      expect(controller.lastSavedLoanId, loanId);
      expect(loans, hasLength(1));
      final updatedDetails = details!;
      expect(updatedDetails.loan.ticketNo, 'GRV-EDIT-1');
      expect(updatedDetails.loan.itemDescription,
          contains('Serial Number 1 - Edited gold chain'));
      expect(updatedDetails.loan.loanAmount, 25000);
      expect(updatedDetails.loan.invoiceGenerated, isTrue);
      expect(updatedDetails.loan.idProofNumber, 'AAD-EDIT');
      expect(updatedDetails.loan.notes, 'Edited note');
      expect(updatedDetails.items, hasLength(1));
      expect(updatedDetails.items.single.item.itemName, 'Edited gold chain');
      expect(
        updatedDetails.items.single.photos.single.filePath,
        '/photos/edited-chain.jpg',
      );
      expect(updatedDetails.disbursements.single.referenceNo, 'EDIT-CHQ-1');
    });
  });

  test('v20 migration backfills legacy Girvi details without losing data',
      () async {
    sqfliteFfiInit();
    final tempDir = await Directory.systemTemp.createTemp('girvi_v20_');
    final dbFile = File('${tempDir.path}/legacy.sqlite');
    final legacyDb = await databaseFactoryFfi.openDatabase(dbFile.path);
    await legacyDb.execute('''
      CREATE TABLE girvi_loans (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        ticket_no TEXT NOT NULL UNIQUE,
        customer_id INTEGER NOT NULL,
        item_description TEXT NOT NULL,
        item_count INTEGER NOT NULL DEFAULT 1,
        huid_number TEXT,
        item_photo_path TEXT,
        metal_type TEXT NOT NULL DEFAULT 'Gold',
        metal_purity TEXT NOT NULL DEFAULT '22K',
        gross_weight REAL NOT NULL DEFAULT 0,
        stone_weight REAL NOT NULL DEFAULT 0,
        net_weight REAL NOT NULL DEFAULT 0,
        rate_per_gram REAL NOT NULL DEFAULT 0,
        total_value REAL NOT NULL DEFAULT 0,
        loan_amount REAL NOT NULL DEFAULT 0,
        disbursement_mode TEXT NOT NULL DEFAULT 'Cash',
        created_at INTEGER NOT NULL,
        updated_at INTEGER
      )
    ''');
    await legacyDb.insert('girvi_loans', {
      'ticket_no': 'OLD-GRV-1',
      'customer_id': 1,
      'item_description': 'Legacy gold ring',
      'item_count': 1,
      'huid_number': 'OLD-HUID',
      'item_photo_path': '/legacy/ring.jpg',
      'metal_type': 'Gold',
      'metal_purity': '22K',
      'gross_weight': 8.5,
      'stone_weight': 0.5,
      'net_weight': 8.0,
      'rate_per_gram': 6000.0,
      'total_value': 48000.0,
      'loan_amount': 20000.0,
      'disbursement_mode': 'Cash Rs 20000.00',
      'created_at': 0,
    });
    await legacyDb.execute('PRAGMA user_version = 20');
    await legacyDb.close();

    final migrated =
        AppDatabase.forTesting(NativeDatabase.createInBackground(dbFile));
    addTearDown(() async {
      await migrated.close();
      await tempDir.delete(recursive: true);
    });

    final items = await migrated.select(migrated.girviLoanItems).get();
    final photos = await migrated.select(migrated.girviItemPhotos).get();
    final disbursements =
        await migrated.select(migrated.girviDisbursements).get();

    expect(items, hasLength(1));
    expect(items.single.itemName, 'Legacy gold ring');
    expect(items.single.huidNumber, 'OLD-HUID');
    expect(items.single.isLegacy, isTrue);
    expect(photos.single.filePath, '/legacy/ring.jpg');
    expect(photos.single.isLegacy, isTrue);
    expect(disbursements.single.amount, 20000);
    expect(disbursements.single.details, 'Cash Rs 20000.00');
    expect(disbursements.single.isLegacy, isTrue);
  });
}

Future<int> _insertCustomer(AppDatabase db) {
  return db.into(db.customers).insert(
        CustomersCompanion.insert(
          name: 'Structured Customer',
          mobile: '9999999999',
        ),
      );
}

GirviLoansCompanion _loanInsert({
  required String ticketNo,
  required int customerId,
  required String itemDescription,
  required double loanAmount,
}) {
  return GirviLoansCompanion.insert(
    ticketNo: ticketNo,
    customerId: customerId,
    itemDescription: itemDescription,
    itemCount: const drift.Value(3),
    metalType: const drift.Value('Mixed'),
    metalPurity: const drift.Value('Mixed'),
    grossWeight: const drift.Value(15),
    stoneWeight: const drift.Value(0),
    netWeight: const drift.Value(15),
    ratePerGram: const drift.Value(5000),
    totalValue: const drift.Value(75000),
    loanAmount: drift.Value(loanAmount),
    disbursementMode: const drift.Value('Cash + UPI'),
  );
}

List<GirviLoanItemInput> _twoItems() {
  return const [
    GirviLoanItemInput(
      serialNo: 1,
      itemName: 'Gold ring',
      metalType: 'Gold',
      purity: '22K',
      purityFactor: 0.916,
      pieces: 1,
      huidNumber: 'HUID-GOLD-1',
      grossWeight: 5,
      lessWeight: 0,
      netWeight: 5,
      valuationMethod: 'PURITY',
      valuationPurityPercent: 91.6,
      fineWeight: 4.58,
      ratePerGram: 10000,
      valuationAmount: 45800,
      photoPaths: ['/photos/ring-front.jpg', '/photos/ring-back.jpg'],
    ),
    GirviLoanItemInput(
      serialNo: 2,
      itemName: 'Silver payal',
      metalType: 'Silver',
      purity: '925',
      purityFactor: 0.925,
      pieces: 2,
      grossWeight: 10,
      lessWeight: 0,
      netWeight: 10,
      valuationMethod: 'DIRECT_RATE',
      fineWeight: 10,
      ratePerGram: 2920,
      valuationAmount: 29200,
      photoPaths: ['/photos/payal.jpg'],
    ),
  ];
}

List<GirviDisbursementInput> _mixedDisbursements() {
  return const [
    GirviDisbursementInput(
      sequenceNo: 1,
      mode: 'Cash',
      displayLabel: 'Cash',
      amount: 10000,
    ),
    GirviDisbursementInput(
      sequenceNo: 2,
      mode: 'UPI',
      displayLabel: 'UPI',
      amount: 20000,
      referenceNo: 'UPI-REF-1',
    ),
  ];
}
