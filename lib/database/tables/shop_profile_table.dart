import 'package:drift/drift.dart';
import 'base_table.dart';

@DataClassName('ShopProfileData')
class ShopProfiles extends Table with BaseTable {
  // --- 1. Basic Info (Enterprise) ---
  TextColumn get shopName =>
      text().withDefault(const Constant("My Jewellery Shop"))();
  TextColumn get legalName => text().nullable()();
  TextColumn get tagline => text().nullable()();
  TextColumn get ownerName => text().nullable()();
  TextColumn get ownerContact => text().nullable()();
  TextColumn get ownerWhatsapp => text().nullable()(); // Personal WA
  TextColumn get estYear => text().nullable()();
  TextColumn get branchCode => text().nullable()();

  // --- Operations ---
  TextColumn get openingTime => text().nullable()();
  TextColumn get closingTime => text().nullable()();
  TextColumn get weeklyOff => text().nullable()();

  // --- Communication ---
  TextColumn get email => text().nullable()();
  TextColumn get contactNumber => text().nullable()();
  TextColumn get whatsappNumber => text().nullable()(); // Shop WA

  // --- Images (Base64 Strings) ---
  // SQLite mein TEXT column huge strings store kar sakta hai
  TextColumn get logoBase64 => text().nullable()();
  TextColumn get signatureBase64 => text().nullable()();

  // --- 2. Address & Map ---
  TextColumn get address => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get state => text().nullable()();
  TextColumn get pincode => text().nullable()();
  TextColumn get country => text().nullable()();
  TextColumn get mapConfig =>
      text().nullable()(); // JSON string for map coordinates

  // --- 3. Social & Support ---
  TextColumn get instagramLink => text().nullable()();
  TextColumn get facebookLink => text().nullable()();
  TextColumn get website => text().nullable()();

  // --- 4. Statutory (GST & BIS) ---
  TextColumn get gstin => text().nullable()();
  TextColumn get gstType => text().nullable()(); // Regular/Composition
  TextColumn get bisLicense => text().nullable()();
  TextColumn get huidNo => text().nullable()();

  // Python: hsn_json = Column(Text) -> Stores list as JSON string
  TextColumn get hsnJson => text().nullable()();

  // --- 5. Banking (Primary) ---
  TextColumn get bankHolderName => text().nullable()();
  TextColumn get bankName => text().nullable()();
  TextColumn get bankAccNo => text().nullable()();
  TextColumn get bankIfsc => text().nullable()();
  TextColumn get upiId => text().nullable()();

  // --- Toggles (Settings) ---
  // Python: show_mobile = Column(Boolean, default=True)
  BoolColumn get showMobile => boolean().withDefault(const Constant(true))();
  BoolColumn get showEmail => boolean().withDefault(const Constant(true))();
  BoolColumn get showGst => boolean().withDefault(const Constant(true))();

  // ✅ v5: Cash Register opening balance — nullable taaki purane rows crash na karein
  RealColumn get openingCashBalance =>
      real().nullable().withDefault(const Constant(0.0))();
}
