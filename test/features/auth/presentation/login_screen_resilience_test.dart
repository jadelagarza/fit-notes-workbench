// Verificación independiente de la pantalla de inicio de sesión: ciclo de vida,
// fallos que no son `Exception`, reintentos encadenados, envío por distintos
// medios y secreto de la contraseña.
//
// Complementa a `login_screen_test.dart`: cada caso aporta una falla distinta
// (respuesta tardía tras desmontar, error lanzado fuera de la jerarquía
// `Exception`, estado de guardia tras volver al formulario, etc.).
import 'dart:async';

import 'package:fit_notes/features/auth/data/mock_auth_repository.dart';
import 'package:fit_notes/features/auth/domain/auth_exceptions.dart';
import 'package:fit_notes/features/auth/domain/auth_repository.dart';
import 'package:fit_notes/features/auth/domain/email.dart';
import 'package:fit_notes/features/auth/domain/login_use_case.dart';
import 'package:fit_notes/features/auth/domain/user.dart';
import 'package:fit_notes/features/auth/presentation/login_keys.dart';
import 'package:fit_notes/features/auth/presentation/login_screen.dart';
import 'package:fit_notes/features/auth/presentation/login_texts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repositorio controlado: cada solicitud queda pendiente hasta que la prueba
/// la completa.
class _PendingRepository implements AuthRepository {
  final List<({Email email, String password})> calls = [];
  final List<Completer<User>> _completers = [];

  @override
  Future<User> login({required Email email, required String password}) {
    calls.add((email: email, password: password));
    final completer = Completer<User>();
    _completers.add(completer);

    return completer.future;
  }

  void succeed({int call = 0}) => _completers[call].complete(_demoUser);

  void fail(Object error, {int call = 0}) {
    _completers[call].completeError(error);
  }
}

/// Repositorio que lanza de forma síncrona, sin devolver un `Future` fallido.
class _SynchronouslyThrowingRepository implements AuthRepository {
  _SynchronouslyThrowingRepository(this.error);

  final Object error;
  int calls = 0;

  @override
  Future<User> login({required Email email, required String password}) {
    calls++;
    throw error;
  }
}

/// Cuenta las solicitudes y delega en otro repositorio.
class _CountingRepository implements AuthRepository {
  _CountingRepository(this._delegate);

  final AuthRepository _delegate;
  int calls = 0;

  @override
  Future<User> login({required Email email, required String password}) {
    calls++;

    return _delegate.login(email: email, password: password);
  }
}

final User _demoUser = User(
  id: 'user-demo-001',
  name: 'Demo FitNotes',
  email: Email.parse('demo@fitnotes.dev'),
);

Widget _screen(AuthRepository repository, {Key? key}) {
  return MaterialApp(
    home: LoginScreen(key: key, loginUseCase: LoginUseCase(repository)),
  );
}

Future<void> _enter(
  WidgetTester tester, {
  String email = '',
  String password = '',
}) async {
  await tester.enterText(find.byKey(LoginKeys.emailField), email);
  await tester.enterText(find.byKey(LoginKeys.passwordField), password);
}

Future<void> _tapSubmit(WidgetTester tester) async {
  await tester.tap(find.byKey(LoginKeys.submitButton), warnIfMissed: false);
  await tester.pump();
}

Future<void> _submitFromKeyboard(WidgetTester tester) async {
  await tester.showKeyboard(find.byKey(LoginKeys.passwordField));
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
}

bool _submitEnabled(WidgetTester tester) {
  return tester
          .widget<FilledButton>(find.byKey(LoginKeys.submitButton))
          .onPressed !=
      null;
}

String _fieldText(WidgetTester tester, Key key) {
  return tester.widget<TextField>(find.byKey(key)).controller!.text;
}

/// Todo el texto visible en widgets `Text` (excluye el contenido de los
/// campos de entrada).
List<String> _visibleTexts(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
      .toList();
}

