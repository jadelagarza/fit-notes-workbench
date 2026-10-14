import 'email.dart';
import 'user.dart';

/// Contrato para iniciar sesión.
///
/// Los fallos se señalan con excepciones de dominio (`auth_exceptions.dart`):
/// - `InvalidCredentialsException`: credenciales que no corresponden a nadie.
/// - `ServiceUnavailableException`: error técnico del servicio.
abstract interface class AuthRepository {
  /// Identifica al usuario con [email] y [password].
  ///
  /// [password] se compara tal cual, sin recortar.
  Future<User> login({required Email email, required String password});
}
