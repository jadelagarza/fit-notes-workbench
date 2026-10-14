import 'package:flutter/widgets.dart';

/// Claves estables de la pantalla de inicio de sesión, para las pruebas.
abstract final class LoginKeys {
  static const Key emailField = Key('login_email_field');
  static const Key passwordField = Key('login_password_field');
  static const Key submitButton = Key('login_submit_button');
  static const Key progressIndicator = Key('login_progress_indicator');
  static const Key errorMessage = Key('login_error_message');
  static const Key successView = Key('login_success_view');
  static const Key backButton = Key('login_back_button');
}
