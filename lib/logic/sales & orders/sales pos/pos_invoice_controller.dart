// ==========================================
// FILE: pos_invoice_controller.dart
// TYPE: Business Logic Controller
// DESCRIPTION: PDF generation, Customization, and Share engine.
//              ✅ UPGRADED: Smart CRM Folder Management
//              ✅ CLEANED: Removed Unused Imports (share_plus, path_provider)
// ==========================================

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

// 🚀 SMART FOLDER LOGIC IMPORTS
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

import '../../../logic/sales & orders/sales pos/pos_billing_controller.dart';
import '../../../models/sales & orders/sales_pos_models/pos_invoice_model.dart';
import '../../../models/sales & orders/sales_pos_models/sales_pos_models.dart';
import '../../../models/sales & orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../repositories/setting/shop_setup/shop_setup_repository.dart';
import '../../../repositories/setting/shop_setup/shop_session_manager.dart';

class BillSettings {
  bool showHuid = false;
  bool showPcs = true;
  bool showGrossWt = true;
  bool showLessWt = true;
  bool showMaking = true;
  // ✅ NEW: Exchange breakdown toggle
  // false = combined single line, true = har metal alag line
  bool showExchangeBreakdown = false;
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

  final InvoicePrintConfig printConfig = InvoicePrintConfig();

  PosInvoiceController({required this.billing});

  InvoiceGenState genState = InvoiceGenState.idle;
  PosInvoiceModel? invoice;
  Uint8List? pdfBytes;
  String? errorMessage;

  PrintFormat selectedFormat = PrintFormat.a4;
  int printCopies = 1;
  bool includeDuplicateStamp = false;

  // ✅ NEW: Due date for Balance Due — user set karega
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
      // ✅ FIX: Use permanent tenant ID from ShopSessionManager
      final String activeTenantId =
          await ShopSessionManager.getPermanentTenantId();
      final shopData = await _shopRepo.fetchExistingSetup(activeTenantId);

