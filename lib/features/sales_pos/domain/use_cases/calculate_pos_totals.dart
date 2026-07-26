import '../../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../../models/sales_orders/sales_pos_models/sales_pos_models.dart';
import '../services/pos_weight_math.dart';

class PosTotalsInput {
  const PosTotalsInput({
    required this.saleItems,
    required this.tradeInItems,
    required this.billingMode,
    required this.billType,
    required this.tradeInMode,
    required this.discountType,
    required this.discountInput,
    required this.cashInput,
    required this.upiInput,
    required this.cardInput,
    required this.advanceInput,
    required this.goldBhawInput,
    required this.silverBhawInput,
    required this.platinumBhawInput,
    required this.diamondBhawInput,
    required this.metalGstRates,
    required this.defaultJewelleryGstRate,
    required this.makingGstRate,
    required this.roundOffGstAmount,
    this.amountTolerance = 0.005,
  });

  final List<SaleItemModel> saleItems;
  final List<TradeInItemModel> tradeInItems;
  final BillingMode billingMode;
  final BillType billType;
  final TradeInAdjustMode tradeInMode;
  final DiscountType discountType;
  final double discountInput;
  final double cashInput;
  final double upiInput;
  final double cardInput;
  final double advanceInput;
  final double goldBhawInput;
  final double silverBhawInput;
  final double platinumBhawInput;
  final double diamondBhawInput;
  final Map<MetalType, double> metalGstRates;
  final double defaultJewelleryGstRate;
  final double makingGstRate;
  final bool roundOffGstAmount;
  final double amountTolerance;
}

class PosTotals {
  const PosTotals({
    required this.totalGoldWt,
    required this.totalSilverWt,
    required this.totalPlatinumWt,
    required this.totalDiamondWt,
    required this.totalGoldAmount,
    required this.totalSilverAmount,
    required this.totalPlatinumAmount,
    required this.totalDiamondAmount,
    required this.totalTradeInAmount,
    required this.tradeInCashDeduction,
    required this.pureGoldAmount,
    required this.pureSilverAmount,
    required this.purePlatinumAmount,
    required this.pureDiamondAmount,
    required this.goldSoldFine,
    required this.silverSoldFine,
    required this.platinumSoldFine,
    required this.diamondSoldFine,
    required this.goldJamaFine,
    required this.silverJamaFine,
    required this.platinumJamaFine,
    required this.diamondJamaFine,
    required this.goldNetFine,
    required this.silverNetFine,
    required this.platinumNetFine,
    required this.diamondNetFine,
    required this.goldBhawAmount,
    required this.silverBhawAmount,
    required this.platinumBhawAmount,
    required this.diamondBhawAmount,
    required this.goldMakingCharge,
    required this.silverMakingCharge,
    required this.platinumMakingCharge,
    required this.diamondMakingCharge,
    required this.totalMakingCharge,
    required this.grossAmount,
    required this.discountAmount,
    required this.taxableAmount,
    required this.goldGst,
    required this.silverGst,
    required this.platinumGst,
    required this.diamondGst,
    required this.totalGst,
    required this.cgst,
    required this.sgst,
    required this.grandTotal,
    required this.finalPayableAmount,
    required this.cashPaidAmount,
    required this.upiPaidAmount,
    required this.cardPaidAmount,
    required this.advancePaidAmount,
    required this.totalPaid,
    required this.balanceDue,
    required this.changeReturnAmount,
    required this.invoiceTotalPaid,
    required this.invoiceBalanceDue,
    required this.changeCreditSourcePaymentMode,
  });

  final double totalGoldWt;
  final double totalSilverWt;
  final double totalPlatinumWt;
  final double totalDiamondWt;
  final double totalGoldAmount;
  final double totalSilverAmount;
  final double totalPlatinumAmount;
  final double totalDiamondAmount;
  final double totalTradeInAmount;
  final double tradeInCashDeduction;
  final double pureGoldAmount;
  final double pureSilverAmount;
  final double purePlatinumAmount;
  final double pureDiamondAmount;
  final double goldSoldFine;
  final double silverSoldFine;
  final double platinumSoldFine;
  final double diamondSoldFine;
  final double goldJamaFine;
  final double silverJamaFine;
  final double platinumJamaFine;
  final double diamondJamaFine;
  final double goldNetFine;
  final double silverNetFine;
  final double platinumNetFine;
  final double diamondNetFine;
  final double goldBhawAmount;
  final double silverBhawAmount;
  final double platinumBhawAmount;
  final double diamondBhawAmount;
  final double goldMakingCharge;
  final double silverMakingCharge;
  final double platinumMakingCharge;
  final double diamondMakingCharge;
  final double totalMakingCharge;
  final double grossAmount;
  final double discountAmount;
  final double taxableAmount;
  final double goldGst;
  final double silverGst;
  final double platinumGst;
  final double diamondGst;
  final double totalGst;
  final double cgst;
  final double sgst;
  final double grandTotal;
  final double finalPayableAmount;
  final double cashPaidAmount;
  final double upiPaidAmount;
  final double cardPaidAmount;
  final double advancePaidAmount;
  final double totalPaid;
  final double balanceDue;
  final double changeReturnAmount;
  final double invoiceTotalPaid;
  final double invoiceBalanceDue;
  final PaymentMode? changeCreditSourcePaymentMode;
}

