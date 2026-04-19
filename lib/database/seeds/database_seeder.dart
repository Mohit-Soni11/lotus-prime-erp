import 'dart:math';
import 'package:drift/drift.dart';
import 'package:lotus_erp/database/db/app_database.dart';

class DatabaseSeeder {
  final AppDatabase db;
  final Random _rng = Random();

  DatabaseSeeder(this.db);

  /// Main trigger function
  Future<void> seed() async {
    // 1. Check if Data Exists
    final customerCount = await db.select(db.customers).get().then((l) => l.length);
    
    if (customerCount > 0) {
      print(">> ℹ️ Customers already exist. Checking Notifications...");
      
      final notifCount = await db.select(db.notifications).get().then((l) => l.length);
      if (notifCount == 0) {
        print(">> 🔔 Notifications missing. Seeding ONLY notifications...");
        await _seedNotifications();
      } else {
        print(">> ✅ All data exists. Skipping Seed.");
      }
      return;
    }

    print("--- 🛠️ SEEDING DATABASE (ENTERPRISE MODE) ---");
    
    await _seedShopProfile();
    await _seedCustomersAndTransactions();
    await _seedNotifications(); 
    
    print("--- ✅ DUMMY DATA GENERATED SUCCESSFULLY ---");
  }

  /// 2. Shop Profile (Matching Python setup.py)
  Future<void> _seedShopProfile() async {
    await db.into(db.shopProfiles).insert(
      ShopProfilesCompanion.insert(
        shopName: const Value("Anjali Jewellers"),
        tagline: const Value("Since 2009 • Premium Jewellery"),
        ownerName: const Value("Sone Lal"),
        city: const Value("Patna"),
        contactNumber: const Value("99056 88200"),
        showMobile: const Value(true),
      )
    );
  }

  /// 3. Customers & Transactions
  Future<void> _seedCustomersAndTransactions() async {
    // Lists matched with Python generate_dummy_data
    final firstNames = ["Amit", "Rahul", "Priya", "Suman", "Vikram", "Anjali", "Rohan", "Kavita", "Arjun", "Neha", "Suresh"];
    final lastNames = ["Sharma", "Verma", "Singh", "Kumari", "Gupta", "Devi", "Roy", "Yadav", "Jha"];
    final cities = ["Patna", "Gaya", "Muzaffarpur", "Danapur", "Delhi"];
    final itemsList = ["Gold Chain", "Bridal Necklace", "Diamond Ring", "Silver Anklet", "Bangle Set"];

    for (int i = 1; i <= 50; i++) {
      final fname = firstNames[_rng.nextInt(firstNames.length)];
      final lname = lastNames[_rng.nextInt(lastNames.length)];
      final fullName = "$fname $lname";
      
      // Python Logic: 9 + Random(60-99) + Index(2 digits) + Random(5 digits)
      final mobilePrefix = _rng.nextInt(40) + 60; // 60 to 99
      final mobileSuffix = _rng.nextInt(90000) + 10000;
      final mobile = "9$mobilePrefix${i.toString().padLeft(2, '0')}$mobileSuffix";

      // A. Create Customer
      final custId = await db.into(db.customers).insert(
        CustomersCompanion.insert(
          name: fullName,
          mobile: mobile,
          city: Value(cities[_rng.nextInt(cities.length)]),
          type: Value(_rng.nextBool() ? "Regular" : "VIP"), // Biased towards Regular
        )
      );

      // B. Create Transactions (Probabilities matched with Python)
      // 80% Chance for Bill
      if (_rng.nextDouble() < 0.8) await _createRandomBill(custId, fullName, mobile, itemsList, i);
      
      // 30% Chance for Order
      if (_rng.nextDouble() < 0.3) await _createRandomOrder(custId, itemsList, i);
      
      // 20% Chance for Loan
      if (_rng.nextDouble() < 0.2) await _createRandomLoan(custId, i);
    }
  }

  // --- Helpers (Logic Ported from Python) ---
  
