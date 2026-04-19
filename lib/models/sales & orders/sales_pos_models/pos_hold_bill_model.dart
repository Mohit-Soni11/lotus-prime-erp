// ==========================================
// FILE: pos_hold_bill_model.dart
// TYPE: Data Model
// AUTHOR: Senior System Architect
// DESCRIPTION: Blueprint for saving a parked/held invoice snapshot.
// ==========================================

import '../../../models/sales & orders/sales_pos_models/sales_pos_models.dart';

class PosHoldBillModel {
  final String holdId;
  final DateTime holdTime;
  final String customerName;
  final String customerMobile;
  final int totalItems;
  final double grandTotal;
  
  // Saving the exact instances of items
  final List<SaleItemModel> savedSaleItems;
  final List<OldGoldItemModel> savedOldGoldItems;

  PosHoldBillModel({
    required this.holdId,
    required this.holdTime,
    required this.customerName,
    required this.customerMobile,
    required this.totalItems,
    required this.grandTotal,
    required this.savedSaleItems,
    required this.savedOldGoldItems,
  });
}