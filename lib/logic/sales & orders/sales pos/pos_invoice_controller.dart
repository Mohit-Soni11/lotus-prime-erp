// ==========================================
// FILE: pos_invoice_controller.dart
// TYPE: Business Logic Controller
// DESCRIPTION: Generates invoice snapshots, PDF output, printing, sharing, and persistence workflows.
// ==========================================

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

//  Smart folder configuration dependencies
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

//  Database persistence dependencies
import '../../../database/db/app_database.dart';

import '../../../logic/sales & orders/sales pos/pos_billing_controller.dart';
import '../../../models/sales & orders/sales_pos_models/pos_invoice_model.dart';
import '../../../models/sales & orders/sales_pos_models/sales_pos_models.dart';
import '../../../models/sales & orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../repositories/sales & orders/pos/pos_checkout_repository.dart';
import '../../../models/setting/billing_setup/sales_billing_model.dart';
import '../../../repositories/setting/billing_setup/sales_billing_repo.dart';
import '../../../repositories/setting/shop_setup/shop_setup_repository.dart';
import '../../../repositories/setting/shop_setup/shop_session_manager.dart';

class BillSettings {
  bool showHuid;
  bool showPcs;
  bool showGrossWt;
  bool showLessWt;
  bool showNetWt;
  bool showPurity;
  bool showRate;
  bool showMaking;
  bool showAmount;
  bool showExchangeBreakdown;
  String footerMessage;
  String termsAndConditions;
  String returnPolicyText;
  String buybackPolicyText;

  BillSettings({
    this.showHuid = false,
    this.showPcs = true,
    this.showGrossWt = true,
    this.showLessWt = true,
    this.showNetWt = true,
    this.showPurity = true,
    this.showRate = true,
    this.showMaking = true,
    this.showAmount = true,
    this.showExchangeBreakdown = false,
    this.footerMessage = 'Thank you for shopping with us! Visit us again.',
    this.termsAndConditions = '',
    this.returnPolicyText = '',
    this.buybackPolicyText = '',
  });
}

class InvoicePrintConfig {
  BillSettings retailNormal = BillSettings();
  BillSettings retailGst = BillSettings();
  BillSettings wholesaleNormal = BillSettings();
  BillSettings wholesaleGst = BillSettings();
}

enum InvoiceGenState { idle, generating, ready, error }

class PosInvoiceController extends ChangeNotifier {
  final PosBillingController billing;
  final ShopSetupRepository _shopRepo = ShopSetupRepository();
  final SalesBillingRepo _salesBillingRepo = SalesBillingRepo();

  final InvoicePrintConfig printConfig = InvoicePrintConfig();
  final Map<MetalType, BillSettings> metalPrintSettings = {};

  PosInvoiceController({required this.billing});

  InvoiceGenState genState = InvoiceGenState.idle;
  PosInvoiceModel? invoice;
  Uint8List? pdfBytes;
  String? errorMessage;

  //  Database save state
  bool isSavedToDb = false;
  int? savedBillDbId;
  final AppDatabase _db = AppDatabase();
  final PosCheckoutRepository _checkoutRepo = PosCheckoutRepository();

  PrintFormat selectedFormat = PrintFormat.a4;
  int printCopies = 1;
  bool includeDuplicateStamp = false;

  DateTime? dueDate;

  String _realShopName = "Lotus Jewellers";
  String _realShopAddress = "Address not set";
  String _realShopPhone = "Phone not set";
  String _realShopGstin = "Not Registered";

  BillSettings getActiveConfig(BillingMode mode, BillType type) {
    if (mode == BillingMode.retail) {
      return type == BillType.normal
          ? printConfig.retailNormal
          : printConfig.retailGst;
    } else {
      return type == BillType.normal
          ? printConfig.wholesaleNormal
          : printConfig.wholesaleGst;
    }
  }

  List<MetalType> get presentMetals {
    final saleItems = invoice?.saleItems ?? billing.saleItems;
    final oldGoldItems = invoice?.oldGoldItems ?? billing.oldGoldItems;
    final present = <MetalType>{
      ...saleItems.map((item) => item.metal),
      ...oldGoldItems.map((item) => item.metal),
    };

    const ordered = [
      MetalType.gold,
      MetalType.silver,
      MetalType.platinum,
      MetalType.diamond,
    ];
    return ordered.where(present.contains).toList();
  }

  BillSettings getMetalConfig(MetalType metal) {
    return metalPrintSettings[metal] ??
        getActiveConfig(billing.billingMode, billing.billType);
  }

