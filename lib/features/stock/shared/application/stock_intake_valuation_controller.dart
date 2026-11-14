import 'package:flutter/material.dart';

/// Values the received stock without recording how the supplier was paid.
class StockIntakeValuationController extends ChangeNotifier {
  StockIntakeValuationController({required this.gramsPerRate})
      : assert(gramsPerRate > 0) {
    rateCtrl.addListener(notifyListeners);
    gstPercentCtrl.addListener(notifyListeners);
  }

  final double gramsPerRate;
  final TextEditingController rateCtrl = TextEditingController();
  final TextEditingController gstPercentCtrl = TextEditingController(text: '3');

  double _fineWeight = 0;
  double _makingAmount = 0;
  bool _gstEnabled = false;

  double get ratePerBase => _number(rateCtrl.text);
  double get ratePerGram => ratePerBase / gramsPerRate;
  double get fineWeight => _fineWeight;
  double get makingAmount => _makingAmount;
  double get metalValue => fineWeight * ratePerGram;
  double get subtotalAmount => metalValue + makingAmount;
  double get configuredGstPercent =>
      _number(gstPercentCtrl.text).clamp(0, 100).toDouble();
  double get gstPercent => _gstEnabled ? configuredGstPercent : 0;
  double get gstAmount => subtotalAmount * gstPercent / 100;
  double get totalAmount => subtotalAmount + gstAmount;

  void setRatePerBase(double value) {
    final next = value > 0 ? _format(value) : '';
    if (rateCtrl.text != next) rateCtrl.text = next;
  }

  void updateTotals(
      {required double fineWeight,
      required double makingAmount,
      bool notify = true}) {
    if (_fineWeight == fineWeight && _makingAmount == makingAmount) return;
    _fineWeight = fineWeight;
    _makingAmount = makingAmount;
    if (notify) notifyListeners();
  }

  void setGstEnabled(bool value, {bool notify = true}) {
    if (_gstEnabled == value) return;
    _gstEnabled = value;
    if (notify) notifyListeners();
  }

  void reset() {
    _fineWeight = 0;
    _makingAmount = 0;
    rateCtrl.clear();
    gstPercentCtrl.text = '3';
    notifyListeners();
  }

  static double _number(String text) =>
      double.tryParse(text.replaceAll(',', '').trim()) ?? 0;

  static String _format(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';

  @override
  void dispose() {
    rateCtrl.dispose();
    gstPercentCtrl.dispose();
    super.dispose();
  }
}

class StockIntakeValuationSnapshot {
  const StockIntakeValuationSnapshot({
    required this.ratePerBase,
    required this.ratePerGram,
    required this.fineWeight,
    required this.makingAmount,
    required this.metalValue,
    required this.subtotalAmount,
    required this.gstPercent,
    required this.gstAmount,
    required this.totalAmount,
  });

  final double ratePerBase;
  final double ratePerGram;
  final double fineWeight;
  final double makingAmount;
  final double metalValue;
  final double subtotalAmount;
  final double gstPercent;
  final double gstAmount;
  final double totalAmount;

  factory StockIntakeValuationSnapshot.fromController(
    StockIntakeValuationController controller,
  ) =>
      StockIntakeValuationSnapshot(
        ratePerBase: controller.ratePerBase,
        ratePerGram: controller.ratePerGram,
        fineWeight: controller.fineWeight,
        makingAmount: controller.makingAmount,
        metalValue: controller.metalValue,
        subtotalAmount: controller.subtotalAmount,
        gstPercent: controller.gstPercent,
        gstAmount: controller.gstAmount,
        totalAmount: controller.totalAmount,
      );
}
