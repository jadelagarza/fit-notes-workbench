import 'package:fit_notes/features/auth/data/mock_auth_repository.dart';
import 'package:fit_notes/features/auth/domain/auth_exceptions.dart';
import 'package:fit_notes/features/auth/domain/email.dart';
import 'package:fit_notes/features/auth/domain/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const repository = MockAuthRepository();

  Future<User> login(String email, String password) {
    return repository.login(email: Email.parse(email), password: password);
  }

  group('credenciales de prueba', () {
    test('se exponen con nombres claros', () {
      expect(MockAuthRepository.successEmail, 'demo@fitnotes.dev');
      expect(MockAuthRepository.successPassword, 'Demo1234');
      expect(MockAuthRepository.serviceFailureEmail, 'fallo@fitnotes.dev');
    });
  });

  group('escenario de éxito', () {
    test('devuelve el usuario Demo FitNotes (LOGIN-04, 06, 21)', () async {
      final user = await login('demo@fitnotes.dev', 'Demo1234');

      expect(user.id, 'user-demo-001');
      expect(user.name, 'Demo FitNotes');
      expect(user.email, Email.parse('demo@fitnotes.dev'));
    });

    test(
      'es reproducible: mismas credenciales, mismo usuario (LOGIN-24)',
      () async {
        for (var attempt = 0; attempt < 3; attempt++) {
          await expectLater(
            login('demo@fitnotes.dev', 'Demo1234'),
            completion(
              isA<User>()
                  .having((user) => user.id, 'id', 'user-demo-001')
                  .having((user) => user.name, 'name', 'Demo FitNotes'),
            ),
          );
        }
      },
    );

    test(
      'acepta el correo con mayúsculas y espacios una vez normalizado',
      () async {
        await expectLater(
          login('  DEMO@FitNotes.dev ', 'Demo1234'),
          completion(isA<User>()),
        );
      },
    );
  });

  group('escenario de error técnico', () {
    test(
      'fallo@fitnotes.dev falla con cualquier contraseña (LOGIN-22)',
      () async {
        for (final password in ['x', 'Demo1234', ' ']) {
          await expectLater(
            login('fallo@fitnotes.dev', password),
            throwsA(isA<ServiceUnavailableException>()),
            reason: 'contraseña "$password"',
          );
        }
      },
    );

    test('FALLO@fitnotes.dev también falla (normalización)', () async {
      await expectLater(
        login('FALLO@fitnotes.dev', 'x'),
        throwsA(isA<ServiceUnavailableException>()),
      );
    });

    test('es reproducible (LOGIN-05, 24)', () async {
      for (var attempt = 0; attempt < 3; attempt++) {
        await expectLater(
          login('fallo@fitnotes.dev', 'x'),
          throwsA(isA<ServiceUnavailableException>()),
        );
      }
    });
  });

  group('escenario de credenciales inválidas', () {
    test('cualquier otra combinación es inválida (LOGIN-23)', () async {
      const combinations = [
        ('otra@ejemplo.com', 'x'),
        ('a@b.c', 'x'),
        ('otro@fitnotes.dev', 'Demo1234'),
        ('demo@fitnotes.dev', 'demo1234'),
        ('demo@fitnotes.dev', ' Demo1234'),
        ('demo@fitnotes.dev', 'Demo1234 '),
        ('demo@fitnotes.dev', '   '),
      ];

      for (final (email, password) in combinations) {
        await expectLater(
          login(email, password),
          throwsA(isA<InvalidCredentialsException>()),
          reason: '$email / "$password"',
        );
      }
    });

    test('es reproducible (LOGIN-05, 24)', () async {
      for (var attempt = 0; attempt < 3; attempt++) {
        await expectLater(
          login('otra@ejemplo.com', 'x'),
          throwsA(isA<InvalidCredentialsException>()),
        );
      }
    });
  });

  group('latencia configurable', () {
    const latency = Duration(milliseconds: 800);

    Future<void> expectCompletesAfterLatency(
      WidgetTester tester,
      String email,
      String password,
    ) async {
      final slowRepository = MockAuthRepository(latency: latency);
      var isDone = false;

      slowRepository
          .login(email: Email.parse(email), password: password)
          .then((_) => isDone = true, onError: (_) => isDone = true);

      await tester.pump(latency - const Duration(milliseconds: 1));
      expect(isDone, isFalse, reason: 'no debe responder antes de la latencia');

      await tester.pump(const Duration(milliseconds: 1));
      expect(isDone, isTrue, reason: 'debe responder al cumplirse la latencia');
    }

    testWidgets('el éxito espera la latencia', (tester) async {
      await expectCompletesAfterLatency(
        tester,
        'demo@fitnotes.dev',
        'Demo1234',
      );
    });

    testWidgets('el error técnico espera la latencia', (tester) async {
      await expectCompletesAfterLatency(tester, 'fallo@fitnotes.dev', 'x');
    });

    testWidgets('las credenciales inválidas esperan la latencia', (
      tester,
    ) async {
      await expectCompletesAfterLatency(tester, 'otra@ejemplo.com', 'x');
    });

    test('por defecto no hay latencia', () {
      expect(const MockAuthRepository().latency, Duration.zero);
    });
  });
}
