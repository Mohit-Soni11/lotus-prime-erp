part of 'booking_invoice_command_panel.dart';

class _ShellSectionLabel extends StatelessWidget {
  const _ShellSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: BookingAdvanceColors.shellTextMuted,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    );
  }
}
