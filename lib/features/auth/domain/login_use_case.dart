import 'auth_exceptions.dart';
import 'auth_repository.dart';
import 'email.dart';
import 'user.dart';

/// Caso de uso: iniciar sesión con correo y contraseña.
///
/// Valida los dos campos a la vez y solo si ambos son válidos delega en el
/// [AuthRepository]. Nunca envía una solicitud con datos inválidos.
class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  /// Identifica al usuario con [email] y [password].
  ///
  /// Lanza [LoginValidationException] si algún campo es inválido; en ese caso
  /// no se llama al repositorio. Los errores del repositorio se propagan.
  ///
  /// El correo se recorta y se normaliza a minúsculas. La contraseña es vacía
  /// solo con cero caracteres y nunca se recorta.
  Future<User> call({required String email, required String password}) async {
    final emailError = Email.validate(email);
    final passwordError = password.isEmpty
        ? PasswordValidationError.required
        : null;

    if (emailError != null || passwordError != null) {
      throw LoginValidationException(
        emailError: emailError,
        passwordError: passwordError,
      );
    }

    return _repository.login(email: Email.parse(email), password: password);
  }
}
