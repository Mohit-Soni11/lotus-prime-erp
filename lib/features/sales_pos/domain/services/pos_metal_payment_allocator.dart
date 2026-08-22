import '../../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import '../../../../models/sales_orders/sales_pos_models/sales_pos_models.dart';

class PosMetalPaymentAllocator {
  const PosMetalPaymentAllocator();

  static const _moneyTolerance = 0.005;

  List<MetalType> collectMetals({
    required List<SaleItemModel> saleItems,
    required List<TradeInItemModel> tradeInItems,
  }) {
    final present = <MetalType>{
      ...saleItems.map((item) => item.metal),
      ...tradeInItems.map((item) => item.metal),
    };
    const ordered = [
      MetalType.gold,
      MetalType.silver,
      MetalType.platinum,
      MetalType.diamond,
    ];
    return ordered.where(present.contains).toList(growable: false);
  }

  List<PosInvoiceMetalPaymentAllocation> allocate({
    required List<SaleItemModel> saleItems,
    required List<TradeInItemModel> tradeInItems,
    required BillingMode billingMode,
    required TradeInAdjustMode tradeInMode,
    required double grossAmount,
    required double discountAmount,
    required double taxableAmount,
    required double totalGst,
    required double roundOffAmount,
    required double netPayable,
    required double cashPaid,
    required double upiPaid,
    required double cardPaid,
    required double advancePaid,
    required Set<MetalType> settleFirstMetals,
  }) {
    final metals = collectMetals(
      saleItems: saleItems,
      tradeInItems: tradeInItems,
    );
    if (metals.isEmpty) return const [];

    final sections = _sections(
      metals: metals,
      saleItems: saleItems,
      tradeInItems: tradeInItems,
      billingMode: billingMode,
      tradeInMode: tradeInMode,
      grossAmount: grossAmount,
      discountAmount: discountAmount,
      taxableAmount: taxableAmount,
      totalGst: totalGst,
      roundOffAmount: roundOffAmount,
    );
    if (sections.isEmpty) return const [];

    final paymentByMetal = _allocateTotalsByMetal(
      sections: sections,
      netPayable: netPayable,
      totalPaid: _roundMoney(cashPaid + upiPaid + cardPaid + advancePaid),
      settleFirstMetals: settleFirstMetals,
    );
    final modeSplit = _splitModesAcrossMetals(
      metals: sections.map((section) => section.metal).toList(growable: false),
      paymentByMetal: paymentByMetal,
      cashPaid: cashPaid,
      upiPaid: upiPaid,
      cardPaid: cardPaid,
      advancePaid: advancePaid,
    );

    return sections.map((section) {
      final modes = modeSplit[section.metal] ?? const _ModeAmounts();
      return PosInvoiceMetalPaymentAllocation(
        metal: section.metal,
        netPayable: section.netPayable,
        cashPaid: modes.cash,
        upiPaid: modes.upi,
        cardPaid: modes.card,
        advancePaid: modes.advance,
        settleFirst: settleFirstMetals.contains(section.metal),
      );
    }).toList(growable: false);
  }

  List<_MetalSection> _sections({
    required List<MetalType> metals,
    required List<SaleItemModel> saleItems,
    required List<TradeInItemModel> tradeInItems,
    required BillingMode billingMode,
    required TradeInAdjustMode tradeInMode,
    required double grossAmount,
    required double discountAmount,
    required double taxableAmount,
    required double totalGst,
    required double roundOffAmount,
  }) {
    final baseSections = [
      for (final metal in metals)
        _baseSection(
          metal: metal,
          saleItems: saleItems,
          tradeInItems: tradeInItems,
          billingMode: billingMode,
          tradeInMode: tradeInMode,
          grossAmount: grossAmount,
          discountAmount: discountAmount,
          taxableAmount: taxableAmount,
          totalGst: totalGst,
        ),
    ];
    final crossAdjustments = _crossMetalAdjustments(baseSections, billingMode);

    return baseSections.map((section) {
      final roundOffRatio = grossAmount.abs() <= _moneyTolerance
          ? 0.0
          : section.grossAmount / grossAmount;
      final adjustedNet = _settledBalance(
        section.netBeforeCrossAdjustment -
            (crossAdjustments[section.metal] ?? 0) +
            (roundOffAmount * roundOffRatio),
      );
      return section.copyWith(netPayable: adjustedNet);
    }).where((section) {
      return section.grossAmount > _moneyTolerance ||
          section.tradeInDeduction > _moneyTolerance ||
          section.netPayable.abs() > _moneyTolerance;
    }).toList(growable: false);
  }

