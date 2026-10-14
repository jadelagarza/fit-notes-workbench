import '../domain/auth_exceptions.dart';
import '../domain/email.dart';

/// Todas las cadenas visibles de la pantalla de inicio de sesión (español).
abstract final class LoginTexts {
  static const String appTitle = 'FitNotes';
  static const String screenTitle = 'Iniciar sesión';

  static const String emailLabel = 'Correo electrónico';
  static const String passwordLabel = 'Contraseña';
  static const String submitButton = 'Iniciar sesión';
  static const String progressLabel = 'Iniciando sesión…';

  static const String emailRequired = 'Introduce tu correo electrónico.';
  static const String emailInvalidFormat =
      'El correo electrónico no tiene un formato válido.';
  static const String passwordRequired = 'Introduce tu contraseña.';

  static const String invalidCredentials =
      'Credenciales inválidas: el correo o la contraseña no son correctos.';
  static const String serviceUnavailable =
      'Servicio no disponible: inténtalo de nuevo más tarde.';

  static const String backToForm = 'Volver al formulario';

  static String welcome(String displayName) => 'Bienvenido, $displayName';

  static String emailError(EmailValidationError error) {
    return switch (error) {
      EmailValidationError.required => emailRequired,
      EmailValidationError.invalidFormat => emailInvalidFormat,
    };
  }

  static String passwordError(PasswordValidationError error) {
    return switch (error) {
      PasswordValidationError.required => passwordRequired,
    };
  }
}
