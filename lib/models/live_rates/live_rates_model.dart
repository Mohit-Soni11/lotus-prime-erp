// ============================================================
// 📊 LIVE RATES MODEL
// UI ko data dene ke liye clean data class
// ============================================================

class LiveRatesModel {
  // --- Gold ---
  final String gold24k;
  final String gold22k;
  final String gold18k;
  final String goldChangePercent;
  final bool goldIsUp;

  // --- Silver ---
  final String silverRateKg;
  final String silverJewellery;
  final String silverIdols;
  final String silverChangePercent;
  final bool silverIsUp;

  // --- Old Gold Buy Rates ---
  final String oldGold24kBuy;
  final String oldGold22kBuy;
  final String oldGold18kBuy;
  final String oldSilverBuy;

  // --- Meta ---
  final DateTime rateDate;
  final String source;
  final bool isFromDb; // false = fallback/dummy data

  const LiveRatesModel({
    required this.gold24k,
    required this.gold22k,
    required this.gold18k,
    required this.goldChangePercent,
    required this.goldIsUp,
    required this.silverRateKg,
    required this.silverJewellery,
    required this.silverIdols,
    required this.silverChangePercent,
    required this.silverIsUp,
    required this.oldGold24kBuy,
    required this.oldGold22kBuy,
    required this.oldGold18kBuy,
    required this.oldSilverBuy,
    required this.rateDate,
    required this.source,
    required this.isFromDb,
  });

  // ✅ Fallback / Loading state
  static final LiveRatesModel loading = LiveRatesModel(
    gold24k: '--',
    gold22k: '--',
    gold18k: '--',
    goldChangePercent: '+0.0%',
    goldIsUp: true,
    silverRateKg: '--',
    silverJewellery: '--',
    silverIdols: '--',
    silverChangePercent: '+0.0%',
    silverIsUp: true,
    oldGold24kBuy: '--',
    oldGold22kBuy: '--',
    oldGold18kBuy: '--',
    oldSilverBuy: '--',
    rateDate: DateTime.now(),
    source: 'Loading...',
    isFromDb: false,
  );

  // ✅ Demo data (jab DB mein koi rate na ho)
  static final LiveRatesModel demo = LiveRatesModel(
    gold24k: '72,500',
    gold22k: '66,200',
    gold18k: '54,430',
    goldChangePercent: '+0.5%',
    goldIsUp: true,
    silverRateKg: '90,000',
    silverJewellery: '8,200',
    silverIdols: '8,500',
    silverChangePercent: '+0.8%',
    silverIsUp: true,
    oldGold24kBuy: '71,000',
    oldGold22kBuy: '64,500',
    oldGold18kBuy: '52,200',
    oldSilverBuy: '85,000',
    rateDate: DateTime.now(),
    source: 'Demo Data',
    isFromDb: false,
  );
}