void main() {
  late _PendingRepository repository;

  setUp(() {
    repository = _PendingRepository();
  });

  group(
    'ciclo de vida: la respuesta llega después de desmontar la pantalla',
    () {
      final outcomes = <String, Object?>{
        'éxito': null,
        'credenciales inválidas': const InvalidCredentialsException(),
        'error técnico': const ServiceUnavailableException(),
        'fallo inesperado': StateError('inesperado'),
      };

      for (final MapEntry(key: name, value: error) in outcomes.entries) {
        testWidgets(
          '$name tras desmontar no lanza ni llama a setState (LOGIN-06, '
          '36)',
          (tester) async {
            await tester.pumpWidget(_screen(repository));
            await _enter(
              tester,
              email: 'demo@fitnotes.dev',
              password: 'Demo1234',
            );
            await _tapSubmit(tester);
            expect(find.byKey(LoginKeys.progressIndicator), findsOneWidget);

            await tester.pumpWidget(const SizedBox());
            if (error == null) {
              repository.succeed();
            } else {
              repository.fail(error);
            }
            await tester.pump();
            await tester.pump(const Duration(seconds: 1));

            expect(tester.takeException(), isNull);
            expect(repository.calls, hasLength(1));
          },
        );
      }

      testWidgets(
        'con el repositorio simulado y su retardo real de 800 ms, retirar '
        'la pantalla y dejar vencer el temporizador no lanza (LOGIN-25)',
        (tester) async {
          await tester.pumpWidget(
            _screen(
              const MockAuthRepository(latency: Duration(milliseconds: 800)),
            ),
          );
          await _enter(
            tester,
            email: 'demo@fitnotes.dev',
            password: 'Demo1234',
          );
          await _tapSubmit(tester);

          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(milliseconds: 800));
          await tester.pump();

          expect(tester.takeException(), isNull);
        },
      );

      testWidgets('una respuesta tardía de la pantalla anterior no contamina a '
          'una pantalla nueva', (tester) async {
        await tester.pumpWidget(_screen(repository, key: const ValueKey('a')));
        await _enter(tester, email: 'demo@fitnotes.dev', password: 'Demo1234');
        await _tapSubmit(tester);

        await tester.pumpWidget(_screen(repository, key: const ValueKey('b')));
        repository.succeed();
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byKey(LoginKeys.successView), findsNothing);
        expect(find.byKey(LoginKeys.progressIndicator), findsNothing);
        expect(_fieldText(tester, LoginKeys.emailField), isEmpty);
        expect(_submitEnabled(tester), isTrue);
      });
    },
  );

  group('fallos que no son Exception (LOGIN-36)', () {
    final failures = <String, Object>{
      'una cadena lanzada': 'boom',
      'un entero lanzado': 42,
      'ArgumentError': ArgumentError('mal argumento'),
      'AssertionError': AssertionError('invariante rota'),
      'UnimplementedError': UnimplementedError(),
      'FormatException': const FormatException('datos mal formados'),
      'InvalidEmailException de dominio': const InvalidEmailException(
        EmailValidationError.invalidFormat,
      ),
    };

    for (final MapEntry(key: name, value: error) in failures.entries) {
      testWidgets(
        '$name se muestra como error técnico y la pantalla sale de la '
        'carga',
        (tester) async {
          await tester.pumpWidget(_screen(repository));
          await _enter(tester, email: 'otra@ejemplo.com', password: 'x');
          await _tapSubmit(tester);

          repository.fail(error);
          await tester.pump();

          expect(tester.takeException(), isNull);
          expect(find.text(LoginTexts.serviceUnavailable), findsOneWidget);
          expect(find.text(LoginTexts.invalidCredentials), findsNothing);
          expect(find.byKey(LoginKeys.progressIndicator), findsNothing);
          expect(_submitEnabled(tester), isTrue);
          expect(_fieldText(tester, LoginKeys.emailField), 'otra@ejemplo.com');
          expect(_fieldText(tester, LoginKeys.passwordField), 'x');
        },
      );
    }

    testWidgets('un repositorio que lanza de forma síncrona también termina en '
        'error técnico', (tester) async {
      final throwing = _SynchronouslyThrowingRepository(StateError('síncrono'));
      await tester.pumpWidget(_screen(throwing));
      await _enter(tester, email: 'otra@ejemplo.com', password: 'x');

      await _tapSubmit(tester);

      expect(tester.takeException(), isNull);
      expect(throwing.calls, 1);
      expect(find.text(LoginTexts.serviceUnavailable), findsOneWidget);
      expect(find.byKey(LoginKeys.progressIndicator), findsNothing);
      expect(_submitEnabled(tester), isTrue);
    });

    testWidgets('el texto del fallo y la contraseña no se filtran a la '
        'pantalla', (tester) async {
      await tester.pumpWidget(_screen(repository));
      await _enter(tester, email: 'otra@ejemplo.com', password: 'S3cr3t!');
      await _tapSubmit(tester);
      expect(
        _visibleTexts(tester).any((text) => text.contains('S3cr3t!')),
        isFalse,
        reason: 'en carga',
      );

      repository.fail(StateError('fallo con S3cr3t! dentro'));
      await tester.pump();

      final texts = _visibleTexts(tester);
      expect(
        texts.any((text) => text.contains('S3cr3t!')),
        isFalse,
        reason: 'tras el error',
      );
      expect(texts.any((text) => text.contains('StateError')), isFalse);
      expect(
        tester
            .widget<TextField>(find.byKey(LoginKeys.passwordField))
            .obscureText,
        isTrue,
      );
    });
  });

  group('reintentos encadenados (LOGIN-31, 34)', () {
    testWidgets('credenciales inválidas, luego error técnico, luego éxito: una '
        'solicitud por envío y el mensaje se sustituye cada vez', (
      tester,
    ) async {
      await tester.pumpWidget(_screen(repository));
      await _enter(tester, email: 'otra@ejemplo.com', password: 'x');

      await _tapSubmit(tester);
      repository.fail(const InvalidCredentialsException(), call: 0);
      await tester.pump();
      expect(find.text(LoginTexts.invalidCredentials), findsOneWidget);
      expect(repository.calls, hasLength(1));

      await _tapSubmit(tester);
      expect(find.byKey(LoginKeys.errorMessage), findsNothing);
      expect(find.byKey(LoginKeys.progressIndicator), findsOneWidget);
      expect(_fieldText(tester, LoginKeys.emailField), 'otra@ejemplo.com');
      repository.fail(const ServiceUnavailableException(), call: 1);
      await tester.pump();
      expect(find.text(LoginTexts.serviceUnavailable), findsOneWidget);
      expect(find.text(LoginTexts.invalidCredentials), findsNothing);
      expect(repository.calls, hasLength(2));

      await _enter(tester, email: 'demo@fitnotes.dev', password: 'Demo1234');
      await _tapSubmit(tester);
      repository.succeed(call: 2);
      await tester.pump();

      expect(find.byKey(LoginKeys.successView), findsOneWidget);
      expect(find.byKey(LoginKeys.errorMessage), findsNothing);
      expect(repository.calls, hasLength(3));
      expect(repository.calls.last.email.value, 'demo@fitnotes.dev');
      expect(repository.calls.last.password, 'Demo1234');
    });

    testWidgets('tras un fallo inesperado se puede reintentar y entrar', (
      tester,
    ) async {
      await tester.pumpWidget(_screen(repository));
      await _enter(tester, email: 'demo@fitnotes.dev', password: 'Demo1234');
      await _tapSubmit(tester);
      repository.fail(StateError('inesperado'));
      await tester.pump();
      expect(find.text(LoginTexts.serviceUnavailable), findsOneWidget);

      await _tapSubmit(tester);
      repository.succeed(call: 1);
      await tester.pump();

      expect(find.byKey(LoginKeys.successView), findsOneWidget);
      expect(find.text(LoginTexts.serviceUnavailable), findsNothing);
      expect(repository.calls, hasLength(2));
    });

    testWidgets('un error de validación no deja la pantalla bloqueada: el '
        'siguiente envío válido sí llama al repositorio', (tester) async {
      await tester.pumpWidget(_screen(repository));
      await _tapSubmit(tester);
      await _tapSubmit(tester);
      expect(repository.calls, isEmpty);

      await _enter(tester, email: 'demo@fitnotes.dev', password: 'Demo1234');
      await _tapSubmit(tester);

      expect(repository.calls, hasLength(1));
    });

    testWidgets(
      'volver al formulario reinicia también la guardia: enviar vacío '
      'valida sin llamar, y un nuevo inicio de sesión funciona (LOGIN-29)',
      (tester) async {
        await tester.pumpWidget(_screen(repository));
        await _enter(tester, email: 'demo@fitnotes.dev', password: 'Demo1234');
        await _tapSubmit(tester);
        repository.succeed();
        await tester.pump();
        await tester.tap(find.byKey(LoginKeys.backButton));
        await tester.pump();

        await _tapSubmit(tester);

        expect(find.text(LoginTexts.emailRequired), findsOneWidget);
        expect(find.text(LoginTexts.passwordRequired), findsOneWidget);
        expect(repository.calls, hasLength(1));

        await _enter(tester, email: 'demo@fitnotes.dev', password: 'Demo1234');
        await _tapSubmit(tester);
        expect(repository.calls, hasLength(2));
        repository.succeed(call: 1);
        await tester.pump();

        expect(find.byKey(LoginKeys.successView), findsOneWidget);
        expect(find.text(LoginTexts.emailRequired), findsNothing);
      },
    );
  });

  group('un solo envío en curso, cualquiera que sea el medio (LOGIN-27)', () {
    Future<void> fillValid(WidgetTester tester) async {
      await tester.pumpWidget(_screen(repository));
      await _enter(tester, email: 'demo@fitnotes.dev', password: 'Demo1234');
    }

    testWidgets('botón y después teclado generan una sola solicitud', (
      tester,
    ) async {
      await fillValid(tester);

      await _tapSubmit(tester);
      await _submitFromKeyboard(tester);

      expect(repository.calls, hasLength(1));
    });

    testWidgets('teclado y después botón generan una sola solicitud', (
      tester,
    ) async {
      await fillValid(tester);

      await _submitFromKeyboard(tester);
      await _tapSubmit(tester);

      expect(repository.calls, hasLength(1));
    });

    testWidgets('varios toques seguidos en el mismo fotograma generan una sola '
        'solicitud', (tester) async {
      await fillValid(tester);

      final button = find.byKey(LoginKeys.submitButton);
      await tester.tap(button, warnIfMissed: false);
      await tester.tap(button, warnIfMissed: false);
      await tester.tap(button, warnIfMissed: false);
      await tester.pump();

      expect(repository.calls, hasLength(1));
    });

    testWidgets(
      'doble toque con el repositorio simulado y su retardo real: una '
      'solicitud y termina en éxito',
      (tester) async {
        final counting = _CountingRepository(
          const MockAuthRepository(latency: Duration(milliseconds: 800)),
        );
        await tester.pumpWidget(_screen(counting));
        await _enter(tester, email: 'demo@fitnotes.dev', password: 'Demo1234');

        await _tapSubmit(tester);
        await _tapSubmit(tester);
        await tester.pump(const Duration(milliseconds: 800));
        await tester.pump();

        expect(counting.calls, 1);
        expect(find.byKey(LoginKeys.successView), findsOneWidget);
      },
    );

    testWidgets('durante la carga, un envío por teclado con datos que serían '
        'inválidos no valida ni inicia otra solicitud', (tester) async {
      await fillValid(tester);
      await _tapSubmit(tester);

      await tester.enterText(find.byKey(LoginKeys.emailField), 'roto');
      await _submitFromKeyboard(tester);

      expect(repository.calls, hasLength(1));
      expect(find.text(LoginTexts.emailInvalidFormat), findsNothing);
      expect(find.byKey(LoginKeys.progressIndicator), findsOneWidget);
    });
  });

  group('validación con espacios en blanco internos (LOGIN-15)', () {
    testWidgets('un tabulador interno en el correo da error de formato y no '
        'hace solicitud', (tester) async {
      await tester.pumpWidget(_screen(repository));
      await _enter(tester, email: 'de\tmo@fitnotes.dev', password: 'x');

      await _tapSubmit(tester);

      expect(find.text(LoginTexts.emailInvalidFormat), findsOneWidget);
      expect(find.text(LoginTexts.emailRequired), findsNothing);
      expect(repository.calls, isEmpty);
    });

    testWidgets('un salto de línea en el correo nunca llega al repositorio '
        'dentro del correo', (tester) async {
      await tester.pumpWidget(_screen(repository));
      await _enter(tester, email: 'de\nmo@fitnotes.dev', password: 'x');

      await _tapSubmit(tester);

      // El campo de una línea puede filtrar el salto de línea antes de que la
      // pantalla lo vea; en cualquier caso, ningún correo con espacios en
      // blanco debe alcanzar el repositorio.
      for (final call in repository.calls) {
        expect(call.email.value, isNot(matches(RegExp(r'\s'))));
      }
      if (repository.calls.isEmpty) {
        expect(find.text(LoginTexts.emailInvalidFormat), findsOneWidget);
      }
    });

    testWidgets('espacios, tabuladores y saltos de línea solo alrededor se '
        'recortan y el correo se acepta (LOGIN-13)', (tester) async {
      await tester.pumpWidget(_screen(repository));
      await _enter(
        tester,
        email: ' \t DEMO@FitNotes.dev \t ',
        password: 'Demo1234',
      );

      await _tapSubmit(tester);

      expect(repository.calls.single.email.value, 'demo@fitnotes.dev');
      expect(find.text(LoginTexts.emailInvalidFormat), findsNothing);
    });
  });

  group('envío desde el teclado con datos inválidos (LOGIN-19, 20)', () {
    testWidgets('muestra ambos errores y no hace solicitud', (tester) async {
      await tester.pumpWidget(_screen(repository));

      await _submitFromKeyboard(tester);

      expect(find.text(LoginTexts.emailRequired), findsOneWidget);
      expect(find.text(LoginTexts.passwordRequired), findsOneWidget);
      expect(find.byKey(LoginKeys.progressIndicator), findsNothing);
      expect(repository.calls, isEmpty);
    });
  });
}
