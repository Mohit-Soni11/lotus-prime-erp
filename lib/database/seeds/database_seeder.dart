import 'dart:math';

import 'package:drift/drift.dart';

import 'package:lotus_erp/core/logging/app_logger.dart';
import 'package:lotus_erp/database/db/app_database.dart';

class DatabaseSeeder {
  final AppDatabase db;
  final Random _rng = Random();

  DatabaseSeeder(this.db);

  Future<void> seed() async {
    final customerCount = await _rowCount('customers');

    if (customerCount > 0) {
      AppLogger.info(
        'Demo seed skipped because customers already exist. Checking notifications.',
      );

      final notificationCount = await _rowCount('notifications');
      if (notificationCount == 0) {
        AppLogger.info('Notifications missing. Seeding notification defaults.');
        await _seedNotifications();
      } else {
        AppLogger.info(
            'Demo seed skipped. Existing operational data detected.');
      }
      return;
    }

    AppLogger.warning('Seeding demo data into a fresh local database.');

    await _seedShopProfile();
    await _seedCustomersAndTransactions();
    await _seedNotifications();

    AppLogger.info('Demo data generated successfully.');
  }

  Future<int> _rowCount(String tableName) async {
    final result = await db
        .customSelect(
          'SELECT COUNT(*) AS count FROM $tableName',
        )
        .getSingle();
    return result.read<int>('count');
  }

  Future<void> _seedShopProfile() async {
    await db.into(db.shopProfiles).insert(
          ShopProfilesCompanion.insert(
            shopName: const Value("Anjali Jewellers"),
            tagline: const Value("Since 2009 - Premium Jewellery"),
            ownerName: const Value("Sone Lal"),
            city: const Value("Patna"),
            contactNumber: const Value("99056 88200"),
            showMobile: const Value(true),
          ),
        );
  }

  Future<void> _seedCustomersAndTransactions() async {
    final firstNames = [
      "Amit",
      "Rahul",
      "Priya",
      "Suman",
      "Vikram",
      "Anjali",
      "Rohan",
      "Kavita",
      "Arjun",
      "Neha",
      "Suresh",
    ];
    final lastNames = [
      "Sharma",
      "Verma",
      "Singh",
      "Kumari",
      "Gupta",
      "Devi",
      "Roy",
      "Yadav",
      "Jha",
    ];
    final cities = ["Patna", "Gaya", "Muzaffarpur", "Danapur", "Delhi"];
    final itemsList = [
      "Gold Chain",
      "Bridal Necklace",
      "Diamond Ring",
      "Silver Anklet",
      "Bangle Set",
    ];

    for (int i = 1; i <= 50; i++) {
      final firstName = firstNames[_rng.nextInt(firstNames.length)];
      final lastName = lastNames[_rng.nextInt(lastNames.length)];
      final fullName = "$firstName $lastName";

      final mobilePrefix = _rng.nextInt(40) + 60;
      final mobileSuffix = _rng.nextInt(90000) + 10000;
      final mobile =
          "9$mobilePrefix${i.toString().padLeft(2, '0')}$mobileSuffix";

      final customerId = await db.into(db.customers).insert(
            CustomersCompanion.insert(
              name: fullName,
              mobile: mobile,
              city: Value(cities[_rng.nextInt(cities.length)]),
              type: Value(_rng.nextBool() ? "Regular" : "VIP"),
            ),
          );

      if (_rng.nextDouble() < 0.8) {
        await _createRandomBill(customerId, fullName, mobile, itemsList, i);
      }

      if (_rng.nextDouble() < 0.3) {
        await _createRandomOrder(customerId, itemsList, i);
      }

      if (_rng.nextDouble() < 0.2) {
        await _createRandomLoan(customerId, i);
      }
    }
  }

