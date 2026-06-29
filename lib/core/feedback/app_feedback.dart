import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppFeedbackType {
  success,
  error,
  warning,
  info,
}

class AppFeedbackAction {
  final String label;
  final VoidCallback onPressed;

  const AppFeedbackAction({
    required this.label,
    required this.onPressed,
  });
}

class AppFeedback {
  AppFeedback._();

  static OverlayEntry? _activeEntry;

  static void success(
    BuildContext context, {
    String? title,
    required String message,
    Duration duration = const Duration(milliseconds: 1800),
    AppFeedbackAction? action,
  }) {
    show(
      context,
      type: AppFeedbackType.success,
      title: title,
      message: message,
      duration: duration,
      action: action,
    );
  }

  static void error(
    BuildContext context, {
    String? title,
    required String message,
    Duration duration = const Duration(milliseconds: 2800),
    AppFeedbackAction? action,
  }) {
    show(
      context,
      type: AppFeedbackType.error,
      title: title,
      message: message,
      duration: duration,
      action: action,
    );
  }

  static void warning(
    BuildContext context, {
    String? title,
    required String message,
    Duration duration = const Duration(milliseconds: 2600),
    AppFeedbackAction? action,
  }) {
    show(
      context,
      type: AppFeedbackType.warning,
      title: title,
      message: message,
      duration: duration,
      action: action,
    );
  }

  static void info(
    BuildContext context, {
    String? title,
    required String message,
    Duration duration = const Duration(milliseconds: 2200),
    AppFeedbackAction? action,
  }) {
    show(
      context,
      type: AppFeedbackType.info,
      title: title,
      message: message,
      duration: duration,
      action: action,
    );
  }

  static void show(
    BuildContext context, {
    required AppFeedbackType type,
    String? title,
    required String message,
    Duration duration = const Duration(milliseconds: 2200),
    AppFeedbackAction? action,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    hide();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _AppFeedbackOverlay(
        type: type,
        title: title ?? _defaultTitle(type),
        message: message,
        action: action,
        onDismiss: () {
          if (_activeEntry == entry) {
            entry.remove();
            _activeEntry = null;
          }
        },
      ),
    );

    _activeEntry = entry;
    overlay.insert(entry);

    Future<void>.delayed(duration, () {
      if (_activeEntry == entry) {
        entry.remove();
        _activeEntry = null;
      }
    });
  }

  static void hide() {
    _activeEntry?.remove();
    _activeEntry = null;
  }

  static String _defaultTitle(AppFeedbackType type) {
    switch (type) {
      case AppFeedbackType.success:
        return 'Done Successfully';
      case AppFeedbackType.error:
        return 'Action Failed';
      case AppFeedbackType.warning:
        return 'Needs Attention';
      case AppFeedbackType.info:
        return 'Information';
    }
  }
}

class _AppFeedbackOverlay extends StatelessWidget {
  final AppFeedbackType type;
  final String title;
  final String message;
  final AppFeedbackAction? action;
  final VoidCallback onDismiss;

  const _AppFeedbackOverlay({
    required this.type,
    required this.title,
    required this.message,
    required this.action,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = _AppFeedbackTheme.forType(type);
    final media = MediaQuery.of(context);
    final maxWidth = media.size.width < 420 ? media.size.width - 36 : 360.0;
    final hasAction = action != null;

    final overlay = Material(
      color: Colors.black.withValues(alpha: 0.08),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.94, end: 1),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            final opacity = ((value - 0.94) / 0.06).clamp(0.0, 1.0);

            return Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: value,
                child: child,
              ),
            );
          },
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.borderColor),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 34,
                    offset: Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.backgroundColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.borderColor),
                    ),
                    child: Icon(
                      theme.icon,
                      color: theme.accentColor,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      color: const Color(0xFF111827),
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF374151),
                      fontSize: 12.5,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                  if (hasAction) ...[
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 38,
                      child: ElevatedButton(
                        onPressed: () {
                          final currentAction = action;
                          onDismiss();
                          currentAction?.onPressed();
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: theme.accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                        child: Text(action!.label),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Positioned.fill(
      child: hasAction ? overlay : IgnorePointer(child: overlay),
    );
  }
}

class _AppFeedbackTheme {
  final IconData icon;
  final Color accentColor;
  final Color backgroundColor;
  final Color borderColor;

  const _AppFeedbackTheme({
    required this.icon,
    required this.accentColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  static _AppFeedbackTheme forType(AppFeedbackType type) {
    switch (type) {
      case AppFeedbackType.success:
        return const _AppFeedbackTheme(
          icon: Icons.check_rounded,
          accentColor: Color(0xFF10B981),
          backgroundColor: Color(0x1A10B981),
          borderColor: Color(0x3310B981),
        );
      case AppFeedbackType.error:
        return const _AppFeedbackTheme(
          icon: Icons.close_rounded,
          accentColor: Color(0xFFEF4444),
          backgroundColor: Color(0x1AEF4444),
          borderColor: Color(0x33EF4444),
        );
      case AppFeedbackType.warning:
        return const _AppFeedbackTheme(
          icon: Icons.priority_high_rounded,
          accentColor: Color(0xFFF59E0B),
          backgroundColor: Color(0x1AF59E0B),
          borderColor: Color(0x33F59E0B),
        );
      case AppFeedbackType.info:
        return const _AppFeedbackTheme(
          icon: Icons.info_outline_rounded,
          accentColor: Color(0xFF3B82F6),
          backgroundColor: Color(0x1A3B82F6),
          borderColor: Color(0x333B82F6),
        );
    }
  }
}