  _MetalSection _baseSection({
    required MetalType metal,
    required List<SaleItemModel> saleItems,
    required List<TradeInItemModel> tradeInItems,
    required BillingMode billingMode,
    required TradeInAdjustMode tradeInMode,
    required double grossAmount,
    required double discountAmount,
    required double taxableAmount,
    required double totalGst,
  }) {
    final scopedSaleItems =
        saleItems.where((item) => item.metal == metal).toList(growable: false);
    final scopedTradeInItems = tradeInItems
        .where((item) => item.metal == metal)
        .toList(growable: false);
    final scopedGross =
        scopedSaleItems.fold(0.0, (sum, item) => sum + item.totalValue);
    final grossRatio =
        grossAmount.abs() <= _moneyTolerance ? 0.0 : scopedGross / grossAmount;
    final scopedDiscount = discountAmount * grossRatio;
    final scopedTaxable = scopedGross - scopedDiscount;
    final safeTaxable = scopedTaxable < 0 ? 0.0 : scopedTaxable;
    final taxRatio = taxableAmount.abs() <= _moneyTolerance
        ? grossRatio
        : safeTaxable / taxableAmount;
    final scopedGst = totalGst * taxRatio;
    final scopedGrandTotal = safeTaxable + scopedGst;
    final tradeInDeduction = tradeInMode == TradeInAdjustMode.cashAdjust
        ? scopedTradeInItems.fold(0.0, (sum, item) => sum + item.totalValue)
        : 0.0;
    final netBeforeCross = billingMode == BillingMode.wholesale
        ? scopedGrandTotal
        : scopedGrandTotal - tradeInDeduction;
    return _MetalSection(
      metal: metal,
      grossAmount: scopedGross,
      tradeInDeduction: tradeInDeduction,
      netBeforeCrossAdjustment: _roundMoney(netBeforeCross),
      netPayable: _roundMoney(netBeforeCross),
    );
  }

  Map<MetalType, double> _crossMetalAdjustments(
    List<_MetalSection> sections,
    BillingMode billingMode,
  ) {
    if (sections.length <= 1 || billingMode == BillingMode.wholesale) {
      return const {};
    }

    final excess = sections
        .where((section) => section.netBeforeCrossAdjustment < -_moneyTolerance)
        .fold(0.0,
            (sum, section) => sum + section.netBeforeCrossAdjustment.abs());
    if (excess <= _moneyTolerance) return const {};

    final positiveTotal = sections
        .where((section) => section.netBeforeCrossAdjustment > _moneyTolerance)
        .fold(0.0, (sum, section) => sum + section.netBeforeCrossAdjustment);
    if (positiveTotal <= _moneyTolerance) return const {};

    return {
      for (final section in sections)
        if (section.netBeforeCrossAdjustment > _moneyTolerance)
          section.metal:
              excess * (section.netBeforeCrossAdjustment / positiveTotal),
    };
  }

  Map<MetalType, double> _allocateTotalsByMetal({
    required List<_MetalSection> sections,
    required double netPayable,
    required double totalPaid,
    required Set<MetalType> settleFirstMetals,
  }) {
    final payableByMetal = {
      for (final section in sections) section.metal: section.netPayable,
    };
    final positivePayable = sections
        .where((section) => section.netPayable > _moneyTolerance)
        .fold(0.0, (sum, section) => sum + section.netPayable);
    final available = totalPaid.clamp(0.0, positivePayable).toDouble();
    var remaining = available;
    final paid = {for (final section in sections) section.metal: 0.0};

    final priority = [
      ...sections
          .where((section) => settleFirstMetals.contains(section.metal))
          .map((section) => section.metal),
      ...sections
          .where((section) => !settleFirstMetals.contains(section.metal))
          .map((section) => section.metal),
    ];

    if (settleFirstMetals.isEmpty && netPayable > _moneyTolerance) {
      for (final section in sections) {
        if (section.netPayable <= _moneyTolerance) continue;
        paid[section.metal] = _roundMoney(
          available * (section.netPayable / netPayable),
        ).clamp(0.0, section.netPayable).toDouble();
      }
      return _balanceRounding(paid, payableByMetal, available, priority);
    }

    for (final metal in priority) {
      final payable = payableByMetal[metal] ?? 0.0;
      if (payable <= _moneyTolerance || remaining <= _moneyTolerance) {
        continue;
      }
      final allocated = remaining > payable ? payable : remaining;
      paid[metal] = _roundMoney(allocated);
      remaining = _settledBalance(remaining - allocated);
    }
    return _balanceRounding(paid, payableByMetal, available, priority);
  }

