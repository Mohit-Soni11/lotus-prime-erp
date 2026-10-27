import 'package:flutter/material.dart';

enum SystemStatus { loading, online, unavailable }

class SystemStatusBadge extends StatefulWidget {
  const SystemStatusBadge({
    super.key,
    required this.status,
    this.showLabel = true,
  });

  final SystemStatus status;
  final bool showLabel;

  @override
  State<SystemStatusBadge> createState() => _SystemStatusBadgeState();
}

class _SystemStatusBadgeState extends State<SystemStatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(SystemStatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    if (widget.status == SystemStatus.online &&
        !MediaQuery.disableAnimationsOf(context)) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (widget.status) {
      SystemStatus.online => ('SYSTEM ONLINE', const Color(0xFF00E676)),
      SystemStatus.loading => ('LOADING DATA', const Color(0xFFFFC857)),
      SystemStatus.unavailable => ('DATA UNAVAILABLE', const Color(0xFFFF7777)),
    };

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              child: SizedBox(
                width: 16,
                height: 16,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) {
                    final online = widget.status == SystemStatus.online;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        if (online)
                          Opacity(
                            opacity: 1 - _pulse.value,
                            child: Transform.scale(
                              scale: 0.65 + _pulse.value * 1.25,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: color),
                                ),
                              ),
                            ),
                          ),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.65),
                                blurRadius: 7,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (widget.showLabel) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
