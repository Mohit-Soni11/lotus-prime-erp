import 'package:flutter/material.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';

/// Presents the same form content as either a workspace or a compact dialog.
class DayBookFormFrame extends StatelessWidget {
  final bool fullScreen;
  final String title;
  final double dialogWidth;
  final VoidCallback? onBack;
  final Widget child;
  const DayBookFormFrame(
      {super.key,
      required this.fullScreen,
      required this.title,
      required this.dialogWidth,
      required this.child,
      this.onBack});

  @override
  Widget build(BuildContext context) {
    if (fullScreen) {
      return Scaffold(
        backgroundColor: DayBookColors.bodyBg,
        appBar: AppBar(
          backgroundColor: DayBookColors.shellPanel,
          foregroundColor: Colors.white,
          leading: IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded)),
          title: Text(title,
              style:
                  const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
        ),
        body: SafeArea(
            child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: SizedBox.expand(child: child),
        )),
      );
    }
    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      backgroundColor: const Color(0xFFFFFEFC),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: DayBookColors.brandGoldBorder)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: dialogWidth,
            maxHeight: MediaQuery.sizeOf(context).height - 36),
        child: child,
      ),
    );
  }
}
