import 'package:drift/drift.dart';
import 'package:lotus_erp/database/db/app_database.dart';

enum GoldPurchaseInvoiceCategory {
  gst,
  nonGst,
}

enum GoldInputCreditStatus {
  eligible,
  notEligible,
}

final class GoldSupplierInvoicePolicy {
  final AppDatabase _database;

  const GoldSupplierInvoicePolicy(this._database);

  GoldPurchaseInvoiceCategory categoryFor({required bool gstEnabled}) {
    return gstEnabled
        ? GoldPurchaseInvoiceCategory.gst
        : GoldPurchaseInvoiceCategory.nonGst;
  }

  GoldInputCreditStatus creditStatusFor({required bool gstEnabled}) {
    return gstEnabled
        ? GoldInputCreditStatus.eligible
        : GoldInputCreditStatus.notEligible;
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
      return 'Select a saved supplier profile before saving this gold batch.';
    }

    final invoiceNo = supplierInvoiceNo.trim();
    if (gstEnabled && invoiceNo.isEmpty) {
      return 'Supplier invoice number is required for GST purchase.';
    }

    final gstin = supplierGstin.trim().toUpperCase();
    if (gstEnabled && gstin.isEmpty) {
      return 'Supplier GSTIN is required for GST purchase. Update the supplier profile first.';
    }

    if (gstEnabled && !RegExp(r'^[0-9A-Z]{15}$').hasMatch(gstin)) {
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

extension GoldPurchaseInvoiceCategoryLabel on GoldPurchaseInvoiceCategory {
  String get storageValue {
    return switch (this) {
      GoldPurchaseInvoiceCategory.gst => 'GST_PURCHASE',
      GoldPurchaseInvoiceCategory.nonGst => 'NON_GST_PURCHASE',
    };
  }

  String get label {
    return switch (this) {
      GoldPurchaseInvoiceCategory.gst => 'GST Purchase',
      GoldPurchaseInvoiceCategory.nonGst => 'Non-GST Purchase',
    };
  }
}

extension GoldInputCreditStatusLabel on GoldInputCreditStatus {
  String get storageValue {
    return switch (this) {
      GoldInputCreditStatus.eligible => 'ITC_ELIGIBLE',
      GoldInputCreditStatus.notEligible => 'NO_ITC',
    };
  }

  String get label {
    return switch (this) {
      GoldInputCreditStatus.eligible => 'ITC Eligible',
      GoldInputCreditStatus.notEligible => 'No ITC',
    };
  }
}
