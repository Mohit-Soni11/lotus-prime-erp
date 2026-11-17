enum LiveRateState { loading, available, missing, error }

class LiveMetalRate {
  const LiveMetalRate({
    required this.purity,
    required this.perGram,
    required this.perBaseUnit,
    this.description,
  });

  final String purity;
  final String perGram;
  final String perBaseUnit;
  final String? description;
}

class LiveRatesModel {
  const LiveRatesModel({
    required this.state,
    required this.goldRates,
    required this.silverRates,
    required this.oldGoldBuy,
    required this.oldSilverBuy,
    required this.rateDate,
    required this.source,
    this.message,
  });

  final LiveRateState state;
  final List<LiveMetalRate> goldRates;
  final List<LiveMetalRate> silverRates;
  final String oldGoldBuy;
  final String oldSilverBuy;
  final DateTime? rateDate;
  final String source;
  final String? message;

  bool get isLoading => state == LiveRateState.loading;
  bool get isAvailable => state == LiveRateState.available;

  factory LiveRatesModel.loading() => _empty(LiveRateState.loading);

  factory LiveRatesModel.missing() => _empty(
        LiveRateState.missing,
        message: 'Configure selling rates in Metal Rate Master.',
      );

  factory LiveRatesModel.error() => _empty(
        LiveRateState.error,
        message: 'Rates could not be loaded.',
      );

  static LiveRatesModel _empty(LiveRateState state, {String? message}) {
    return LiveRatesModel(
      state: state,
      goldRates: const [],
      silverRates: const [],
      oldGoldBuy: '--',
      oldSilverBuy: '--',
      rateDate: null,
      source: '',
      message: message,
    );
  }
}
