import 'package:drift/drift.dart';
import 'package:lotus_erp/database/db/app_database.dart';

enum SilverPurchaseInvoiceCategory { gst, nonGst }

enum SilverInputCreditStatus { eligible, notEligible }

final class SilverSupplierInvoicePolicy {
  final AppDatabase _database;

  const SilverSupplierInvoicePolicy(this._database);

  SilverPurchaseInvoiceCategory categoryFor({required bool gstEnabled}) {
    return gstEnabled
        ? SilverPurchaseInvoiceCategory.gst
        : SilverPurchaseInvoiceCategory.nonGst;
  }

  SilverInputCreditStatus creditStatusFor({required bool gstEnabled}) {
    return gstEnabled
        ? SilverInputCreditStatus.eligible
        : SilverInputCreditStatus.notEligible;
  }

  Future<String?> validate({
    required int? supplierId,
    required bool gstEnabled,
    required String supplierGstin,
    required String supplierInvoiceNo,
    required bool hasBillAttachment,
    required String currentBatchCode,
  }) async {
    if (supplierId == null) {
      return 'Select a saved supplier profile before saving this silver batch.';
    }

    final invoiceNo = supplierInvoiceNo.trim();
    if (gstEnabled && invoiceNo.isEmpty) {
      return 'Supplier invoice number is required for GST purchase.';
    }

    final gstin = supplierGstin.trim().toUpperCase();
    if (gstEnabled &&
        gstin.isNotEmpty &&
        !RegExp(r'^[0-9A-Z]{15}$').hasMatch(gstin)) {
      return 'Supplier GSTIN must be a valid 15-character GSTIN for GST purchase.';
    }

    if (gstEnabled && !hasBillAttachment) {
      return 'Attach supplier bill photo or PDF before saving a GST purchase.';
    }

    if (invoiceNo.isNotEmpty) {
      final duplicate = await hasDuplicateInvoice(
        supplierId: supplierId,
        supplierInvoiceNo: invoiceNo,
        currentBatchCode: currentBatchCode,
      );
      if (duplicate) {
        return 'This supplier invoice number is already recorded for the selected supplier.';
      }
    }

    return null;
  }

  Future<bool> hasDuplicateInvoice({
    required int supplierId,
    required String supplierInvoiceNo,
    required String currentBatchCode,
  }) async {
    final invoiceNo = supplierInvoiceNo.trim();
    if (invoiceNo.isEmpty) {
      return false;
    }

    try {
      final rows = await _database.customSelect(
        '''
        SELECT 1
        FROM purchase_vouchers
        WHERE supplier_id = ?
          AND UPPER(TRIM(COALESCE(supplier_invoice_no, ''))) = UPPER(TRIM(?))
          AND voucher_no <> ?
        LIMIT 1
        ''',
        variables: [
          Variable.withInt(supplierId),
          Variable.withString(invoiceNo),
          Variable.withString(currentBatchCode),
        ],
      ).get();
      return rows.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

extension SilverPurchaseInvoiceCategoryLabel on SilverPurchaseInvoiceCategory {
  String get storageValue {
    return switch (this) {
      SilverPurchaseInvoiceCategory.gst => 'GST_PURCHASE',
      SilverPurchaseInvoiceCategory.nonGst => 'NON_GST_PURCHASE',
    };
  }

  String get label {
    return switch (this) {
      SilverPurchaseInvoiceCategory.gst => 'GST Purchase',
      SilverPurchaseInvoiceCategory.nonGst => 'Non-GST Purchase',
    };
  }
}

extension SilverInputCreditStatusLabel on SilverInputCreditStatus {
  String get storageValue {
    return switch (this) {
      SilverInputCreditStatus.eligible => 'ITC_ELIGIBLE',
      SilverInputCreditStatus.notEligible => 'NO_ITC',
    };
  }

  String get label {
    return switch (this) {
      SilverInputCreditStatus.eligible => 'ITC Eligible',
      SilverInputCreditStatus.notEligible => 'No ITC',
    };
  }
}
