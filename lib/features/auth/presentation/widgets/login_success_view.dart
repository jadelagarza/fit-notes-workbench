import 'package:flutter/material.dart';

import '../login_keys.dart';
import '../login_texts.dart';
import '../user_model.dart';

/// Bienvenida del usuario identificado, con el botón para volver al formulario.
class LoginSuccessView extends StatelessWidget {
  const LoginSuccessView({required this.user, required this.onBack, super.key});

  final UserModel user;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      key: LoginKeys.successView,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          LoginTexts.welcome(user.displayName),
          style: textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          user.email,
          style: textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          key: LoginKeys.backButton,
          onPressed: onBack,
          child: const Text(LoginTexts.backToForm),
        ),
      ],
    );
  }
}
