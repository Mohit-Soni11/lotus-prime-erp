
import '../../database/db/app_database.dart';
import '../../models/stock/supplier_profile/supplier_profile_model.dart';
import 'supplier_repository.dart';
import '../../core/logging/app_logger.dart';

class SupplierProfileRepository {
  final AppDatabase _db;
  late final SupplierRepository _supplierRepo;

  SupplierProfileRepository({AppDatabase? db}) : _db = db ?? AppDatabase() {
    _supplierRepo = SupplierRepository(_db);
  }

  Future<SupplierProfileModel?> fetchProfile(int supplierId) async {
    try {
      final supplier = await _supplierRepo.getById(supplierId);
      if (supplier == null || supplier.id == null) return null;

      final ledger = await _supplierRepo.getLedgerSnapshot(supplierId);
      final purchases = ledger.history
          .map(
            (item) => SupplierProfilePurchaseModel(
              voucherId: item.voucherId,
              voucherNo: item.voucherNo,
              supplierInvoiceNo: item.supplierInvoiceNo,
              partyName: item.partyName,
              grossAmount: item.grossAmount,
              grandTotal: item.grandTotal,
              totalPaid: item.totalPaid,
              balanceDue: item.balanceDue,
              ratePerKg: item.ratePerKg,
              metalPaidGrossWeight: item.metalPaidGrossWeight,
              metalPaidPurity: item.metalPaidPurity,
              metalPaidFine: item.metalPaidFine,
              metalPaidValue: item.metalPaidValue,
              dueMode: item.dueMode,
              excessMode: item.excessMode,
              promiseDate: item.promiseDate,
              paymentStatus: item.paymentStatus,
              stockEntryCount: item.stockEntryCount,
              createdAt: item.createdAt,
              billPhotoPath: item.billPhotoPath,
              oldDueBefore: item.oldDueBefore,
              oldDueAdjustedAmount: item.oldDueAdjustedAmount,
              metalLineCount: item.metalLineCount,
            ),
          )
          .toList(growable: false);

      return SupplierProfileModel(
        id: supplier.id!,
        businessName: supplier.businessName,
        contactPersonName: supplier.contactPersonName,
        supplierType: supplier.supplierType,
        mobile: supplier.mobile,
        whatsapp: supplier.whatsapp,
        email: supplier.email,
        alternateContact: supplier.alternateContact,
        panNumber: supplier.panNumber,
        gstNumber: supplier.gstNumber,
        addressLine1: supplier.addressLine1,
        addressLine2: supplier.addressLine2,
        state: supplier.state,
        pincode: supplier.pincode,
        country: supplier.country,
        openingBalance: ledger.openingBalance,
        notes: supplier.notes,
        status: supplier.status,
        createdAt: supplier.createdAt,
        voucherDueTotal: ledger.voucherDueTotal,
        oldDueAdjustedTotal: ledger.oldDueAdjustedTotal,
        outstandingDue: ledger.outstandingDue,
        purchases: purchases,
      );
    } catch (e) {
      AppLogger.debug('Supplier profile fetch error: $e');
      return null;
    }
  }

  Future<bool> updateSupplier(SupplierProfileModel profile) async {
    try {
      return _supplierRepo.updateSupplier(profile.toSupplierModel());
    } catch (e) {
      AppLogger.debug('Supplier profile update error: $e');
      return false;
    }
  }

  Future<bool> deactivateSupplier(int supplierId) async {
    try {
      return _supplierRepo.deactivateSupplier(supplierId);
    } catch (e) {
      AppLogger.debug('Supplier deactivate error: $e');
      return false;
    }
  }
}