class CalculatePosTotals {
  const CalculatePosTotals();

  PosTotals call(PosTotalsInput input) {
    var totalGoldWt = 0.0;
    var totalSilverWt = 0.0;
    var totalPlatinumWt = 0.0;
    var totalDiamondWt = 0.0;

    var totalGoldAmount = 0.0;
    var totalSilverAmount = 0.0;
    var totalPlatinumAmount = 0.0;
    var totalDiamondAmount = 0.0;

    var goldSoldFine = 0.0;
    var silverSoldFine = 0.0;
    var platinumSoldFine = 0.0;
    var diamondSoldFine = 0.0;

    var goldMakingCharge = 0.0;
    var silverMakingCharge = 0.0;
    var platinumMakingCharge = 0.0;
    var diamondMakingCharge = 0.0;

    for (final item in input.saleItems) {
      final makingCharge = input.billingMode == BillingMode.wholesale
          ? item.wholesaleLabourAmt
          : item.makingAmt;

      switch (item.metal) {
        case MetalType.gold:
          totalGoldWt += item.netWt;
          totalGoldAmount += item.totalValue;
          goldSoldFine += item.fineWt;
          goldMakingCharge += makingCharge;
          break;
        case MetalType.silver:
          totalSilverWt += item.netWt;
          totalSilverAmount += item.totalValue;
          silverSoldFine += item.fineWt;
          silverMakingCharge += makingCharge;
          break;
        case MetalType.platinum:
          totalPlatinumWt += item.netWt;
          totalPlatinumAmount += item.totalValue;
          platinumSoldFine += item.fineWt;
          platinumMakingCharge += makingCharge;
          break;
        case MetalType.diamond:
          totalDiamondWt += item.netWt;
          totalDiamondAmount += item.totalValue;
          diamondSoldFine += item.fineWt;
          diamondMakingCharge += makingCharge;
          break;
      }
    }

    var totalTradeInAmount = 0.0;
    var goldJamaFine = 0.0;
    var silverJamaFine = 0.0;
    var platinumJamaFine = 0.0;
    var diamondJamaFine = 0.0;

    for (final item in input.tradeInItems) {
      totalTradeInAmount += item.totalValue;
      switch (item.metal) {
        case MetalType.gold:
          goldJamaFine += item.fineWt;
          break;
        case MetalType.silver:
          silverJamaFine += item.fineWt;
          break;
        case MetalType.platinum:
          platinumJamaFine += item.fineWt;
          break;
        case MetalType.diamond:
          diamondJamaFine += item.fineWt;
          break;
      }
    }

    goldSoldFine = _roundWeight(goldSoldFine);
    silverSoldFine = _roundWeight(silverSoldFine);
    platinumSoldFine = _roundWeight(platinumSoldFine);
    diamondSoldFine = _roundWeight(diamondSoldFine);
    goldJamaFine = _roundWeight(goldJamaFine);
    silverJamaFine = _roundWeight(silverJamaFine);
    platinumJamaFine = _roundWeight(platinumJamaFine);
    diamondJamaFine = _roundWeight(diamondJamaFine);

    final totalMakingCharge = goldMakingCharge +
        silverMakingCharge +
        platinumMakingCharge +
        diamondMakingCharge;

    final retailGrossAmount = totalGoldAmount +
        totalSilverAmount +
        totalPlatinumAmount +
        totalDiamondAmount;

    final goldNetFine = _roundWeight(goldSoldFine - goldJamaFine);
    final silverNetFine = _roundWeight(silverSoldFine - silverJamaFine);
    final platinumNetFine = _roundWeight(platinumSoldFine - platinumJamaFine);
    final diamondNetFine = _roundWeight(diamondSoldFine - diamondJamaFine);

    final goldBhawAmount = goldNetFine * (input.goldBhawInput / 10);
    final silverBhawAmount = silverNetFine * (input.silverBhawInput / 1000);
    final platinumBhawAmount = platinumNetFine * (input.platinumBhawInput / 10);
    final diamondBhawAmount = diamondNetFine * input.diamondBhawInput;

    final wholesaleTotalMetalAmount = goldBhawAmount +
        silverBhawAmount +
        platinumBhawAmount +
        diamondBhawAmount;
    final wholesaleGrossAmount = wholesaleTotalMetalAmount + totalMakingCharge;

    final grossAmount = input.billingMode == BillingMode.wholesale
        ? wholesaleGrossAmount
        : retailGrossAmount;
    final discountAmount = _discountAmount(input, grossAmount);
    final taxableAmount = grossAmount - discountAmount;

    final goldGst = _metalGst(
      input: input,
      grossAmount: grossAmount,
      discountAmount: discountAmount,
      wholesaleTotalMetalAmount: wholesaleTotalMetalAmount,
      metalAmount: goldBhawAmount,
      makingCharge: goldMakingCharge,
      retailAmount: totalGoldAmount,
      totalMakingCharge: totalMakingCharge,
      metal: MetalType.gold,
    );
    final silverGst = _metalGst(
      input: input,
      grossAmount: grossAmount,
      discountAmount: discountAmount,
      wholesaleTotalMetalAmount: wholesaleTotalMetalAmount,
      metalAmount: silverBhawAmount,
      makingCharge: silverMakingCharge,
      retailAmount: totalSilverAmount,
      totalMakingCharge: totalMakingCharge,
      metal: MetalType.silver,
    );
    final platinumGst = _metalGst(
      input: input,
      grossAmount: grossAmount,
      discountAmount: discountAmount,
      wholesaleTotalMetalAmount: wholesaleTotalMetalAmount,
      metalAmount: platinumBhawAmount,
      makingCharge: platinumMakingCharge,
      retailAmount: totalPlatinumAmount,
      totalMakingCharge: totalMakingCharge,
      metal: MetalType.platinum,
    );
    final diamondGst = _metalGst(
      input: input,
      grossAmount: grossAmount,
      discountAmount: discountAmount,
      wholesaleTotalMetalAmount: wholesaleTotalMetalAmount,
      metalAmount: diamondBhawAmount,
      makingCharge: diamondMakingCharge,
      retailAmount: totalDiamondAmount,
      totalMakingCharge: totalMakingCharge,
      metal: MetalType.diamond,
    );

    final totalGst = goldGst + silverGst + platinumGst + diamondGst;
    final cgst = totalGst / 2;
    final sgst = totalGst / 2;
    final grandTotal = taxableAmount + totalGst;
    final tradeInCashDeduction =
        input.tradeInMode == TradeInAdjustMode.cashAdjust
            ? totalTradeInAmount
            : 0.0;
    final finalPayableAmount = input.billingMode == BillingMode.wholesale
        ? grandTotal
        : grandTotal - tradeInCashDeduction;

    final paymentAllocation = _allocatePayments(input, finalPayableAmount);
    final totalPaid =
        input.cashInput + input.upiInput + input.cardInput + input.advanceInput;
    final excess = totalPaid - finalPayableAmount;
    final changeReturnAmount = excess > input.amountTolerance ? excess : 0.0;
    final invoiceTotalPaid = paymentAllocation.cash +
        paymentAllocation.upi +
        paymentAllocation.card +
        paymentAllocation.advance;

    return PosTotals(
      totalGoldWt: totalGoldWt,
      totalSilverWt: totalSilverWt,
      totalPlatinumWt: totalPlatinumWt,
      totalDiamondWt: totalDiamondWt,
      totalGoldAmount: totalGoldAmount,
      totalSilverAmount: totalSilverAmount,
      totalPlatinumAmount: totalPlatinumAmount,
      totalDiamondAmount: totalDiamondAmount,
      totalTradeInAmount: totalTradeInAmount,
      tradeInCashDeduction: tradeInCashDeduction,
      pureGoldAmount: totalGoldAmount - goldMakingCharge,
      pureSilverAmount: totalSilverAmount - silverMakingCharge,
      purePlatinumAmount: totalPlatinumAmount - platinumMakingCharge,
      pureDiamondAmount: totalDiamondAmount - diamondMakingCharge,
      goldSoldFine: goldSoldFine,
      silverSoldFine: silverSoldFine,
      platinumSoldFine: platinumSoldFine,
      diamondSoldFine: diamondSoldFine,
      goldJamaFine: goldJamaFine,
      silverJamaFine: silverJamaFine,
      platinumJamaFine: platinumJamaFine,
      diamondJamaFine: diamondJamaFine,
      goldNetFine: goldNetFine,
      silverNetFine: silverNetFine,
      platinumNetFine: platinumNetFine,
      diamondNetFine: diamondNetFine,
      goldBhawAmount: goldBhawAmount,
      silverBhawAmount: silverBhawAmount,
      platinumBhawAmount: platinumBhawAmount,
      diamondBhawAmount: diamondBhawAmount,
      goldMakingCharge: goldMakingCharge,
      silverMakingCharge: silverMakingCharge,
      platinumMakingCharge: platinumMakingCharge,
      diamondMakingCharge: diamondMakingCharge,
      totalMakingCharge: totalMakingCharge,
      grossAmount: grossAmount,
      discountAmount: discountAmount,
      taxableAmount: taxableAmount,
      goldGst: goldGst,
      silverGst: silverGst,
      platinumGst: platinumGst,
      diamondGst: diamondGst,
      totalGst: totalGst,
      cgst: cgst,
      sgst: sgst,
      grandTotal: grandTotal,
      finalPayableAmount: finalPayableAmount,
      cashPaidAmount: paymentAllocation.cash,
      upiPaidAmount: paymentAllocation.upi,
      cardPaidAmount: paymentAllocation.card,
      advancePaidAmount: paymentAllocation.advance,
      totalPaid: totalPaid,
      balanceDue: finalPayableAmount - totalPaid,
      changeReturnAmount: changeReturnAmount,
      invoiceTotalPaid: invoiceTotalPaid,
      invoiceBalanceDue: finalPayableAmount - invoiceTotalPaid,
      changeCreditSourcePaymentMode: _changeCreditSourcePaymentMode(
        input,
        paymentAllocation,
        changeReturnAmount,
      ),
    );
  }

