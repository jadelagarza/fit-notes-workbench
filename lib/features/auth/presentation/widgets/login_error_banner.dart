import 'package:flutter/material.dart';

import '../login_keys.dart';

/// Mensaje visible del error del inicio de sesión.
class LoginErrorBanner extends StatelessWidget {
  const LoginErrorBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      liveRegion: true,
      child: Container(
        key: LoginKeys.errorMessage,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(message, style: TextStyle(color: colors.onErrorContainer)),
      ),
    );
  }
}
