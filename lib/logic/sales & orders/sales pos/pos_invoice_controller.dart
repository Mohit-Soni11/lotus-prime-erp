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
import '../../../models/sales & orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../repositories/setting/shop_setup/shop_setup_repository.dart'; 

class BillSettings {
  bool showHuid = false;
  bool showPcs = true;
  bool showGrossWt = true;
  bool showLessWt = true;
  bool showMaking = true;
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

  String _realShopName = "Lotus Jewellers";
  String _realShopAddress = "Address not set";
  String _realShopPhone = "Phone not set";
  String _realShopGstin = "Not Registered";

  BillSettings getActiveConfig(BillingMode mode, BillType type) {
    if (mode == BillingMode.retail) {
      return type == BillType.normal ? printConfig.retailNormal : printConfig.retailGst;
    } else {
      return type == BillType.normal ? printConfig.wholesaleNormal : printConfig.wholesaleGst;
    }
  }

  Future<void> updatePrintOptions({required int copies, required bool duplicate}) async {
    printCopies = copies;
    includeDuplicateStamp = duplicate;
    if (invoice != null) {
      pdfBytes = await _buildPdf(invoice!, selectedFormat);
      notifyListeners();
    }
  }

  Future<void> toggleCustomization(String key, BillingMode mode, BillType type) async {
    BillSettings config = getActiveConfig(mode, type);

    switch (key) {
      case 'huid': config.showHuid = !config.showHuid; break;
      case 'pcs': config.showPcs = !config.showPcs; break;
      case 'gw': config.showGrossWt = !config.showGrossWt; break;
      case 'lw': config.showLessWt = !config.showLessWt; break;
      case 'making': config.showMaking = !config.showMaking; break;
    }
    
    if (invoice != null && invoice!.billingMode == mode && invoice!.billType == type) {
      pdfBytes = await _buildPdf(invoice!, selectedFormat);
    }
    notifyListeners();
  }

  Future<void> _fetchRealShopData() async {
    try {
      final String activeTenantId = "SHOP_DEFAULT"; 
      final shopData = await _shopRepo.fetchExistingSetup(activeTenantId);

      if (shopData != null) {
        final basicInfo = shopData['basicInfo'];
        final addressData = shopData['addressData'];
        final taxGst = shopData['taxGst'];

        if (basicInfo != null) {
          _realShopName = basicInfo['shopName'] ?? billing.shopName;
          _realShopPhone = basicInfo['primaryPhone'] ?? _realShopPhone;
        }
        if (addressData != null) {
          final addrLine = addressData['addressLine1'] ?? '';
          final city = addressData['city'] ?? '';
          final state = addressData['state'] ?? '';
          _realShopAddress = "$addrLine, $city, $state".replaceAll(RegExp(r'^[\s,]+|[\s,]+$'), '');
        }
        if (taxGst != null && taxGst['isGstRegistered'] == true) {
          _realShopGstin = taxGst['gstinNumber'] ?? _realShopGstin;
        }
      } else {
        _realShopName = billing.shopName.isNotEmpty ? billing.shopName : "Lotus Jewellers";
      }
    } catch (e) {
      _realShopName = billing.shopName.isNotEmpty ? billing.shopName : "Lotus Jewellers";
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
    );
  }

