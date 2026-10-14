import 'package:fit_notes/features/auth/domain/auth_exceptions.dart';
import 'package:fit_notes/features/auth/domain/auth_repository.dart';
import 'package:fit_notes/features/auth/domain/email.dart';
import 'package:fit_notes/features/auth/domain/login_use_case.dart';
import 'package:fit_notes/features/auth/domain/user.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingAuthRepository implements AuthRepository {
  _RecordingAuthRepository({this.error});

  final Object? error;
  final List<({Email email, String password})> calls = [];

  static final User demoUser = User(
    id: 'user-demo-001',
    name: 'Demo FitNotes',
    email: Email.parse('demo@fitnotes.dev'),
  );

  @override
  Future<User> login({required Email email, required String password}) async {
    calls.add((email: email, password: password));
    final failure = error;
    if (failure != null) {
      throw failure;
    }

    return demoUser;
  }
}

Matcher _validationError({
  EmailValidationError? email,
  PasswordValidationError? password,
}) {
  return isA<LoginValidationException>()
      .having((e) => e.emailError, 'emailError', email)
      .having((e) => e.passwordError, 'passwordError', password);
}

void main() {
  late _RecordingAuthRepository repository;
  late LoginUseCase useCase;

  setUp(() {
    repository = _RecordingAuthRepository();
    useCase = LoginUseCase(repository);
  });

  group('validación previa a la solicitud', () {
    test('correo vacío: error de correo obligatorio y sin solicitud', () async {
      await expectLater(
        useCase(email: '', password: 'Demo1234'),
        throwsA(_validationError(email: EmailValidationError.required)),
      );

      expect(repository.calls, isEmpty);
    });

    test('correo de solo espacios: error de correo obligatorio', () async {
      await expectLater(
        useCase(email: '   ', password: 'Demo1234'),
        throwsA(_validationError(email: EmailValidationError.required)),
      );

      expect(repository.calls, isEmpty);
    });

    test('correo con formato inválido: error de formato distinto', () async {
      for (final email in ['demofitnotes.dev', 'a@b', 'a@@b.com', '@b.com']) {
        await expectLater(
          useCase(email: email, password: 'x'),
          throwsA(_validationError(email: EmailValidationError.invalidFormat)),
          reason: email,
        );
      }

      expect(repository.calls, isEmpty);
    });

    test('contraseña vacía: error de contraseña y sin solicitud', () async {
      await expectLater(
        useCase(email: 'demo@fitnotes.dev', password: ''),
        throwsA(_validationError(password: PasswordValidationError.required)),
      );
      await expectLater(
        useCase(email: 'fallo@fitnotes.dev', password: ''),
        throwsA(_validationError(password: PasswordValidationError.required)),
      );

      expect(repository.calls, isEmpty);
    });

    test('ambos campos inválidos: informa los dos errores a la vez', () async {
      await expectLater(
        useCase(email: '', password: ''),
        throwsA(
          _validationError(
            email: EmailValidationError.required,
            password: PasswordValidationError.required,
          ),
        ),
      );
      await expectLater(
        useCase(email: 'a@b', password: ''),
        throwsA(
          _validationError(
            email: EmailValidationError.invalidFormat,
            password: PasswordValidationError.required,
          ),
        ),
      );

      expect(repository.calls, isEmpty);
    });
  });

  group('delegación en el repositorio', () {
    test('con datos válidos llama una vez con el correo normalizado', () async {
      final user = await useCase(
        email: '  DEMO@FitNotes.dev ',
        password: 'Demo1234',
      );

      expect(user, _RecordingAuthRepository.demoUser);
      expect(repository.calls, hasLength(1));
      expect(repository.calls.single.email, Email.parse('demo@fitnotes.dev'));
      expect(repository.calls.single.email.value, 'demo@fitnotes.dev');
      expect(repository.calls.single.password, 'Demo1234');
    });

    test(
      'la contraseña de solo espacios no es vacía y no se recorta',
      () async {
        await useCase(email: 'demo@fitnotes.dev', password: '   ');

        expect(repository.calls.single.password, '   ');
      },
    );

    test('la contraseña conserva los espacios alrededor', () async {
      await useCase(email: 'demo@fitnotes.dev', password: ' Demo1234 ');

      expect(repository.calls.single.password, ' Demo1234 ');
    });

    test('cualquier contraseña de un carácter supera la validación', () async {
      await useCase(email: 'a@b.c', password: 'x');

      expect(repository.calls, hasLength(1));
    });
  });

  group('errores del repositorio', () {
    test('propaga InvalidCredentialsException', () async {
      useCase = LoginUseCase(
        _RecordingAuthRepository(error: const InvalidCredentialsException()),
      );

      await expectLater(
        useCase(email: 'otra@ejemplo.com', password: 'x'),
        throwsA(isA<InvalidCredentialsException>()),
      );
    });

    test('propaga ServiceUnavailableException', () async {
      useCase = LoginUseCase(
        _RecordingAuthRepository(error: const ServiceUnavailableException()),
      );

      await expectLater(
        useCase(email: 'fallo@fitnotes.dev', password: 'x'),
        throwsA(isA<ServiceUnavailableException>()),
      );
    });

    test('propaga un fallo inesperado sin ocultarlo', () async {
      useCase = LoginUseCase(
        _RecordingAuthRepository(error: StateError('inesperado')),
      );

      await expectLater(
        useCase(email: 'demo@fitnotes.dev', password: 'Demo1234'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('LoginValidationException', () {
    test('toString identifica los errores de cada campo', () {
      const exception = LoginValidationException(
        emailError: EmailValidationError.required,
      );

      expect(exception.toString(), contains('required'));
    });
  });
}