  Future<void> _createRandomBill(int custId, String name, String mob, List<String> items, int index) async {
    final billNo = "INV-26-${1000 + index}";
    
    // 🔥 FORCE TODAY LOGIC:
    // Python mein random date thi, par Dashboard demo ke liye hum
    // har dusre bill (Even numbers) ko "AAJ" ka banayenge.
    final billDate = (index % 2 == 0) 
        ? DateTime.now() // Aaj ki date (Dashboard par dikhega)
        : DateTime.now().subtract(Duration(days: _rng.nextInt(30))); // Purani date

    final billId = await db.into(db.bills).insert(
      BillsCompanion.insert(
        billNo: billNo,
        customerId: Value(custId),
        customerName: Value(name),
        mobile: Value(mob),
        billDate: Value(billDate),
        totalAmount: const Value(0), // Will update below
      )
    );

    double total = 0;
    int itemCount = _rng.nextInt(3) + 1; // 1 to 3 items
    
    for (int k = 0; k < itemCount; k++) {
      // Python Logic: Weight 2.5 to 15.0
      double weight = 2.5 + _rng.nextDouble() * 12.5; 
      
      // Python Logic: Rate 74500 fixed
      double rate = 74500; 
      
      // Python Logic: Making = 500 * Weight
      double making = 500 * weight;
      
      // Python Logic: Calculation
      double itemTotal = (rate / 10 * weight) + making;

      await db.into(db.billItems).insert(
        BillItemsCompanion.insert(
          billId: billId,
          itemName: items[_rng.nextInt(items.length)],
          grossWeight: Value(double.parse(weight.toStringAsFixed(2))),
          netWeight: Value(double.parse(weight.toStringAsFixed(2))),
          rate: Value(rate),
          makingCharge: Value(double.parse(making.toStringAsFixed(2))),
          itemTotal: Value(double.parse(itemTotal.toStringAsFixed(2))),
        )
      );
      total += itemTotal;
    }

    // Update Bill Total
    await (db.update(db.bills)..where((tbl) => tbl.id.equals(billId))).write(
      BillsCompanion(
        totalAmount: Value(double.parse(total.toStringAsFixed(0))),
        finalAmount: Value(double.parse(total.toStringAsFixed(0))),
      )
    );
  }

  Future<void> _createRandomOrder(int custId, List<String> items, int index) async {
    await db.into(db.salesOrders).insert(
      SalesOrdersCompanion.insert(
        orderNo: "ORD-${500 + index}",
        customerId: custId,
        itemName: items[_rng.nextInt(items.length)],
        approxWeight: const Value(10.5), // Fixed as per Python
        bookingType: const Value("FIXED"),
        lockedRate: const Value(75000), // Fixed as per Python
        status: const Value("PENDING"),
        deliveryDate: Value(DateTime.now().add(const Duration(days: 10))),
      )
    );
  }

  Future<void> _createRandomLoan(int custId, int index) async {
    await db.into(db.loans).insert(
      LoansCompanion.insert(
        loanNo: "LN-${200 + index}",
        customerId: custId,
        itemDesc: "Old Gold Chain",
        grossWeight: const Value(12.5),
        loanAmount: Value((20000 + _rng.nextInt(30000)).toDouble()), // 20k to 50k
        startDate: Value(DateTime.now().subtract(Duration(days: _rng.nextInt(55) + 5))),
      )
    );
  }

  // 4. Notifications (Extensive List + Python ones)
  Future<void> _seedNotifications() async {
    final dummyNotifs = [
      NotificationsCompanion.insert(
        type: "admin", role: const Value("staff"),
        title: "Low Stock", desc: "Gold Chains low.", isRead: const Value(false)
      ),
      NotificationsCompanion.insert(
        type: "crm", role: const Value("admin"),
        title: "Followup", desc: "Call Pending Payments.", isRead: const Value(false)
      ),
      NotificationsCompanion.insert(
        type: "loan", role: const Value("all"),
        title: "Interest Due Warning", desc: "Loan #LN-205 (Rohan Gupta) is overdue.", isRead: const Value(false)
      ),
      NotificationsCompanion.insert(
        type: "admin", role: const Value("owner"),
        title: "Backup Successful ✅", desc: "Daily cloud backup completed.", isRead: const Value(true)
      ),
      NotificationsCompanion.insert(
        type: "admin", role: const Value("all"),
        title: "Gold Rate Updated 📉", desc: "Gold rate dropped to ₹71,500.", isRead: const Value(true)
      ),
    ];

    for (var notif in dummyNotifs) {
      await db.into(db.notifications).insert(notif);
    }
  }
}