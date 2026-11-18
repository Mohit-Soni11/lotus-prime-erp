import 'package:flutter/material.dart';

import '../../theme/dashboard/app/uv.dart';
import 'services/auth_session_controller.dart';

class AuthGateScreen extends StatelessWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AuthSessionController.instance;
    return Scaffold(
      backgroundColor: UV.colors.bgPrimary,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListenableBuilder(
            listenable: session,
            builder: (context, _) {
              if (session.status == AuthSessionStatus.checking) {
                return const CircularProgressIndicator();
              }
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 40),
                    const SizedBox(height: 16),
                    Text('Session check unavailable', style: UV.styles.h2),
                    const SizedBox(height: 8),
                    Text(
                      session.message,
                      textAlign: TextAlign.center,
                      style: UV.styles.body,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: session.retry,
                      child: const Text('Retry'),
                    ),
                    TextButton(
                      onPressed: session.signOut,
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
