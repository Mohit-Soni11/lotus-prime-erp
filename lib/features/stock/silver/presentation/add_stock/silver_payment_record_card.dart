import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lotus_erp/features/stock/silver/application/silver_payment_controller.dart';
import 'package:lotus_erp/features/stock/silver/application/silver_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_silver/silver_stock_theme.dart';

part 'silver_payment_settlement_tabs.dart';
part 'silver_payment_settlement_boards.dart';
part 'silver_payment_shared_widgets.dart';

class SilverPaymentRecordCard extends StatefulWidget {
  final SilverStockController ctrl;

  const SilverPaymentRecordCard({super.key, required this.ctrl});

  @override
  State<SilverPaymentRecordCard> createState() =>
      _SilverPaymentRecordCardState();
}

class _SilverPaymentRecordCardState extends State<SilverPaymentRecordCard> {
  bool _metalLineScheduled = false;

  SilverPaymentController get payment => widget.ctrl.payment;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.ctrl, payment]),
      builder: (context, _) {
        _ensureMetalLineWhenNeeded();

        return _SilverCardShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _CardHeader(
                icon: SilverStockIcons.metalExchange,
                title: '5. Settlement Method',
                subtitle:
                    'Settle supplier using silver metal, cash or mixed payment.',
              ),
              const Divider(height: 1, color: SilverStockColors.cardBorder),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SettlementModeTabs(payment: payment),
                    const SizedBox(height: 14),
                    _SettlementDiscountPanel(payment: payment),
                    const SizedBox(height: 14),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: payment.usesMetalSettlement
                          ? _MetalSettlementBoard(
                              key: const ValueKey('metal-settlement'),
                              payment: payment,
                            )
                          : _CashSettlementBoard(
                              key: const ValueKey('cash-settlement'),
                              payment: payment,
                            ),
                    ),
                    const SizedBox(height: 14),
                    _CashSplitGrid(payment: payment),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _ensureMetalLineWhenNeeded() {
    if (!payment.usesMetalSettlement ||
        payment.metalLines.isNotEmpty ||
        _metalLineScheduled) {
      return;
    }

    _metalLineScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      payment.addMetalLine();
      _metalLineScheduled = false;
    });
  }
}