  Future<void> toggleMetalCustomization(MetalType metal, String key) async {
    final config = getMetalConfig(metal);
    metalPrintSettings[metal] = config;

    switch (key) {
      case 'huid':
        config.showHuid = !config.showHuid;
        break;
      case 'pcs':
        config.showPcs = !config.showPcs;
        break;
      case 'gw':
        config.showGrossWt = !config.showGrossWt;
        break;
      case 'lw':
        config.showLessWt = !config.showLessWt;
        break;
      case 'net':
        config.showNetWt = !config.showNetWt;
        break;
      case 'purity':
        config.showPurity = !config.showPurity;
        break;
      case 'rate':
        config.showRate = !config.showRate;
        break;
      case 'making':
        config.showMaking = !config.showMaking;
        break;
      case 'amount':
        config.showAmount = !config.showAmount;
        break;
      case 'exchange':
        config.showExchangeBreakdown = !config.showExchangeBreakdown;
        break;
    }

    if (invoice != null) {
      pdfBytes = await _buildPdf(invoice!, selectedFormat);
    }
    notifyListeners();
  }

  Future<void> _loadMetalBillingSettings(PosInvoiceModel inv) async {
    final settings = <MetalType, BillSettings>{};

    for (final metal in _collectMetals(inv)) {
      final setup = await _salesBillingRepo.fetchForMetal(metal.name);
      settings[metal] = _settingsFromBillingSetup(setup);
    }

    metalPrintSettings
      ..clear()
      ..addAll(settings);
  }

  List<MetalType> _collectMetals(PosInvoiceModel inv) {
    final present = <MetalType>{
      ...inv.saleItems.map((item) => item.metal),
      ...inv.oldGoldItems.map((item) => item.metal),
    };
    const ordered = [
      MetalType.gold,
      MetalType.silver,
      MetalType.platinum,
      MetalType.diamond,
    ];
    return ordered.where(present.contains).toList();
  }

  BillSettings _settingsFromBillingSetup(SalesBillingModel model) {
    return BillSettings(
      showHuid: model.showHuid,
      showPcs: model.showPieces,
      showGrossWt: model.showGrossWeight,
      showLessWt: model.showLessWeight,
      showNetWt: model.showNetWeight,
      showPurity: model.showPurity,
      showRate: model.showRate,
      showMaking: model.showMakingCharges,
      showAmount: model.showTotalValue,
      showExchangeBreakdown: model.showOldGoldLine,
      footerMessage: model.footerMessage,
      termsAndConditions: model.termsAndConditions,
      returnPolicyText: model.returnPolicyText,
      buybackPolicyText: model.buybackPolicyText,
    );
  }

  Future<void> updatePrintOptions(
      {required int copies, required bool duplicate}) async {
    printCopies = copies;
    includeDuplicateStamp = duplicate;
    if (invoice != null) {
      pdfBytes = await _buildPdf(invoice!, selectedFormat);
      notifyListeners();
    }
  }

  Future<void> toggleCustomization(
      String key, BillingMode mode, BillType type) async {
    BillSettings config = getActiveConfig(mode, type);

    switch (key) {
      case 'huid':
        config.showHuid = !config.showHuid;
        break;
      case 'pcs':
        config.showPcs = !config.showPcs;
        break;
      case 'gw':
        config.showGrossWt = !config.showGrossWt;
        break;
      case 'lw':
        config.showLessWt = !config.showLessWt;
        break;
      case 'making':
        config.showMaking = !config.showMaking;
        break;
      case 'exchange':
        config.showExchangeBreakdown = !config.showExchangeBreakdown;
        break;
    }

    if (invoice != null &&
        invoice!.billingMode == mode &&
        invoice!.billType == type) {
      pdfBytes = await _buildPdf(invoice!, selectedFormat);
    }
    notifyListeners();
  }

  Future<void> _fetchRealShopData() async {
    try {
      final String activeTenantId =
          await ShopSessionManager.getPermanentTenantId();
      final shopData = await _shopRepo.fetchExistingSetup(activeTenantId);

      if (shopData != null) {
        final basicInfo = shopData['basic_info'] as Map<String, dynamic>?;
        final addressData = shopData['address'] as Map<String, dynamic>?;
        final taxData = shopData['tax_compliance'] as Map<String, dynamic>?;

        if (basicInfo != null) {
          final brandName = basicInfo['brand_display_name']?.toString() ?? '';
          final displayName = basicInfo['display_name']?.toString() ?? '';
          _realShopName = brandName.isNotEmpty
              ? brandName
              : displayName.isNotEmpty
                  ? displayName
                  : "Lotus Jewellers";

          final shopPhone = basicInfo['shop_phone']?.toString() ?? '';
          final ownerPhone = basicInfo['owner_phone']?.toString() ?? '';
          _realShopPhone = shopPhone.isNotEmpty
              ? shopPhone
              : ownerPhone.isNotEmpty
                  ? ownerPhone
                  : "Phone not set";
        }

        if (addressData != null) {
          final addrLine = addressData['addr1']?.toString() ?? '';
          final city = addressData['city']?.toString() ?? '';
          final state = addressData['state']?.toString() ?? '';
          final pincode = addressData['pincode']?.toString() ?? '';

          final parts = [addrLine, city, state, pincode]
              .where((p) => p.isNotEmpty)
              .toList();
          _realShopAddress =
              parts.isNotEmpty ? parts.join(', ') : "Address not set";
        }

        if (taxData != null) {
          final gstin = taxData['gstin']?.toString() ?? '';
          _realShopGstin = gstin.isNotEmpty ? gstin : "Not Registered";
        }

        debugPrint(
            " [INVOICE] Shop data loaded: $_realShopName | $_realShopPhone | $_realShopAddress");
      } else {
        debugPrint(" [INVOICE] No shop profile found in DB. Using defaults.");
        _realShopName = "Shop Name Not Set";
        _realShopAddress = "Please complete Shop Setup";
        _realShopPhone = "Phone not set";
      }
    } catch (e) {
      debugPrint(" [INVOICE] Error fetching shop data: $e");
      _realShopName =
          billing.shopName.isNotEmpty ? billing.shopName : "Lotus Jewellers";
    }
  }

