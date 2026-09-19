// =============================================================================
// FILE        : cash_register_model.dart
// MODULE      : Dashboard / Cash Register
// LAYER       : Models
// DESCRIPTION : Complete snapshot for today's cash register.
//
//               4 KEY FIELDS:
//               • openingBalance  → ShopProfiles.openingCashBalance (v6)
//               • totalReceived   → Sum of bills.paidAmount (today)
//               • totalPaidOut    → Expense total
//               • netCashDrawer   → openingBalance + received - paidOut
// =============================================================================

class CashRegisterModel {
  final double openingBalance;
  final double totalReceived;
  final double totalPaidOut;
  final double netCashDrawer;

  // Formatted strings for the UI.
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
        openingBalance: 0,
        totalReceived: 0,
        totalPaidOut: 0,
        netCashDrawer: 0,
        openingBalanceStr: '--',
        totalReceivedStr: '--',
        totalPaidOutStr: '--',
        netCashDrawerStr: '--',
        isLoading: true,
      );

  factory CashRegisterModel.zero() => const CashRegisterModel(
        openingBalance: 0,
        totalReceived: 0,
        totalPaidOut: 0,
        netCashDrawer: 0,
        openingBalanceStr: '₹0',
        totalReceivedStr: '₹0',
        totalPaidOutStr: '₹0',
        netCashDrawerStr: '₹0',
      );
}
