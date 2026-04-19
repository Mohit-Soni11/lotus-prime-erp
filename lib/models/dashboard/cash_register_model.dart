// =============================================================================
// FILE        : cash_register_model.dart
// MODULE      : Dashboard / Cash Register
// LAYER       : Models
// DESCRIPTION : Aaj ke cash register ka complete snapshot.
//
//               4 KEY FIELDS (Python backend_data jaisa):
//               • openingBalance  → ShopProfiles.openingCashBalance (v6)
//               • totalReceived   → Sum of bills.paidAmount (today)
//               • totalPaidOut    → Future: expenses table se (abhi 0)
//               • netCashDrawer   → openingBalance + received - paidOut
// =============================================================================

class CashRegisterModel {
  final double openingBalance;
  final double totalReceived;
  final double totalPaidOut;
  final double netCashDrawer;

  // Formatted strings — UI ke liye
  final String openingBalanceStr;
  final String totalReceivedStr;
  final String totalPaidOutStr;
  final String netCashDrawerStr;

  final bool isLoading;

  const CashRegisterModel({
    required this.openingBalance,
    required this.totalReceived,
    required this.totalPaidOut,
    required this.netCashDrawer,
    required this.openingBalanceStr,
    required this.totalReceivedStr,
    required this.totalPaidOutStr,
    required this.netCashDrawerStr,
    this.isLoading = false,
  });

  factory CashRegisterModel.loading() => const CashRegisterModel(
    openingBalance:    0,
    totalReceived:     0,
    totalPaidOut:      0,
    netCashDrawer:     0,
    openingBalanceStr: '--',
    totalReceivedStr:  '--',
    totalPaidOutStr:   '--',
    netCashDrawerStr:  '--',
    isLoading:         true,
  );

  factory CashRegisterModel.zero() => const CashRegisterModel(
    openingBalance:    0,
    totalReceived:     0,
    totalPaidOut:      0,
    netCashDrawer:     0,
    openingBalanceStr: '₹0',
    totalReceivedStr:  '₹0',
    totalPaidOutStr:   '₹0',
    netCashDrawerStr:  '₹0',
  );
}