  Map<MetalType, double> _balanceRounding(
    Map<MetalType, double> paid,
    Map<MetalType, double> payableByMetal,
    double targetTotal,
    List<MetalType> priority,
  ) {
    final currentTotal = paid.values.fold(0.0, (sum, amount) => sum + amount);
    var delta = _roundMoney(targetTotal - currentTotal);
    if (delta.abs() <= _moneyTolerance) return paid;

    for (final metal in priority.reversed) {
      final payable = payableByMetal[metal] ?? 0.0;
      final current = paid[metal] ?? 0.0;
      if (delta > 0 && current < payable) {
        final add = delta > payable - current ? payable - current : delta;
        paid[metal] = _roundMoney(current + add);
        delta = _roundMoney(delta - add);
      } else if (delta < 0 && current > 0) {
        final remove = delta.abs() > current ? current : delta.abs();
        paid[metal] = _roundMoney(current - remove);
        delta = _roundMoney(delta + remove);
      }
      if (delta.abs() <= _moneyTolerance) break;
    }
    return paid;
  }

  Map<MetalType, _ModeAmounts> _splitModesAcrossMetals({
    required List<MetalType> metals,
    required Map<MetalType, double> paymentByMetal,
    required double cashPaid,
    required double upiPaid,
    required double cardPaid,
    required double advancePaid,
  }) {
    final result = {for (final metal in metals) metal: const _ModeAmounts()};
    final remainingByMetal = {
      for (final metal in metals) metal: paymentByMetal[metal] ?? 0.0,
    };

    void applyMode(double amount, _ModeSetter setter) {
      var remainingModeAmount = _roundMoney(amount);
      if (remainingModeAmount <= _moneyTolerance) return;
      for (final metal in metals) {
        final metalRemaining = remainingByMetal[metal] ?? 0.0;
        if (metalRemaining <= _moneyTolerance ||
            remainingModeAmount <= _moneyTolerance) {
          continue;
        }
        final allocated = remainingModeAmount > metalRemaining
            ? metalRemaining
            : remainingModeAmount;
        result[metal] = setter(result[metal]!, _roundMoney(allocated));
        remainingByMetal[metal] = _settledBalance(metalRemaining - allocated);
        remainingModeAmount = _settledBalance(remainingModeAmount - allocated);
      }
    }

    applyMode(cashPaid, (modes, amount) => modes.copyWith(cash: amount));
    applyMode(upiPaid, (modes, amount) => modes.copyWith(upi: amount));
    applyMode(cardPaid, (modes, amount) => modes.copyWith(card: amount));
    applyMode(
      advancePaid,
      (modes, amount) => modes.copyWith(advance: amount),
    );
    return result;
  }

  double _settledBalance(double value) {
    if (value.abs() <= _moneyTolerance) return 0.0;
    return _roundMoney(value);
  }

  double _roundMoney(double value) => (value * 100).roundToDouble() / 100;
}

typedef _ModeSetter = _ModeAmounts Function(_ModeAmounts modes, double amount);

class _MetalSection {
  final MetalType metal;
  final double grossAmount;
  final double tradeInDeduction;
  final double netBeforeCrossAdjustment;
  final double netPayable;

  const _MetalSection({
    required this.metal,
    required this.grossAmount,
    required this.tradeInDeduction,
    required this.netBeforeCrossAdjustment,
    required this.netPayable,
  });

  _MetalSection copyWith({double? netPayable}) {
    return _MetalSection(
      metal: metal,
      grossAmount: grossAmount,
      tradeInDeduction: tradeInDeduction,
      netBeforeCrossAdjustment: netBeforeCrossAdjustment,
      netPayable: netPayable ?? this.netPayable,
    );
  }
}

class _ModeAmounts {
  final double cash;
  final double upi;
  final double card;
  final double advance;

  const _ModeAmounts({
    this.cash = 0,
    this.upi = 0,
    this.card = 0,
    this.advance = 0,
  });

  _ModeAmounts copyWith({
    double? cash,
    double? upi,
    double? card,
    double? advance,
  }) {
    return _ModeAmounts(
      cash: cash == null ? this.cash : this.cash + cash,
      upi: upi == null ? this.upi : this.upi + upi,
      card: card == null ? this.card : this.card + card,
      advance: advance == null ? this.advance : this.advance + advance,
    );
  }
}
