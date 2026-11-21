// =============================================================================
// FILE        : cash_register_model.dart
// MODULE      : Dashboard / Cash Register
// LAYER       : Models
// DESCRIPTION : Dashboard projection of Day Book cash and bank balances.
// =============================================================================

class CashRegisterModel {
  final double openingBalance;
  final double moneyIn;
  final double moneyOut;
  final double closingBalance;

  // Formatted strings for the UI.
  final String openingBalanceStr;
  final String moneyInStr;
  final String moneyOutStr;
  final String closingBalanceStr;

  final bool isLoading;

  const CashRegisterModel({
    required this.openingBalance,
    required this.moneyIn,
    required this.moneyOut,
    required this.closingBalance,
    required this.openingBalanceStr,
    required this.moneyInStr,
    required this.moneyOutStr,
    required this.closingBalanceStr,
    this.isLoading = false,
  });

  factory CashRegisterModel.loading() => const CashRegisterModel(
        openingBalance: 0,
        moneyIn: 0,
        moneyOut: 0,
        closingBalance: 0,
        openingBalanceStr: '--',
        moneyInStr: '--',
        moneyOutStr: '--',
        closingBalanceStr: '--',
        isLoading: true,
      );
}