  Future<void> _createRandomBill(
    int customerId,
    String name,
    String mobile,
    List<String> items,
    int index,
  ) async {
    final billNo = "INV-26-${1000 + index}";
    final billDate = index.isEven
        ? DateTime.now()
        : DateTime.now().subtract(Duration(days: _rng.nextInt(30)));

    final billId = await db.into(db.bills).insert(
          BillsCompanion.insert(
            billNo: billNo,
            customerId: Value(customerId),
            customerName: Value(name),
            mobile: Value(mobile),
            billDate: Value(billDate),
            totalAmount: const Value(0),
          ),
        );

    double total = 0;
    final itemCount = _rng.nextInt(3) + 1;

    for (int k = 0; k < itemCount; k++) {
      final weight = 2.5 + _rng.nextDouble() * 12.5;
      const rate = 74500.0;
      final making = 500 * weight;
      final itemTotal = (rate / 10 * weight) + making;

      await db.into(db.billItems).insert(
            BillItemsCompanion.insert(
              billId: billId,
              itemName: items[_rng.nextInt(items.length)],
              grossWeight: Value(double.parse(weight.toStringAsFixed(2))),
              netWeight: Value(double.parse(weight.toStringAsFixed(2))),
              rate: const Value(rate),
              makingCharge: Value(double.parse(making.toStringAsFixed(2))),
              itemTotal: Value(double.parse(itemTotal.toStringAsFixed(2))),
            ),
          );
      total += itemTotal;
    }

    await (db.update(db.bills)..where((tbl) => tbl.id.equals(billId))).write(
      BillsCompanion(
        totalAmount: Value(double.parse(total.toStringAsFixed(0))),
        finalAmount: Value(double.parse(total.toStringAsFixed(0))),
      ),
    );
  }

  Future<void> _createRandomOrder(
    int customerId,
    List<String> items,
    int index,
  ) async {
    await db.into(db.salesOrders).insert(
          SalesOrdersCompanion.insert(
            orderNo: "ORD-${500 + index}",
            customerId: customerId,
            itemName: items[_rng.nextInt(items.length)],
            approxWeight: const Value(10.5),
            bookingType: const Value("FIXED"),
            lockedRate: const Value(75000),
            status: const Value("PENDING"),
            deliveryDate: Value(DateTime.now().add(const Duration(days: 10))),
          ),
        );
  }

  Future<void> _createRandomLoan(int customerId, int index) async {
    await db.into(db.loans).insert(
          LoansCompanion.insert(
            loanNo: "LN-${200 + index}",
            customerId: customerId,
            itemDesc: "Old Gold Chain",
            grossWeight: const Value(12.5),
            loanAmount: Value((20000 + _rng.nextInt(30000)).toDouble()),
            startDate: Value(
              DateTime.now().subtract(Duration(days: _rng.nextInt(55) + 5)),
            ),
          ),
        );
  }

  Future<void> _seedNotifications() async {
    final dummyNotifications = [
      NotificationsCompanion.insert(
        type: "admin",
        role: const Value("staff"),
        title: "Low Stock",
        desc: "Gold Chains low.",
        isRead: const Value(false),
      ),
      NotificationsCompanion.insert(
        type: "crm",
        role: const Value("admin"),
        title: "Followup",
        desc: "Call pending payments.",
        isRead: const Value(false),
      ),
      NotificationsCompanion.insert(
        type: "loan",
        role: const Value("all"),
        title: "Interest Due Warning",
        desc: "Loan LN-205 (Rohan Gupta) is overdue.",
        isRead: const Value(false),
      ),
      NotificationsCompanion.insert(
        type: "admin",
        role: const Value("owner"),
        title: "Backup Successful",
        desc: "Daily cloud backup completed.",
        isRead: const Value(true),
      ),
      NotificationsCompanion.insert(
        type: "admin",
        role: const Value("all"),
        title: "Gold Rate Updated",
        desc: "Gold rate dropped to Rs 71,500.",
        isRead: const Value(true),
      ),
    ];

    for (final notification in dummyNotifications) {
      await db.into(db.notifications).insert(notification);
    }
  }
}
