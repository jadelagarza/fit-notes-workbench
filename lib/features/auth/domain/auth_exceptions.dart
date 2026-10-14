import 'email.dart';

/// Motivo por el que una contraseña introducida no es aceptable.
enum PasswordValidationError {
  /// La contraseña tiene cero caracteres. Nunca se recorta.
  required,
}

/// Las credenciales son válidas en formato, pero no corresponden a ningún
/// usuario.
class InvalidCredentialsException implements Exception {
  const InvalidCredentialsException();

  @override
  String toString() => 'InvalidCredentialsException';
}

/// Error técnico: el servicio de inicio de sesión no está disponible.
class ServiceUnavailableException implements Exception {
  const ServiceUnavailableException();

  @override
  String toString() => 'ServiceUnavailableException';
}

/// Los datos introducidos no superan la validación; no se envió ninguna
/// solicitud de inicio de sesión.
///
/// Lleva el error de cada campo, o `null` si ese campo es válido. Al menos uno
/// de los dos no es `null`.
class LoginValidationException implements Exception {
  const LoginValidationException({this.emailError, this.passwordError})
    : assert(
        emailError != null || passwordError != null,
        'Al menos un campo debe tener error',
      );

  final EmailValidationError? emailError;
  final PasswordValidationError? passwordError;

  @override
  String toString() {
    return 'LoginValidationException(email: $emailError, '
        'password: $passwordError)';
  }
}
