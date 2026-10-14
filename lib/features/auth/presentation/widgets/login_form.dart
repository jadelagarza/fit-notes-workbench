import 'package:flutter/material.dart';

import '../login_keys.dart';
import '../login_texts.dart';
import 'login_error_banner.dart';

/// Formulario de inicio de sesión: campos, mensaje de error, envío y progreso.
///
/// No valida ni decide nada: muestra los errores que recibe y avisa con
/// [onSubmit] cuando la persona intenta enviar.
class LoginForm extends StatelessWidget {
  const LoginForm({
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.onSubmit,
    this.emailErrorText,
    this.passwordErrorText,
    this.failureMessage,
    super.key,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onSubmit;
  final String? emailErrorText;
  final String? passwordErrorText;
  final String? failureMessage;

  @override
  Widget build(BuildContext context) {
    final failureMessage = this.failureMessage;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (failureMessage != null) ...[
          LoginErrorBanner(message: failureMessage),
          const SizedBox(height: 16),
        ],
        TextField(
          key: LoginKeys.emailField,
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: LoginTexts.emailLabel,
            errorText: emailErrorText,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          key: LoginKeys.passwordField,
          controller: passwordController,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          decoration: InputDecoration(
            labelText: LoginTexts.passwordLabel,
            errorText: passwordErrorText,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: LoginKeys.submitButton,
          onPressed: isLoading ? null : onSubmit,
          child: const Text(LoginTexts.submitButton),
        ),
        if (isLoading) ...[
          const SizedBox(height: 24),
          const Center(
            child: CircularProgressIndicator(
              key: LoginKeys.progressIndicator,
              semanticsLabel: LoginTexts.progressLabel,
            ),
          ),
        ],
      ],
    );
  }
}
