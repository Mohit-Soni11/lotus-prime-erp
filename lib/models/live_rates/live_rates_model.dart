enum LiveRateState { loading, available, missing, error }

class LiveRatesModel {
  const LiveRatesModel({
    required this.state,
    required this.gold24k,
    required this.gold22k,
    required this.gold18k,
    required this.gold24kPerGram,
    required this.gold22kPerGram,
    required this.gold18kPerGram,
    required this.silverRateKg,
    required this.silverJewellery,
    required this.silverIdols,
    required this.silver999PerGram,
    required this.silver925PerGram,
    required this.silver925RateKg,
    required this.oldGold24kBuy,
    required this.oldGold22kBuy,
    required this.oldGold18kBuy,
    required this.oldSilverBuy,
    required this.rateDate,
    required this.source,
    this.message,
  });

  final LiveRateState state;
  final String gold24k;
  final String gold22k;
  final String gold18k;
  final String gold24kPerGram;
  final String gold22kPerGram;
  final String gold18kPerGram;
  final String silverRateKg;
  final String silverJewellery;
  final String silverIdols;
  final String silver999PerGram;
  final String silver925PerGram;
  final String silver925RateKg;
  final String oldGold24kBuy;
  final String oldGold22kBuy;
  final String oldGold18kBuy;
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
      gold24k: '--',
      gold22k: '--',
      gold18k: '--',
      gold24kPerGram: '--',
      gold22kPerGram: '--',
      gold18kPerGram: '--',
      silverRateKg: '--',
      silverJewellery: '--',
      silverIdols: '--',
      silver999PerGram: '--',
      silver925PerGram: '--',
      silver925RateKg: '--',
      oldGold24kBuy: '--',
      oldGold22kBuy: '--',
      oldGold18kBuy: '--',
      oldSilverBuy: '--',
      rateDate: null,
      source: '',
      message: message,
    );
  }
}
