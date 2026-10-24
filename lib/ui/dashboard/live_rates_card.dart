import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../logic/dashboard/live_rates/live_rates_logic.dart';
import '../../models/live_rates/live_rates_model.dart';
import '../../theme/dashboard/live_rates/live_rates_theme.dart';

class LiveRatesCard extends StatefulWidget {
  const LiveRatesCard({super.key});

  @override
  State<LiveRatesCard> createState() => _LiveRatesCardState();
}

class _LiveRatesCardState extends State<LiveRatesCard> {
  late final LiveRatesLogic _logic;
  bool _showPurchaseRates = false;

  @override
  void initState() {
    super.initState();
    _logic = LiveRatesLogic();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LiveRatesModel>(
      stream: _logic.ratesStream,
      initialData: _logic.initialData,
      builder: (context, snapshot) {
        final rates = snapshot.data ?? LiveRatesModel.loading();
        return Container(
          decoration: LiveRatesStyles.cardDecoration,
          padding: const EdgeInsets.all(16),
          child: rates.isLoading
              ? const _RatesLoadingState()
              : rates.isAvailable
                  ? _RatesContent(
                      rates: rates,
                      showPurchaseRates: _showPurchaseRates,
                      onTogglePurchaseRates: () => setState(
                        () => _showPurchaseRates = !_showPurchaseRates,
                      ),
                    )
                  : _RatesUnavailableState(rates: rates),
        );
      },
    );
  }
}

class _RatesContent extends StatelessWidget {
  const _RatesContent({
    required this.rates,
    required this.showPurchaseRates,
    required this.onTogglePurchaseRates,
  });

  final LiveRatesModel rates;
  final bool showPurchaseRates;
  final VoidCallback onTogglePurchaseRates;

  @override
  Widget build(BuildContext context) {
    final updated = rates.rateDate == null
        ? 'Update time unavailable'
        : DateFormat('dd MMM, hh:mm a').format(rates.rateDate!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.currency_exchange_rounded,
                color: LiveRatesColors.goldMain),
            const SizedBox(width: 8),
            const Text('Metal Rates', style: LiveRatesStyles.cardTitleStyle),
            const Spacer(),
            _SourceChip(source: rates.source),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            final gold = _RatePanel(
              title: 'GOLD',
              unit: '₹ / 10g',
              color: LiveRatesColors.goldMain,
              rows: [
                ('24K', rates.gold24k),
                ('22K', rates.gold22k),
                ('18K', rates.gold18k),
              ],
            );
            final silver = _RatePanel(
              title: 'SILVER',
              unit: '₹ / 10g',
              color: LiveRatesColors.silverMain,
              rows: [
                ('999', rates.silverIdols),
                ('925', rates.silverJewellery),
                ('Per kg', rates.silverRateKg),
              ],
            );
            if (compact) {
              return Column(
                  children: [gold, const SizedBox(height: 12), silver]);
            }
            return Row(children: [
              Expanded(child: gold),
              const SizedBox(width: 12),
              Expanded(child: silver),
            ]);
          },
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: onTogglePurchaseRates,
          icon: Icon(showPurchaseRates
              ? Icons.expand_less_rounded
              : Icons.expand_more_rounded),
          label: Text(showPurchaseRates
              ? 'Hide purchase rates'
              : 'View purchase rates'),
        ),
        if (showPurchaseRates) ...[
          const SizedBox(height: 4),
          _PurchaseRatesPanel(rates: rates),
        ],
        const SizedBox(height: 10),
        Text('Last updated: $updated', style: LiveRatesStyles.timestampStyle),
      ],
    );
  }
}

class _RatePanel extends StatelessWidget {
  const _RatePanel({
    required this.title,
    required this.unit,
    required this.color,
    required this.rows,
  });

  final String title;
  final String unit;
  final Color color;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: LiveRatesStyles.metalTitleStyle.copyWith(color: color)),
            const SizedBox(height: 3),
            Text(unit, style: LiveRatesStyles.unitStyle),
            const SizedBox(height: 10),
            ...rows.map((row) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(children: [
                    Expanded(
                        child:
                            Text(row.$1, style: LiveRatesStyles.subLabelStyle)),
                    Text('₹${row.$2}', style: LiveRatesStyles.subPriceStyle),
                  ]),
                )),
          ],
        ),
      );
}

class _PurchaseRatesPanel extends StatelessWidget {
  const _PurchaseRatesPanel({required this.rates});
  final LiveRatesModel rates;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: LiveRatesColors.expandedBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Wrap(
          spacing: 18,
          runSpacing: 8,
          children: [
            _PurchaseRate(label: '24K buy', value: rates.oldGold24kBuy),
            _PurchaseRate(label: '22K buy', value: rates.oldGold22kBuy),
            _PurchaseRate(label: '18K buy', value: rates.oldGold18kBuy),
            _PurchaseRate(label: 'Silver buy', value: rates.oldSilverBuy),
          ],
        ),
      );
}

class _PurchaseRate extends StatelessWidget {
  const _PurchaseRate({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) =>
      Text('$label: ₹$value', style: LiveRatesStyles.subLabelStyle);
}

class _RatesLoadingState extends StatelessWidget {
  const _RatesLoadingState();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 160,
        child: Center(
          child: CircularProgressIndicator(color: LiveRatesColors.goldMain),
        ),
      );
}

class _RatesUnavailableState extends StatelessWidget {
  const _RatesUnavailableState({required this.rates});
  final LiveRatesModel rates;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 160,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.price_check_outlined,
                size: 32, color: LiveRatesColors.textSecondary),
            const SizedBox(height: 10),
            Text(rates.message ?? 'Rates unavailable.',
                style: LiveRatesStyles.subLabelStyle,
                textAlign: TextAlign.center),
          ]),
        ),
      );
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.source});
  final String source;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: LiveRatesColors.upGreen.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(source,
            style: LiveRatesStyles.timestampStyle.copyWith(
              color: LiveRatesColors.upGreen,
              fontStyle: FontStyle.normal,
            )),
      );
}