  PosInvoiceModel _buildInvoiceSnapshot() {
    return PosInvoiceModel(
      invoiceNumber: billing.formattedInvoice,
      invoiceDate: DateTime.now(),
      billType: billing.billType,
      billingMode: billing.billingMode,
      shopName: _realShopName,
      shopAddress: _realShopAddress,
      shopPhone: _realShopPhone,
      shopGstin: _realShopGstin,
      customerName: billing.nameCtrl.text,
      customerMobile: billing.mobileCtrl.text,
      customerCity: billing.cityCtrl.text,
      customerPan: billing.panCtrl.text,
      customerGstin: billing.gstCtrl.text,
      oldGoldMode: billing.oldGoldMode,
      saleItems: List.from(billing.saleItems),
      oldGoldItems: List.from(billing.oldGoldItems),
      grossAmount: billing.grossAmount,
      discountAmount: billing.discountAmount,
      taxableAmount: billing.taxableAmount,
      cgst: billing.cgst,
      sgst: billing.sgst,
      totalGst: billing.totalGst,
      totalOldGoldDeduction: billing.oldGoldCashDeduction,
      grandTotal: billing.grandTotal,
      totalMakingCharge: billing.totalMakingCharge,
      cashPaid: double.tryParse(billing.cashCtrl.text) ?? 0,
      upiPaid: double.tryParse(billing.upiCtrl.text) ?? 0,
      cardPaid: double.tryParse(billing.cardCtrl.text) ?? 0,
      advancePaid: double.tryParse(billing.advCtrl.text) ?? 0,
      balanceDue: billing.balanceDue,
      promiseDate: dueDate,
    );
  }

  // ==========================================
  //  STEP 1: Reserve the next sequence number from the database.
  // Drift tables do not expose count() directly here. 
  //         select().get() se list lo, .length lo
  // ==========================================
  Future<void> _syncNextInvoicePreview() async {
    if (billing.isCurrentSaleCommitted) {
      return;
    }

    try {
      final nextSequence = await _checkoutRepo.fetchNextInvoiceSequence(
        invoicePrefix: billing.invoicePrefix,
        shopInitials: billing.shopInitials,
        financialYear: billing.currentFinancialYear,
      );
      billing.updateInvoiceSequencePreview(nextSequence);
    } catch (_) {
      // Fall back to the invoice already held in preview memory.
    }
  }

  // ==========================================
  //  STEP 2: Persist the bill and line items to the database.
  // ==========================================
  PosInvoiceModel _copyInvoiceWithNumber(
    PosInvoiceModel source,
    String invoiceNumber,
  ) {
    return PosInvoiceModel(
      invoiceNumber: invoiceNumber,
      invoiceDate: source.invoiceDate,
      billType: source.billType,
      billingMode: source.billingMode,
      shopName: source.shopName,
      shopAddress: source.shopAddress,
      shopPhone: source.shopPhone,
      shopGstin: source.shopGstin,
      customerName: source.customerName,
      customerMobile: source.customerMobile,
      customerCity: source.customerCity,
      customerPan: source.customerPan,
      customerGstin: source.customerGstin,
      oldGoldMode: source.oldGoldMode,
      saleItems: source.saleItems,
      oldGoldItems: source.oldGoldItems,
      grossAmount: source.grossAmount,
      discountAmount: source.discountAmount,
      taxableAmount: source.taxableAmount,
      cgst: source.cgst,
      sgst: source.sgst,
      totalGst: source.totalGst,
      totalOldGoldDeduction: source.totalOldGoldDeduction,
      grandTotal: source.grandTotal,
      cashPaid: source.cashPaid,
      upiPaid: source.upiPaid,
      cardPaid: source.cardPaid,
      advancePaid: source.advancePaid,
      balanceDue: source.balanceDue,
      totalMakingCharge: source.totalMakingCharge,
      promiseDate: source.promiseDate,
    );
  }