      if (shopData != null) {
        // ✅ FIX: DB keys are snake_case — 'basic_info', 'address', 'tax_compliance'
        final basicInfo = shopData['basic_info'] as Map<String, dynamic>?;
        final addressData = shopData['address'] as Map<String, dynamic>?;
        final taxData = shopData['tax_compliance'] as Map<String, dynamic>?;

        // Shop Name: brand_display_name > display_name > shop_phone fallback
        if (basicInfo != null) {
          final brandName = basicInfo['brand_display_name']?.toString() ?? '';
          final displayName = basicInfo['display_name']?.toString() ?? '';
          _realShopName = brandName.isNotEmpty
              ? brandName
              : displayName.isNotEmpty
                  ? displayName
                  : "Lotus Jewellers";

          // Phone: shop_phone first, then owner_phone
          final shopPhone = basicInfo['shop_phone']?.toString() ?? '';
          final ownerPhone = basicInfo['owner_phone']?.toString() ?? '';
          _realShopPhone = shopPhone.isNotEmpty
              ? shopPhone
              : ownerPhone.isNotEmpty
                  ? ownerPhone
                  : "Phone not set";
        }

        // Address: addr1, city, state, pincode
        if (addressData != null) {
          final addrLine = addressData['addr1']?.toString() ?? '';
          final city = addressData['city']?.toString() ?? '';
          final state = addressData['state']?.toString() ?? '';
          final pincode = addressData['pincode']?.toString() ?? '';

          // Build address — only add non-empty parts
          final parts = [addrLine, city, state, pincode]
              .where((p) => p.isNotEmpty)
              .toList();
          _realShopAddress =
              parts.isNotEmpty ? parts.join(', ') : "Address not set";
        }

        // GST: gstin from tax_compliance
        if (taxData != null) {
          final gstin = taxData['gstin']?.toString() ?? '';
          _realShopGstin = gstin.isNotEmpty ? gstin : "Not Registered";
        }

        debugPrint(
            "✅ [INVOICE] Shop data loaded: $_realShopName | $_realShopPhone | $_realShopAddress");
      } else {
        debugPrint("⚠️ [INVOICE] No shop profile found in DB. Using defaults.");
        _realShopName = "Shop Name Not Set";
        _realShopAddress = "Please complete Shop Setup";
        _realShopPhone = "Phone not set";
      }
    } catch (e) {
      debugPrint("❌ [INVOICE] Error fetching shop data: $e");
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

  Future<void> generateInvoice() async {
    genState = InvoiceGenState.generating;
    notifyListeners();
    try {
      await _fetchRealShopData();
      // ✅ FIX: billing controller ka promiseDate leke aao
      dueDate = billing.promiseDate;
      invoice = _buildInvoiceSnapshot();
      billing.nextSequence++;
      await Future.delayed(const Duration(milliseconds: 500));
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
    final activeConfig = getActiveConfig(inv.billingMode, inv.billType);

    return pw
        .Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      if (inv.saleItems.isNotEmpty) ...[
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.amber50),
              children: [
                _th("#"),
                _th("Item Description"),
                _th("Purity"),
                if (activeConfig.showGrossWt) _th("Gross(g)"),
                if (activeConfig.showLessWt) _th("Less(g)"),
                _th(isWholesale ? "Fine(g)" : "Net(g)"),
                _th("Rate"),
                if (activeConfig.showMaking)
                  _th(isWholesale ? "Labour" : "Making"),
                _th("Amount"),
              ],
            ),
            ...inv.saleItems.asMap().entries.map((e) {
              final i = e.value;
              String desc = i.descCtrl.text.isNotEmpty
                  ? i.descCtrl.text
                  : "${i.metal.name.toUpperCase()} ITEM";
              if (activeConfig.showHuid && i.huidCtrl.text.isNotEmpty)
                desc += "\n[HUID: ${i.huidCtrl.text}]";
              if (activeConfig.showPcs && i.pcs > 1) desc += " (${i.pcs} pcs)";

              return pw.TableRow(children: [
                _cell("${e.key + 1}"),
                _cell(desc),
                _cell(_formatPurity(i)),
                if (activeConfig.showGrossWt)
                  _cell(
                      i.grossCtrl.text.isNotEmpty ? i.grossCtrl.text : "0.000"),
                if (activeConfig.showLessWt)
                  _cell(i.totalLessWt.toStringAsFixed(3)),
                _cell(isWholesale
                    ? i.fineWt.toStringAsFixed(3)
                    : i.netWt.toStringAsFixed(3)),
                _cell(i.rate.toStringAsFixed(0)),
                if (activeConfig.showMaking)
                  _cell(isWholesale
                      ? i.wholesaleLabourAmt.toStringAsFixed(0)
                      : i.makingAmt.toStringAsFixed(0)),
                _cell(i.totalValue.toStringAsFixed(2)),
              ]);
            }),
          ],
        ),
      ],
    ]);
  }

  pw.Widget _th(String text) => pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text,
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)));
  pw.Widget _cell(String text) => pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 8)));

  // ✅ FIX: Purity display — metal type ke hisaab se format
  //
  // GOLD    → "18KT (75.0%)", "22KT (91.60%)", "24KT (99.99%)" etc.
  // SILVER  → "35%", "92.5%" — sirf percentage
  // PLAT    → "95.0%" ya jo text likha hai
  // DIAMOND → jo text likha hai (ct / % / grade)
  String _formatPurity(SaleItemModel item) {
    final text = item.purityCtrl.text.trim();
    final tunch = item.tunch;

    switch (item.metal) {
      // ─────────────── GOLD ───────────────
      case MetalType.gold:
        // KT number nikalo — "18KT", "18kt", "18K", ya sirf "18"
        final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(text);
        final ktVal = match != null
            ? double.tryParse(match.group(1)!)
            : (tunch > 0 ? tunch : null);

        if (ktVal != null && ktVal > 0) {
          final pct = _ktToPercent(ktVal);
          return '${ktVal % 1 == 0 ? ktVal.toInt() : ktVal}KT ($pct%)';
        }
        return text.isNotEmpty ? text : '-';

      // ─────────────── SILVER ───────────────
      case MetalType.silver:
        // Sirf % dikhao — jo number likha hai woh
        if (tunch > 0) {
          final clean = tunch % 1 == 0
              ? tunch.toInt().toString()
              : tunch.toStringAsFixed(1);
          return '$clean%';
        }
        if (text.isNotEmpty) return '$text%';
        return '-';

      // ─────────────── PLATINUM ───────────────
      case MetalType.platinum:
        if (tunch > 0) return '${tunch.toStringAsFixed(1)}%';
        if (text.isNotEmpty) return text;
        return '-';

      // ─────────────── DIAMOND ───────────────
      case MetalType.diamond:
        // Diamond ka purity text as-is dikhao (ct, grade, clarity)
        if (text.isNotEmpty) return text;
        if (tunch > 0) return '${tunch.toStringAsFixed(2)}ct';
        return '-';
    }
  }

  // KT → exact % conversion — standard industry values
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
    final activeConfig = getActiveConfig(inv.billingMode, inv.billType);
    // ✅ Professional: Net Payable = Grand Total - Exchange deduction
    final double netPayable = inv.grandTotal - inv.totalOldGoldDeduction;

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
          // Exchange deduction lines
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

              if (!activeConfig.showExchangeBreakdown) {
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
          // ✅ Grand Total = netPayable (exchange already deducted)
          _totalRow("GRAND TOTAL", netPayable, isBold: true, isGrand: true),
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
    // ✅ PROFESSIONAL STYLE (Tanishq / Malabar Gold standard)
    // Exchange pehle se Totals Block mein "Less:" ke roop mein deduct ho chuka hai
    // Payment Details mein sirf actual cash payment modes dikhenge
    final double netPayable = inv.grandTotal - inv.totalOldGoldDeduction;
    final double totalCashPaid =
        inv.cashPaid + inv.upiPaid + inv.cardPaid + inv.advancePaid;

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
          // ── Header ──────────────────────────────────────────────────────
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
                  child: pw.Text("✓ FULLY PAID",
                      style: pw.TextStyle(
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800)),
                ),
            ],
          ),
          pw.SizedBox(height: 8),

          // ── Payment Mode Chips ──────────────────────────────────────────
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
                        style:
                            pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
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

          // ── Total Paid row ───────────────────────────────────────────────
          if (payments.length > 1) ...[
            pw.Divider(color: PdfColors.grey200, thickness: 0.5),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Total Paid",
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                pw.Text("Rs ${totalCashPaid.toStringAsFixed(2)}",
                    style: pw.TextStyle(
                        fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 6),
          ],

          // ── Balance Due / Paid stamp ─────────────────────────────────────
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
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
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
    return pw.Column(children: [
      pw.Divider(color: PdfColors.grey300),
      pw.SizedBox(height: 6),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text("Thank you for shopping with us!",
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        pw.Text("${inv.shopName} — E&OE",
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
        pw.Text("GRAND TOTAL: Rs ${inv.grandTotal.toStringAsFixed(2)}",
            style: pw.TextStyle(
                fontSize: fontSize + 2, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  Future<void> printInvoice(PrintFormat format) async {
    if (pdfBytes == null) return;
    if (format != selectedFormat) {
      selectedFormat = format;
      pdfBytes = await _buildPdf(invoice!, format);
      notifyListeners();
    }
    await Printing.layoutPdf(onLayout: (_) async => pdfBytes!);
  }

  Future<void> openDirectWhatsAppChat() async {
    if (invoice == null || invoice!.customerMobile.isEmpty) return;

    final phone = invoice!.customerMobile.replaceAll(RegExp(r'\D'), '');
    final cleanPhone = phone.length == 10 ? "91$phone" : phone;

    final customerName =
        invoice!.customerName.isNotEmpty ? invoice!.customerName : "Customer";
    final textMessage =
        "Dear $customerName,\n\nThank you for shopping at *${invoice!.shopName}*!\n\nHere are your invoice details:\n*Invoice No:* ${invoice!.invoiceNumber}\n*Total Amount:* Rs ${invoice!.grandTotal.toStringAsFixed(2)}\n\nVisit again!";

    final url = Uri.parse(
        "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(textMessage)}");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch WhatsApp");
    }
  }

  // 🚀 NAYA MASTER LOGIC: Smart CRM Folder Directory Management
  Future<String?> downloadPdf() async {
    if (pdfBytes == null || invoice == null) return null;

    try {
      final prefs = await SharedPreferences.getInstance();
      String? baseDirPath = prefs.getString('invoice_base_folder');

      // 1. Agar pehle se folder set nahi hai, toh owner se select karwao
      if (baseDirPath == null || !await Directory(baseDirPath).exists()) {
        baseDirPath = await FilePicker.platform.getDirectoryPath(
          dialogTitle: "Select Folder to Save All Bills",
        );

        if (baseDirPath == null) {
          debugPrint("Folder selection cancelled by user");
          return null; // Return if cancelled
        }
        // Save karke rakh lo taaki baar baar na puche
        await prefs.setString('invoice_base_folder', baseDirPath);
      }

      // 2. Customer ke Mobile Number ka Folder banao
      String mobileFolder =
          invoice!.customerMobile.replaceAll(RegExp(r'\D'), '');
      if (mobileFolder.isEmpty) mobileFolder = "Walk-in_Customers";

      final customerDir = Directory('$baseDirPath/$mobileFolder');
      if (!await customerDir.exists()) {
        await customerDir.create(recursive: true);
      }

      // 3. Customer ke Naam aur Invoice No se file save karo
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

  // ✅ NEW: Due date set karo — PDF regenerate hoga
  Future<void> setDueDate(DateTime? date) async {
    dueDate = date;
    if (invoice != null) {
      // Invoice snapshot mein dueDate update karo
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
    notifyListeners();
  }

  @override
  void dispose() {
    reset();
    super.dispose();
  }
}