  double _discountAmount(PosTotalsInput input, double grossAmount) {
    if (input.discountType == DiscountType.percentage) {
      final clampedPercentage = input.discountInput.clamp(0.0, 100.0);
      return grossAmount * clampedPercentage / 100;
    }
    return input.discountInput.clamp(0.0, grossAmount).toDouble();
  }

  double _metalGst({
    required PosTotalsInput input,
    required double grossAmount,
    required double discountAmount,
    required double wholesaleTotalMetalAmount,
    required double metalAmount,
    required double makingCharge,
    required double retailAmount,
    required double totalMakingCharge,
    required MetalType metal,
  }) {
    if (input.billType != BillType.gst) {
      return 0;
    }

    double ratio(double amount) => grossAmount == 0 ? 0 : amount / grossAmount;

    if (input.billingMode == BillingMode.wholesale) {
      final metalTaxable =
          metalAmount - (discountAmount * ratio(wholesaleTotalMetalAmount));
      final labourTaxable =
          makingCharge - (discountAmount * ratio(totalMakingCharge));
      return _taxAmount(
            input,
            metalTaxable,
            input.metalGstRates[metal] ?? input.defaultJewelleryGstRate,
          ) +
          _taxAmount(input, labourTaxable, input.makingGstRate);
    }

    final retailTaxable = retailAmount - (discountAmount * ratio(retailAmount));
    return _taxAmount(
      input,
      retailTaxable,
      input.metalGstRates[metal] ?? input.defaultJewelleryGstRate,
    );
  }