  Future<void> _saveBillToDatabase(PosInvoiceModel inv) async {
    if (isSavedToDb) return;

    if (billing.isCurrentSaleCommitted) {
      final existingBill = await (_db.select(_db.bills)
            ..where((tbl) => tbl.billNo.equals(inv.invoiceNumber)))
          .getSingleOrNull();
      savedBillDbId = existingBill?.id;
      isSavedToDb = true;
      return;
    }

    // --- Insert the bill header record. ---
    final result = await _checkoutRepo.finalizeSale(
      invoice: inv,
      customerId: billing.selectedCustomer?.id,
    );

    savedBillDbId = result.billId;

    // --- Insert each sale line item. ---
    /*
    for (final item in billing.saleItems) {
      final grossWt = double.tryParse(item.grossCtrl.text) ?? 0.0;
      final itemName = item.descCtrl.text.isNotEmpty
          ? item.descCtrl.text
          : item.metal.displayName;

      await _db.into(_db.billItems).insert(
            BillItemsCompanion(
              billId: Value(billId),
              itemName: Value(itemName),
              huid: Value(
                  item.huidCtrl.text.isNotEmpty ? item.huidCtrl.text : null),
              purity: Value(
                  item.purityCtrl.text.isNotEmpty ? item.purityCtrl.text : ''),
              grossWeight: Value(grossWt),
              netWeight: Value(item.netWt),
              rate: Value(item.rate),
              makingCharge: Value(item.makingAmt),
              itemTotal: Value(item.totalValue),
            ),
          );
    }

    */
    billing.markCurrentSaleCommitted(result.invoiceNumber);
    billing.updateInvoiceSequencePreview(result.invoiceSequence + 1);

    if (result.invoiceNumber != inv.invoiceNumber) {
      invoice = _copyInvoiceWithNumber(inv, result.invoiceNumber);
      pdfBytes = await _buildPdf(invoice!, selectedFormat);
    }

    isSavedToDb = true;
  }

  Future<void> finalizeInvoiceIfNeeded() async {
    if (invoice == null) {
      await generateInvoice();
    }
    if (invoice == null) return;
    try {
      await _saveBillToDatabase(invoice!);
    } catch (e) {
      errorMessage = e.toString();
      genState = InvoiceGenState.error;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> generateInvoice() async {
    genState = InvoiceGenState.generating;
    errorMessage = null;
    if (!billing.isCurrentSaleCommitted) {
      isSavedToDb = false;
      savedBillDbId = null;
    }
    notifyListeners();
    try {
      await Future.wait([
        _fetchRealShopData(),
        _syncNextInvoicePreview(),
      ]);

      dueDate = billing.promiseDate;
      invoice = _buildInvoiceSnapshot();
      await _loadMetalBillingSettings(invoice!);

      pdfBytes = await _buildPdf(invoice!, selectedFormat);
      genState = InvoiceGenState.ready;
    } catch (e) {
      errorMessage = e.toString();
      genState = InvoiceGenState.error;
    }
    notifyListeners();
  }

  Future<Uint8List> _buildPdf(PosInvoiceModel inv, PrintFormat fmt) async {
    final doc = pw.Document();
    PdfPageFormat pageFormat;
    switch (fmt) {
      case PrintFormat.a4:
        pageFormat = PdfPageFormat.a4;
        break;
      case PrintFormat.thermal3inch:
        pageFormat = const PdfPageFormat(
            80 * PdfPageFormat.mm, 250 * PdfPageFormat.mm,
            marginAll: 4 * PdfPageFormat.mm);
        break;
      case PrintFormat.thermal2inch:
        pageFormat = const PdfPageFormat(
            57 * PdfPageFormat.mm, 250 * PdfPageFormat.mm,
            marginAll: 3 * PdfPageFormat.mm);
        break;
    }

    for (int i = 0; i < printCopies; i++) {
      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: fmt == PrintFormat.a4
              ? const pw.EdgeInsets.all(24)
              : const pw.EdgeInsets.all(6),
          build: (pw.Context context) {
            final layout = fmt == PrintFormat.a4
                ? _buildA4Layout(inv)
                : _buildThermalLayout(inv, fmt);
            if (includeDuplicateStamp) {
              return pw.Stack(
                alignment: pw.Alignment.center,
                children: [
                  pw.Center(
                      child: pw.Transform.rotate(
                          angle: 0.785,
                          child: pw.Text("DUPLICATE",
                              style: pw.TextStyle(
                                  color: PdfColors.grey300,
                                  fontSize: fmt == PrintFormat.a4 ? 60 : 25,
                                  fontWeight: pw.FontWeight.bold)))),
                  layout,
                ],
              );
            }
            return layout;
          },
        ),
      );
    }
    return doc.save();
  }

