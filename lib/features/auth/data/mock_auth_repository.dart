import '../domain/auth_exceptions.dart';
import '../domain/auth_repository.dart';
import '../domain/email.dart';
import '../domain/user.dart';
import 'user_dto.dart';

/// Repositorio simulado de inicio de sesión: determinista, sin red ni
/// aleatoriedad. El escenario se decide solo por las credenciales recibidas.
///
/// Todas las credenciales son valores ficticios de prueba y no protegen nada
/// real.
class MockAuthRepository implements AuthRepository {
  /// [latency] es el tiempo que se espera antes de responder.
  const MockAuthRepository({this.latency = Duration.zero});

  /// Correo del escenario de éxito.
  static const String successEmail = 'demo@fitnotes.dev';

  /// Contraseña del escenario de éxito. Se compara de forma exacta.
  static const String successPassword = 'Demo1234';

  /// Correo del escenario de error técnico, con cualquier contraseña.
  static const String serviceFailureEmail = 'fallo@fitnotes.dev';

  static const Map<String, dynamic> _successUserJson = <String, dynamic>{
    'id': 'user-demo-001',
    'name': 'Demo FitNotes',
    'email': successEmail,
  };

  final Duration latency;

  /// Escenarios, tras esperar [latency]:
  /// - [serviceFailureEmail] con cualquier contraseña: lanza
  ///   [ServiceUnavailableException].
  /// - [successEmail] con [successPassword]: devuelve el usuario de prueba.
  /// - Cualquier otra combinación: lanza [InvalidCredentialsException].
  @override
  Future<User> login({required Email email, required String password}) async {
    await Future<void>.delayed(latency);

    if (email.value == serviceFailureEmail) {
      throw const ServiceUnavailableException();
    }

    if (email.value == successEmail && password == successPassword) {
      return UserDTO.fromJson(_successUserJson).toEntity();
    }

    throw const InvalidCredentialsException();
  }
}
