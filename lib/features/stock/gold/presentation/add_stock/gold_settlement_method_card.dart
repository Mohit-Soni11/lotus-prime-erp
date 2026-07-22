import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lotus_erp/features/stock/gold/application/gold_payment_controller.dart';
import 'package:lotus_erp/features/stock/gold/application/gold_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_gold/gold_stock_theme.dart';

part 'gold_settlement_tabs.dart';
part 'gold_settlement_boards.dart';
part 'gold_settlement_shared_widgets.dart';

class GoldSettlementMethodCard extends StatefulWidget {
  final GoldStockController ctrl;

  const GoldSettlementMethodCard({super.key, required this.ctrl});

  @override
  State<GoldSettlementMethodCard> createState() =>
      _GoldSettlementMethodCardState();
}

class _GoldSettlementMethodCardState extends State<GoldSettlementMethodCard> {
  bool _metalLineScheduled = false;

  GoldPaymentController get payment => widget.ctrl.payment;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.ctrl, payment]),
      builder: (context, _) {
        _ensureMetalLineWhenNeeded();

        return _GoldCardShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _CardHeader(
                icon: GoldStockIcons.metalExchange,
                title: '5. Settlement Method',
                subtitle: 'Choose metal, cash or mixed supplier settlement.',
              ),
              const Divider(height: 1, color: GoldStockColors.cardBorder),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SettlementModeTabs(payment: payment),
                    const SizedBox(height: 14),
                    _SettlementDiscountPanel(payment: payment),
                    const SizedBox(height: 14),
                    if (payment.paymentMode == PaymentMode.metalToMetal)
                      _MetalSettlementBoard(payment: payment)
                    else
                      _CashSettlementBoard(payment: payment),
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
    if (payment.paymentMode != PaymentMode.metalToMetal ||
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