  Future<void> generateInvoice() async {
    genState = InvoiceGenState.generating;
    notifyListeners();
    try {
      await _fetchRealShopData();
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
        pageFormat = PdfPageFormat.a4; break;
      case PrintFormat.thermal3inch:
        pageFormat = const PdfPageFormat(80 * PdfPageFormat.mm, 250 * PdfPageFormat.mm, marginAll: 4 * PdfPageFormat.mm); break;
      case PrintFormat.thermal2inch:
        pageFormat = const PdfPageFormat(57 * PdfPageFormat.mm, 250 * PdfPageFormat.mm, marginAll: 3 * PdfPageFormat.mm); break;
    }

    for (int i = 0; i < printCopies; i++) {
      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: fmt == PrintFormat.a4 ? const pw.EdgeInsets.all(24) : const pw.EdgeInsets.all(6),
          build: (pw.Context context) {
            final layout = fmt == PrintFormat.a4 ? _buildA4Layout(inv) : _buildThermalLayout(inv, fmt);
            if (includeDuplicateStamp) {
              return pw.Stack(
                alignment: pw.Alignment.center,
                children: [
                  pw.Center(child: pw.Transform.rotate(angle: 0.785, child: pw.Text("DUPLICATE", style: pw.TextStyle(color: PdfColors.grey300, fontSize: fmt == PrintFormat.a4 ? 60 : 25, fontWeight: pw.FontWeight.bold)))),
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
          pw.Text(inv.shopName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.Text(inv.shopAddress, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.Text("Ph: ${inv.shopPhone}", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          if (inv.billType == BillType.gst && inv.shopGstin != "Not Registered")
            pw.Text("GSTIN: ${inv.shopGstin}", style: const pw.TextStyle(fontSize: 9)),
        ]),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text(
              inv.billType == BillType.gst ? "TAX INVOICE" : "ESTIMATE",
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.amber800)),
          pw.SizedBox(height: 4),
          pw.Text("No: ${inv.invoiceNumber}", style: const pw.TextStyle(fontSize: 10)),
          pw.Text("Date: ${inv.invoiceDate.day}/${inv.invoiceDate.month}/${inv.invoiceDate.year}", style: const pw.TextStyle(fontSize: 10)),
        ]),
      ],
    );
  }

  pw.Widget _pdfCustomerBlock(PosInvoiceModel inv) {
    final name = inv.customerName.isEmpty ? "Walk-in Customer" : inv.customerName;
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.all(pw.Radius.circular(6))),
      child: pw.Row(children: [
        pw.Expanded(child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("BILL TO", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            pw.SizedBox(height: 3),
            pw.Text(name, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            if (inv.customerMobile.isNotEmpty) pw.Text(inv.customerMobile, style: const pw.TextStyle(fontSize: 9)),
          ],
        )),
      ]),
    );
  }

  pw.Widget _pdfItemsTable(PosInvoiceModel inv) {
    final isWholesale = inv.billingMode == BillingMode.wholesale;
    final activeConfig = getActiveConfig(inv.billingMode, inv.billType);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (inv.saleItems.isNotEmpty) ...[
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.amber50),
                children: [
                  _th("#"), _th("Item Description"), _th("Purity"), 
                  if (activeConfig.showGrossWt) _th("Gross(g)"),
                  if (activeConfig.showLessWt) _th("Less(g)"),
                  _th(isWholesale ? "Fine(g)" : "Net(g)"),
                  _th("Rate"), 
                  if (activeConfig.showMaking) _th(isWholesale ? "Labour" : "Making"),
                  _th("Amount"),
                ],
              ),
              ...inv.saleItems.asMap().entries.map((e) {
                final i = e.value;
                String desc = i.descCtrl.text.isNotEmpty ? i.descCtrl.text : "${i.metal.name.toUpperCase()} ITEM";
                if (activeConfig.showHuid && i.huidCtrl.text.isNotEmpty) desc += "\n[HUID: ${i.huidCtrl.text}]";
                if (activeConfig.showPcs && i.pcs > 1) desc += " (${i.pcs} pcs)";

                return pw.TableRow(children: [
                  _cell("${e.key + 1}"), _cell(desc), _cell("${i.tunch}%"),
                  if (activeConfig.showGrossWt) _cell(i.grossCtrl.text.isNotEmpty ? i.grossCtrl.text : "0.000"),
                  if (activeConfig.showLessWt) _cell(i.totalLessWt.toStringAsFixed(3)),
                  _cell(isWholesale ? i.fineWt.toStringAsFixed(3) : i.netWt.toStringAsFixed(3)),
                  _cell(i.rate.toStringAsFixed(0)),
                  if (activeConfig.showMaking) _cell(isWholesale ? i.wholesaleLabourAmt.toStringAsFixed(0) : i.makingAmt.toStringAsFixed(0)),
                  _cell(i.totalValue.toStringAsFixed(2)),
                ]);
              }),
            ],
          ),
        ],
      ]
    );
  }

  pw.Widget _th(String text) => pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(text, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)));
  pw.Widget _cell(String text) => pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(text, style: const pw.TextStyle(fontSize: 8)));

  pw.Widget _pdfTotalsBlock(PosInvoiceModel inv) {
    return pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
      pw.SizedBox(
        width: 220,
        child: pw.Column(children: [
          _totalRow("Gross Amount", inv.grossAmount),
          if (inv.discountAmount > 0) _totalRow("Discount", -inv.discountAmount, isDeduction: true),
          if (inv.billType == BillType.gst) ...[
            _totalRow("CGST", inv.cgst),
            _totalRow("SGST", inv.sgst),
          ],
          if (inv.totalOldGoldDeduction > 0) _totalRow("Old Gold Exchange", -inv.totalOldGoldDeduction, isDeduction: true),
          pw.Divider(color: PdfColors.amber800),
          _totalRow("GRAND TOTAL", inv.grandTotal, isBold: true, isGrand: true),
        ]),
      ),
    ]);
  }

  pw.Widget _totalRow(String label, double amount, {bool isBold = false, bool isDeduction = false, bool isGrand = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(label, style: pw.TextStyle(fontSize: isGrand ? 11 : 9, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text("${isDeduction ? '- ' : ''}Rs ${amount.abs().toStringAsFixed(2)}", style: pw.TextStyle(fontSize: isGrand ? 12 : 9, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ]),
    );
  }

  pw.Widget _pdfPaymentBlock(PosInvoiceModel inv) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6))),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text("PAYMENT DETAILS", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
        pw.SizedBox(height: 6),
        pw.Wrap(spacing: 16, runSpacing: 4, children: [
          if (inv.cashPaid > 0) pw.Text("Cash: Rs ${inv.cashPaid.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 9)),
          if (inv.upiPaid > 0) pw.Text("UPI: Rs ${inv.upiPaid.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 9)),
        ]),
        if (inv.balanceDue > 0.5) ...[
          pw.SizedBox(height: 6),
          pw.Text("Balance Due: Rs ${inv.balanceDue.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
        ],
      ]),
    );
  }

  pw.Widget _pdfFooter(PosInvoiceModel inv) {
    return pw.Column(children: [
      pw.Divider(color: PdfColors.grey300),
      pw.SizedBox(height: 6),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text("Thank you for shopping with us!", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        pw.Text("${inv.shopName} — E&OE", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
      ]),
    ]);
  }

  pw.Widget _buildThermalLayout(PosInvoiceModel inv, PrintFormat fmt) {
    final fontSize = fmt == PrintFormat.thermal2inch ? 7.0 : 8.5;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(inv.shopName, style: pw.TextStyle(fontSize: 12.0, fontWeight: pw.FontWeight.bold)),
        pw.Text("No: ${inv.invoiceNumber}", style: pw.TextStyle(fontSize: fontSize)),
        pw.Divider(color: PdfColors.grey400),
        pw.Text("GRAND TOTAL: Rs ${inv.grandTotal.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: fontSize + 2, fontWeight: pw.FontWeight.bold)),
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

    final customerName = invoice!.customerName.isNotEmpty ? invoice!.customerName : "Customer";
    final textMessage = "Dear $customerName,\n\nThank you for shopping at *${invoice!.shopName}*!\n\nHere are your invoice details:\n*Invoice No:* ${invoice!.invoiceNumber}\n*Total Amount:* Rs ${invoice!.grandTotal.toStringAsFixed(2)}\n\nVisit again!";
    
    final url = Uri.parse("https://wa.me/$cleanPhone?text=${Uri.encodeComponent(textMessage)}");
    
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
      String mobileFolder = invoice!.customerMobile.replaceAll(RegExp(r'\D'), '');
      if (mobileFolder.isEmpty) mobileFolder = "Walk-in_Customers";

      final customerDir = Directory('$baseDirPath/$mobileFolder');
      if (!await customerDir.exists()) {
        await customerDir.create(recursive: true);
      }

      // 3. Customer ke Naam aur Invoice No se file save karo
      String custName = invoice!.customerName.isNotEmpty ? invoice!.customerName : "Customer";
      String cleanName = custName.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').replaceAll(' ', '_');
      String cleanInv = invoice!.invoiceNumber.replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '_');
      
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

  void reset() {
    genState = InvoiceGenState.idle; invoice = null; pdfBytes = null; errorMessage = null; notifyListeners();
  }

  @override
  void dispose() { reset(); super.dispose(); }
}