  double _taxAmount(PosTotalsInput input, double taxable, double rate) {
    if (taxable <= 0 || rate <= 0) {
      return 0;
    }
    final amount = taxable * rate;
    if (!input.roundOffGstAmount) {
      return amount;
    }
    return (amount * 100).roundToDouble() / 100;
  }

  _PaymentAllocation _allocatePayments(
    PosTotalsInput input,
    double finalPayableAmount,
  ) {
    var remaining = finalPayableAmount;
    if (remaining <= input.amountTolerance) {
      return const _PaymentAllocation();
    }

    double take(double raw) {
      if (remaining <= input.amountTolerance || raw <= 0) {
        return 0;
      }
      final allocated = raw > remaining ? remaining : raw;
      remaining -= allocated;
      return allocated;
    }

    return _PaymentAllocation(
      cash: take(input.cashInput),
      upi: take(input.upiInput),
      card: take(input.cardInput),
      advance: take(input.advanceInput),
    );
  }

  PaymentMode? _changeCreditSourcePaymentMode(
    PosTotalsInput input,
    _PaymentAllocation allocation,
    double changeReturnAmount,
  ) {
    if (changeReturnAmount <= input.amountTolerance) {
      return null;
    }
    if (input.cashInput - allocation.cash > input.amountTolerance) {
      return PaymentMode.cash;
    }
    if (input.upiInput - allocation.upi > input.amountTolerance) {
      return PaymentMode.upi;
    }
    if (input.cardInput - allocation.card > input.amountTolerance) {
      return PaymentMode.card;
    }
    if (input.advanceInput - allocation.advance > input.amountTolerance) {
      return PaymentMode.advance;
    }
    return PaymentMode.cash;
  }

  double _roundWeight(double value) {
    return PosWeightMath.roundToThreeDecimals(value);
  }
}

class _PaymentAllocation {
  const _PaymentAllocation({
    this.cash = 0,
    this.upi = 0,
    this.card = 0,
    this.advance = 0,
  });

  final double cash;
  final double upi;
  final double card;
  final double advance;
}