  pw.Widget _buildA4Layout(PosInvoiceModel inv) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _pdfA4Header(inv),
        pw.SizedBox(height: 16),
        _pdfCustomerBlock(inv),
        pw.SizedBox(height: 14),
        _pdfItemsTable(inv),
        pw.SizedBox(height: 14),
        _pdfTotalsBlock(inv),
        pw.SizedBox(height: 14),
        _pdfPaymentBlock(inv),
        pw.Spacer(),
        _pdfFooter(inv),
      ],
    );
  }

  pw.Widget _pdfA4Header(PosInvoiceModel inv) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(inv.shopName,
              style:
                  pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.Text(inv.shopAddress,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.Text("Ph: ${inv.shopPhone}",
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          if (inv.billType == BillType.gst && inv.shopGstin != "Not Registered")
            pw.Text("GSTIN: ${inv.shopGstin}",
                style: const pw.TextStyle(fontSize: 9)),
        ]),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          if (inv.billType == BillType.gst)
            pw.Text("TAX INVOICE",
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.amber800)),
          pw.SizedBox(height: 4),
          pw.Text("No: ${inv.invoiceNumber}",
              style: const pw.TextStyle(fontSize: 10)),
          pw.Text(
              "Date: ${inv.invoiceDate.day}/${inv.invoiceDate.month}/${inv.invoiceDate.year}",
              style: const pw.TextStyle(fontSize: 10)),
        ]),
      ],
    );
  }

  pw.Widget _pdfCustomerBlock(PosInvoiceModel inv) {
    final name =
        inv.customerName.isEmpty ? "Walk-in Customer" : inv.customerName;
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(6))),
      child: pw.Row(children: [
        pw.Expanded(
            child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("BILL TO",
                style:
                    const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            pw.SizedBox(height: 3),
            pw.Text(name,
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            if (inv.customerMobile.isNotEmpty)
              pw.Text(inv.customerMobile,
                  style: const pw.TextStyle(fontSize: 9)),
          ],
        )),
      ]),
    );
  }

  pw.Widget _pdfItemsTable(PosInvoiceModel inv) {
    final isWholesale = inv.billingMode == BillingMode.wholesale;
    final itemsByMetal = <MetalType, List<SaleItemModel>>{};
    for (final item in inv.saleItems) {
      itemsByMetal.putIfAbsent(item.metal, () => []).add(item);
    }

    return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          ..._collectMetals(inv)
              .where((metal) => (itemsByMetal[metal] ?? []).isNotEmpty)
              .map((metal) {
            final items = itemsByMetal[metal]!;
            final activeConfig = getMetalConfig(metal);
            final sectionTotal =
                items.fold(0.0, (sum, item) => sum + item.totalValue);

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8, vertical: 5),
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("${metal.displayName} INVOICE SECTION",
                          style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey800)),
                      pw.Text("Section Total: Rs ${sectionTotal.toStringAsFixed(2)}",
                          style: pw.TextStyle(
                              fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
                pw.Table(
                  border:
                      pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.amber50),
                      children: [
                        _th("#"),
                        _th("Item Description"),
                        if (activeConfig.showPurity) _th("Purity"),
                        if (activeConfig.showGrossWt) _th("Gross(g)"),
                        if (activeConfig.showLessWt) _th("Less(g)"),
                        if (activeConfig.showNetWt)
                          _th(isWholesale ? "Fine(g)" : "Net(g)"),
                        if (activeConfig.showRate) _th("Rate"),
                        if (activeConfig.showMaking)
                          _th(isWholesale ? "Labour" : "Making"),
                        if (activeConfig.showAmount) _th("Amount"),
                      ],
                    ),
                    ...items.asMap().entries.map((e) {
                      final i = e.value;
                      String desc = i.descCtrl.text.isNotEmpty
                          ? i.descCtrl.text
                          : "${i.metal.name.toUpperCase()} ITEM";
                      if (activeConfig.showHuid &&
                          i.huidCtrl.text.isNotEmpty) {
                        desc += "\n[HUID: ${i.huidCtrl.text}]";
                      }
                      if (activeConfig.showPcs && i.pcs > 1) {
                        desc += " (${i.pcs} pcs)";
                      }

                      return pw.TableRow(children: [
                        _cell("${e.key + 1}"),
                        _cell(desc),
                        if (activeConfig.showPurity) _cell(_formatPurity(i)),
                        if (activeConfig.showGrossWt)
                          _cell(i.grossCtrl.text.isNotEmpty
                              ? i.grossCtrl.text
                              : "0.000"),
                        if (activeConfig.showLessWt)
                          _cell(i.totalLessWt.toStringAsFixed(3)),
                        if (activeConfig.showNetWt)
                          _cell(isWholesale
                              ? i.fineWt.toStringAsFixed(3)
                              : i.netWt.toStringAsFixed(3)),
                        if (activeConfig.showRate)
                          _cell(i.rate.toStringAsFixed(0)),
                        if (activeConfig.showMaking)
                          _cell(isWholesale
                              ? i.wholesaleLabourAmt.toStringAsFixed(0)
                              : i.makingAmt.toStringAsFixed(0)),
                        if (activeConfig.showAmount)
                          _cell(i.totalValue.toStringAsFixed(2)),
                      ]);
                    }),
                  ],
                ),
                pw.SizedBox(height: 10),
              ],
            );
          }),
        ]);
  }

  pw.Widget _th(String text) => pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text,
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)));

  pw.Widget _cell(String text) => pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 8)));

  String _formatPurity(SaleItemModel item) {
    final text = item.purityCtrl.text.trim();
    final tunch = item.tunch;

    switch (item.metal) {
      case MetalType.gold:
        final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(text);
        final ktVal = match != null
            ? double.tryParse(match.group(1)!)
            : (tunch > 0 ? tunch : null);

        if (ktVal != null && ktVal > 0) {
          final pct = _ktToPercent(ktVal);
          return '${ktVal % 1 == 0 ? ktVal.toInt() : ktVal}KT ($pct%)';
        }
        return text.isNotEmpty ? text : '-';

      case MetalType.silver:
        if (tunch > 0) {
          final clean = tunch % 1 == 0
              ? tunch.toInt().toString()
              : tunch.toStringAsFixed(1);
          return '$clean%';
        }
        if (text.isNotEmpty) return '$text%';
        return '-';

      case MetalType.platinum:
        if (tunch > 0) return '${tunch.toStringAsFixed(1)}%';
        if (text.isNotEmpty) return text;
        return '-';

      case MetalType.diamond:
        if (text.isNotEmpty) return text;
        if (tunch > 0) return '${tunch.toStringAsFixed(2)}ct';
        return '-';
    }
  }

  String _ktToPercent(double kt) {
    switch (kt.round()) {
      case 9:
        return '37.5';
      case 10:
        return '41.7';
      case 12:
        return '50.0';
      case 14:
        return '58.5';
      case 18:
        return '75.0';
      case 20:
        return '83.3';
      case 21:
        return '87.5';
      case 22:
        return '91.60';
      case 23:
        return '95.8';
      case 24:
        return '99.99';
      default:
        final pct = (kt / 24) * 100;
        return pct.toStringAsFixed(1);
    }
  }

  pw.Widget _pdfTotalsBlock(PosInvoiceModel inv) {
    final showExchangeBreakdown = inv.oldGoldItems
        .any((item) => getMetalConfig(item.metal).showExchangeBreakdown);
    // Use the invoice net payable value directly.
    return pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
      pw.SizedBox(
        width: 240,
        child: pw.Column(children: [
          _totalRow("Gross Amount", inv.grossAmount),
          if (inv.discountAmount > 0)
            _totalRow("Discount", -inv.discountAmount, isDeduction: true),
          if (inv.billType == BillType.gst) ...[
            _totalRow("CGST", inv.cgst),
            _totalRow("SGST", inv.sgst),
          ],
          if (inv.totalOldGoldDeduction > 0) ...[
            () {
              final goldExchange = inv.oldGoldItems
                  .where((i) => i.metal == MetalType.gold)
                  .fold(0.0, (sum, i) => sum + i.totalValue);
              final silverExchange = inv.oldGoldItems
                  .where((i) => i.metal == MetalType.silver)
                  .fold(0.0, (sum, i) => sum + i.totalValue);
              final platinumExchange = inv.oldGoldItems
                  .where((i) => i.metal == MetalType.platinum)
                  .fold(0.0, (sum, i) => sum + i.totalValue);

              if (!showExchangeBreakdown) {
                return _totalRow(
                  "Less: Old Metal Exchange",
                  -inv.totalOldGoldDeduction,
                  isDeduction: true,
                );
              }
              return pw.Column(children: [
                if (goldExchange > 0)
                  _totalRow("Less: Gold Exchange", -goldExchange,
                      isDeduction: true),
                if (silverExchange > 0)
                  _totalRow("Less: Silver Exchange", -silverExchange,
                      isDeduction: true),
                if (platinumExchange > 0)
                  _totalRow("Less: Platinum Exchange", -platinumExchange,
                      isDeduction: true),
                if (goldExchange == 0 &&
                    silverExchange == 0 &&
                    platinumExchange == 0)
                  _totalRow(
                      "Less: Old Metal Exchange", -inv.totalOldGoldDeduction,
                      isDeduction: true),
              ]);
            }(),
          ],
          pw.Divider(color: PdfColors.amber800),
          // Use the invoice net payable value directly.
          _totalRow("GRAND TOTAL", inv.netPayable, isBold: true, isGrand: true),
        ]),
      ),
    ]);
  }

  pw.Widget _totalRow(String label, double amount,
      {bool isBold = false, bool isDeduction = false, bool isGrand = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style: pw.TextStyle(
                    fontSize: isGrand ? 11 : 9,
                    fontWeight:
                        isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
            pw.Text(
                "${isDeduction ? '- ' : ''}Rs ${amount.abs().toStringAsFixed(2)}",
                style: pw.TextStyle(
                    fontSize: isGrand ? 12 : 9,
                    fontWeight:
                        isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          ]),
    );
  }

  pw.Widget _pdfPaymentBlock(PosInvoiceModel inv) {
    final double totalCashPaid = inv.totalPaid;

    final List<Map<String, dynamic>> payments = [
      if (inv.cashPaid > 0) {'label': 'Cash', 'amount': inv.cashPaid},
      if (inv.upiPaid > 0)
        {'label': 'UPI / Bank Transfer', 'amount': inv.upiPaid},
      if (inv.cardPaid > 0) {'label': 'Card', 'amount': inv.cardPaid},
      if (inv.advancePaid > 0) {'label': 'Advance', 'amount': inv.advancePaid},
    ];

    final bool hasDue = inv.balanceDue > 0.5;
    final bool isPaid = !hasDue;

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "PAYMENT RECEIVED",
                style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey600),
              ),
              if (isPaid)
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.green100,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(" FULLY PAID",
                      style: pw.TextStyle(
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800)),
                ),
            ],
          ),
          pw.SizedBox(height: 8),
          if (payments.isNotEmpty) ...[
            pw.Wrap(
              spacing: 12,
              runSpacing: 6,
              children: payments.map((p) {
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(4)),
                    border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
                  ),
                  child: pw.RichText(
                    text: pw.TextSpan(children: [
                      pw.TextSpan(
                        text: "${p['label']}:  ",
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.TextSpan(
                        text:
                            "Rs ${(p['amount'] as double).toStringAsFixed(2)}",
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black),
                      ),
                    ]),
                  ),
                );
              }).toList(),
            ),
            pw.SizedBox(height: 10),
          ],
          if (payments.length > 1) ...[
            pw.Divider(color: PdfColors.grey200, thickness: 0.5),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Total Paid",
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey600)),
                pw.Text("Rs ${totalCashPaid.toStringAsFixed(2)}",
                    style: pw.TextStyle(
                        fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 6),
          ],
          pw.Divider(color: PdfColors.grey300, thickness: 0.8),
          pw.SizedBox(height: 6),
          if (hasDue) ...[
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Balance Outstanding",
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.red700)),
                    if (inv.promiseDate != null)
                      pw.Text(
                        "Pay by: ${inv.promiseDate!.day.toString().padLeft(2, '0')}/${inv.promiseDate!.month.toString().padLeft(2, '0')}/${inv.promiseDate!.year}",
                        style: pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.orange700,
                            fontStyle: pw.FontStyle.italic),
                      ),
                  ],
                ),
                pw.Text(
                  "Rs ${inv.balanceDue.toStringAsFixed(2)}",
                  style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red700),
                ),
              ],
            ),
          ] else ...[
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Balance Outstanding",
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey600)),
                pw.Text("Nil",
                    style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green700)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _pdfFooter(PosInvoiceModel inv) {
    final footerMessages = _collectMetals(inv)
        .map((metal) => getMetalConfig(metal).footerMessage.trim())
        .where((message) => message.isNotEmpty)
        .toSet()
        .toList();
    final footerMessage = footerMessages.isEmpty
        ? "Thank you for shopping with us!"
        : footerMessages.join(" | ");

    return pw.Column(children: [
      pw.Divider(color: PdfColors.grey300),
      pw.SizedBox(height: 6),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Expanded(
            child: pw.Text(footerMessage,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ),
        pw.Text("${inv.shopName}  E&OE",
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
      ]),
    ]);
  }

  pw.Widget _buildThermalLayout(PosInvoiceModel inv, PrintFormat fmt) {
    final fontSize = fmt == PrintFormat.thermal2inch ? 7.0 : 8.5;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(inv.shopName,
            style:
                pw.TextStyle(fontSize: 12.0, fontWeight: pw.FontWeight.bold)),
        pw.Text("No: ${inv.invoiceNumber}",
            style: pw.TextStyle(fontSize: fontSize)),
        pw.Divider(color: PdfColors.grey400),
        pw.Text("GRAND TOTAL: Rs ${inv.netPayable.toStringAsFixed(2)}",
            style: pw.TextStyle(
                fontSize: fontSize + 2, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  Future<void> printInvoice(PrintFormat format) async {
    await finalizeInvoiceIfNeeded();
    if (pdfBytes == null) return;
    if (format != selectedFormat) {
      selectedFormat = format;
      pdfBytes = await _buildPdf(invoice!, format);
      notifyListeners();
    }
    await Printing.layoutPdf(onLayout: (_) async => pdfBytes!);
  }

  Future<void> openDirectWhatsAppChat() async {
    await finalizeInvoiceIfNeeded();
    if (invoice == null || invoice!.customerMobile.isEmpty) return;

    final phone = invoice!.customerMobile.replaceAll(RegExp(r'\D'), '');
    final cleanPhone = phone.length == 10 ? "91$phone" : phone;

    final customerName =
        invoice!.customerName.isNotEmpty ? invoice!.customerName : "Customer";
    final textMessage =
        "Dear $customerName,\n\nThank you for shopping at *${invoice!.shopName}*!\n\nHere are your invoice details:\n*Invoice No:* ${invoice!.invoiceNumber}\n*Total Amount:* Rs ${invoice!.netPayable.toStringAsFixed(2)}\n\nVisit again!";

    final url = Uri.parse(
        "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(textMessage)}");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch WhatsApp");
    }
  }

  //  Smart CRM folder directory management
  Future<String?> downloadPdf() async {
    await finalizeInvoiceIfNeeded();
    if (pdfBytes == null || invoice == null) return null;

    try {
      final prefs = await SharedPreferences.getInstance();
      String? baseDirPath = prefs.getString('invoice_base_folder');

      if (baseDirPath == null || !await Directory(baseDirPath).exists()) {
        baseDirPath = await FilePicker.platform.getDirectoryPath(
          dialogTitle: "Select Folder to Save All Bills",
        );

        if (baseDirPath == null) {
          debugPrint("Folder selection cancelled by user");
          return null;
        }
        await prefs.setString('invoice_base_folder', baseDirPath);
      }

      String mobileFolder =
          invoice!.customerMobile.replaceAll(RegExp(r'\D'), '');
      if (mobileFolder.isEmpty) mobileFolder = "Walk-in_Customers";

      final customerDir = Directory('$baseDirPath/$mobileFolder');
      if (!await customerDir.exists()) {
        await customerDir.create(recursive: true);
      }

      String custName =
          invoice!.customerName.isNotEmpty ? invoice!.customerName : "Customer";
      String cleanName = custName
          .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
          .replaceAll(' ', '_');
      String cleanInv =
          invoice!.invoiceNumber.replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '_');

      final fileName = "${cleanName}_$cleanInv.pdf";
      final file = File('${customerDir.path}/$fileName');

      await file.writeAsBytes(pdfBytes!);
      debugPrint("File successfully saved at: ${file.path}");

      return file.path;
    } catch (e) {
      debugPrint("Error saving file: $e");
      return null;
    }
  }

  Future<void> switchFormat(PrintFormat fmt) async {
    selectedFormat = fmt;
    notifyListeners();
    if (invoice != null) {
      pdfBytes = await _buildPdf(invoice!, fmt);
      notifyListeners();
    }
  }

  Future<void> setDueDate(DateTime? date) async {
    dueDate = date;
    if (invoice != null) {
      invoice = PosInvoiceModel(
        invoiceNumber: invoice!.invoiceNumber,
        invoiceDate: invoice!.invoiceDate,
        billType: invoice!.billType,
        billingMode: invoice!.billingMode,
        shopName: invoice!.shopName,
        shopAddress: invoice!.shopAddress,
        shopPhone: invoice!.shopPhone,
        shopGstin: invoice!.shopGstin,
        customerName: invoice!.customerName,
        customerMobile: invoice!.customerMobile,
        customerCity: invoice!.customerCity,
        customerPan: invoice!.customerPan,
        customerGstin: invoice!.customerGstin,
        oldGoldMode: invoice!.oldGoldMode,
        saleItems: invoice!.saleItems,
        oldGoldItems: invoice!.oldGoldItems,
        grossAmount: invoice!.grossAmount,
        discountAmount: invoice!.discountAmount,
        taxableAmount: invoice!.taxableAmount,
        cgst: invoice!.cgst,
        sgst: invoice!.sgst,
        totalGst: invoice!.totalGst,
        totalOldGoldDeduction: invoice!.totalOldGoldDeduction,
        grandTotal: invoice!.grandTotal,
        cashPaid: invoice!.cashPaid,
        upiPaid: invoice!.upiPaid,
        cardPaid: invoice!.cardPaid,
        advancePaid: invoice!.advancePaid,
        balanceDue: invoice!.balanceDue,
        totalMakingCharge: invoice!.totalMakingCharge,
        promiseDate: dueDate,
      );
      pdfBytes = await _buildPdf(invoice!, selectedFormat);
    }
    notifyListeners();
  }

  void reset() {
    genState = InvoiceGenState.idle;
    invoice = null;
    pdfBytes = null;
    errorMessage = null;
    isSavedToDb = false;
    savedBillDbId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    reset();
    super.dispose();
  }
}
