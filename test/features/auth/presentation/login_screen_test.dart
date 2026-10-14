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

/// Doble de repositorio: cuenta llamadas y deja que cada prueba decida cuándo
/// y cómo termina cada solicitud.
class _ControlledAuthRepository implements AuthRepository {
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

final User _demoUser = User(
  id: 'user-demo-001',
  name: 'Demo FitNotes',
  email: Email.parse('demo@fitnotes.dev'),
);

Future<void> _pumpScreen(WidgetTester tester, AuthRepository repository) {
  return tester.pumpWidget(
    MaterialApp(home: LoginScreen(loginUseCase: LoginUseCase(repository))),
  );
}

Future<void> _enterCredentials(
  WidgetTester tester, {
  String email = '',
  String password = '',
}) async {
  await tester.enterText(find.byKey(LoginKeys.emailField), email);
  await tester.enterText(find.byKey(LoginKeys.passwordField), password);
}

Future<void> _tapSubmit(WidgetTester tester) async {
  await tester.tap(find.byKey(LoginKeys.submitButton));
  await tester.pump();
}

String _textOf(WidgetTester tester, Key key) {
  return tester.widget<TextField>(find.byKey(key)).controller!.text;
}

bool _isSubmitEnabled(WidgetTester tester) {
  return tester
          .widget<FilledButton>(find.byKey(LoginKeys.submitButton))
          .onPressed !=
      null;
}

void _expectInitialForm(WidgetTester tester) {
  expect(find.byKey(LoginKeys.emailField), findsOneWidget);
  expect(find.byKey(LoginKeys.passwordField), findsOneWidget);
  expect(_textOf(tester, LoginKeys.emailField), isEmpty);
  expect(_textOf(tester, LoginKeys.passwordField), isEmpty);
  expect(find.byKey(LoginKeys.progressIndicator), findsNothing);
  expect(find.byKey(LoginKeys.errorMessage), findsNothing);
  expect(find.byKey(LoginKeys.successView), findsNothing);
  expect(find.text(LoginTexts.emailRequired), findsNothing);
  expect(find.text(LoginTexts.emailInvalidFormat), findsNothing);
  expect(find.text(LoginTexts.passwordRequired), findsNothing);
  expect(_isSubmitEnabled(tester), isTrue);
}

void main() {
  late _ControlledAuthRepository repository;

  setUp(() {
    repository = _ControlledAuthRepository();
  });

  group('estado inicial', () {
    testWidgets('muestra el formulario vacío, sin mensajes y con envío '
        'disponible (LOGIN-33)', (tester) async {
      await _pumpScreen(tester, repository);

      _expectInitialForm(tester);
    });

    testWidgets('oculta los caracteres de la contraseña (LOGIN-35)', (
      tester,
    ) async {
      await _pumpScreen(tester, repository);

      final password = tester.widget<TextField>(
        find.byKey(LoginKeys.passwordField),
      );
      final email = tester.widget<TextField>(find.byKey(LoginKeys.emailField));

      expect(password.obscureText, isTrue);
      expect(email.obscureText, isFalse);
    });
  });

  group('validación al enviar', () {
    testWidgets('con los dos campos vacíos muestra ambos errores a la vez y no '
        'hace solicitud (LOGIN-01, 03, 14, 19, 20)', (tester) async {
      await _pumpScreen(tester, repository);

      await _tapSubmit(tester);

      expect(find.text(LoginTexts.emailRequired), findsOneWidget);
      expect(find.text(LoginTexts.passwordRequired), findsOneWidget);
      expect(repository.calls, isEmpty);
      expect(find.byKey(LoginKeys.progressIndicator), findsNothing);
      expect(_isSubmitEnabled(tester), isTrue);
    });

    testWidgets('los errores aparecen junto a su campo', (tester) async {
      await _pumpScreen(tester, repository);

      await _tapSubmit(tester);

      expect(
        find.descendant(
          of: find.byKey(LoginKeys.emailField),
          matching: find.text(LoginTexts.emailRequired),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(LoginKeys.passwordField),
          matching: find.text(LoginTexts.passwordRequired),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'correo vacío con contraseña: solo error de correo (LOGIN-01)',
      (tester) async {
        await _pumpScreen(tester, repository);
        await _enterCredentials(tester, password: 'Demo1234');

        await _tapSubmit(tester);

        expect(find.text(LoginTexts.emailRequired), findsOneWidget);
        expect(find.text(LoginTexts.passwordRequired), findsNothing);
        expect(repository.calls, isEmpty);
      },
    );

    testWidgets('correo de solo espacios es obligatorio (LOGIN-14)', (
      tester,
    ) async {
      await _pumpScreen(tester, repository);
      await _enterCredentials(tester, email: '   ', password: 'Demo1234');

      await _tapSubmit(tester);

      expect(find.text(LoginTexts.emailRequired), findsOneWidget);
      expect(repository.calls, isEmpty);
    });

    testWidgets('contraseña vacía con correo válido: solo error de contraseña '
        '(LOGIN-03)', (tester) async {
      await _pumpScreen(tester, repository);
      await _enterCredentials(tester, email: 'demo@fitnotes.dev');

      await _tapSubmit(tester);

      expect(find.text(LoginTexts.passwordRequired), findsOneWidget);
      expect(find.text(LoginTexts.emailRequired), findsNothing);
      expect(find.text(LoginTexts.emailInvalidFormat), findsNothing);
      expect(repository.calls, isEmpty);
    });

    testWidgets('formatos inválidos muestran el error de formato, distinto del '
        'obligatorio (LOGIN-02, 15, 32)', (tester) async {
      await _pumpScreen(tester, repository);

      for (final email in [
        'demofitnotes.dev',
        'a@b',
        'a@@b.com',
        'a@b@c.com',
        '@b.com',
        'a@b..c',
        'a@.com',
        'a@b.',
        'de mo@fitnotes.dev',
      ]) {
        await _enterCredentials(tester, email: email, password: 'x');
        await _tapSubmit(tester);

        expect(
          find.text(LoginTexts.emailInvalidFormat),
          findsOneWidget,
          reason: email,
        );
        expect(find.text(LoginTexts.emailRequired), findsNothing);
      }

      expect(repository.calls, isEmpty);
    });
  });

  group('carga', () {
    testWidgets('con datos válidos muestra el indicador y deshabilita el envío '
        '(LOGIN-07, 26)', (tester) async {
      await _pumpScreen(tester, repository);
      await _enterCredentials(
        tester,
        email: 'demo@fitnotes.dev',
        password: 'Demo1234',
      );

      await _tapSubmit(tester);

      expect(find.byKey(LoginKeys.progressIndicator), findsOneWidget);
      expect(_isSubmitEnabled(tester), isFalse);
      expect(repository.calls, hasLength(1));
    });

    testWidgets('envía el correo normalizado y la contraseña tal cual '
        '(LOGIN-13, 16, 17)', (tester) async {
      await _pumpScreen(tester, repository);
      await _enterCredentials(
        tester,
        email: '  DEMO@FitNotes.dev ',
        password: ' Demo1234 ',
      );

      await _tapSubmit(tester);

      expect(repository.calls.single.email.value, 'demo@fitnotes.dev');
      expect(repository.calls.single.password, ' Demo1234 ');
    });

    testWidgets('una contraseña de solo espacios no es vacía (LOGIN-17)', (
      tester,
    ) async {
      await _pumpScreen(tester, repository);
      await _enterCredentials(
        tester,
        email: 'demo@fitnotes.dev',
        password: '   ',
      );

      await _tapSubmit(tester);

      expect(find.text(LoginTexts.passwordRequired), findsNothing);
      expect(repository.calls, hasLength(1));
    });

    testWidgets('pulsar de nuevo durante la carga no genera otra solicitud '
        '(LOGIN-27)', (tester) async {
      await _pumpScreen(tester, repository);
      await _enterCredentials(
        tester,
        email: 'demo@fitnotes.dev',
        password: 'Demo1234',
      );
      await _tapSubmit(tester);

      await tester.tap(find.byKey(LoginKeys.submitButton), warnIfMissed: false);
      await tester.pump();

      expect(repository.calls, hasLength(1));
    });

    testWidgets('enviar desde el teclado durante la carga tampoco genera otra '
        'solicitud (LOGIN-27)', (tester) async {
      await _pumpScreen(tester, repository);
      await _enterCredentials(
        tester,
        email: 'demo@fitnotes.dev',
        password: 'Demo1234',
      );
      await tester.showKeyboard(find.byKey(LoginKeys.passwordField));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(repository.calls, hasLength(1));

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(repository.calls, hasLength(1));
    });
  });

  group('éxito', () {
    Future<void> pumpUntilSuccess(WidgetTester tester) async {
      await _pumpScreen(tester, repository);
      await _enterCredentials(
        tester,
        email: 'demo@fitnotes.dev',
        password: 'Demo1234',
      );
      await _tapSubmit(tester);
      repository.succeed();
      await tester.pump();
    }

    testWidgets('muestra la bienvenida con nombre y correo y el botón para '
        'volver (LOGIN-08, 28)', (tester) async {
      await pumpUntilSuccess(tester);

      expect(find.byKey(LoginKeys.successView), findsOneWidget);
      expect(find.text(LoginTexts.welcome('Demo FitNotes')), findsOneWidget);
      expect(find.text('demo@fitnotes.dev'), findsOneWidget);
      expect(find.byKey(LoginKeys.backButton), findsOneWidget);
      expect(find.byKey(LoginKeys.progressIndicator), findsNothing);
      expect(find.byKey(LoginKeys.emailField), findsNothing);
      expect(find.text('Demo1234'), findsNothing);
    });

    testWidgets('volver al formulario restablece el estado inicial sin otra '
        'acción (LOGIN-29)', (tester) async {
      await pumpUntilSuccess(tester);

      await tester.tap(find.byKey(LoginKeys.backButton));
      await tester.pump();

      _expectInitialForm(tester);
      expect(repository.calls, hasLength(1));
    });
  });

  group('error', () {
    Future<void> submitAndFailWith(WidgetTester tester, Object error) async {
      await _pumpScreen(tester, repository);
      await _enterCredentials(tester, email: 'otra@ejemplo.com', password: 'x');
      await _tapSubmit(tester);
      repository.fail(error);
      await tester.pump();
    }

    testWidgets('credenciales inválidas muestran su mensaje y el formulario '
        'conserva los valores y sigue editable (LOGIN-09, 31)', (tester) async {
      await submitAndFailWith(tester, const InvalidCredentialsException());

      expect(
        find.descendant(
          of: find.byKey(LoginKeys.errorMessage),
          matching: find.text(LoginTexts.invalidCredentials),
        ),
        findsOneWidget,
      );
      expect(find.byKey(LoginKeys.progressIndicator), findsNothing);
      expect(_textOf(tester, LoginKeys.emailField), 'otra@ejemplo.com');
      expect(_textOf(tester, LoginKeys.passwordField), 'x');
      expect(_isSubmitEnabled(tester), isTrue);
      expect(
        tester.widget<TextField>(find.byKey(LoginKeys.emailField)).enabled,
        isNot(false),
      );
    });

    testWidgets('el error técnico muestra un mensaje distinto del de '
        'credenciales inválidas (LOGIN-09, 30)', (tester) async {
      await submitAndFailWith(tester, const ServiceUnavailableException());

      expect(
        find.descendant(
          of: find.byKey(LoginKeys.errorMessage),
          matching: find.text(LoginTexts.serviceUnavailable),
        ),
        findsOneWidget,
      );
      expect(find.text(LoginTexts.invalidCredentials), findsNothing);
      expect(
        LoginTexts.serviceUnavailable,
        isNot(LoginTexts.invalidCredentials),
      );
    });

    testWidgets('un fallo inesperado se muestra como error técnico y no deja '
        'la pantalla en carga (LOGIN-36)', (tester) async {
      await submitAndFailWith(tester, StateError('inesperado'));

      expect(find.text(LoginTexts.serviceUnavailable), findsOneWidget);
      expect(find.byKey(LoginKeys.progressIndicator), findsNothing);
      expect(_isSubmitEnabled(tester), isTrue);
    });

    testWidgets('un nuevo intento sustituye el mensaje anterior y puede '
        'terminar en éxito (LOGIN-31, 34)', (tester) async {
      await submitAndFailWith(tester, const InvalidCredentialsException());
      await _enterCredentials(
        tester,
        email: 'demo@fitnotes.dev',
        password: 'Demo1234',
      );

      await _tapSubmit(tester);

      expect(find.byKey(LoginKeys.errorMessage), findsNothing);
      expect(find.byKey(LoginKeys.progressIndicator), findsOneWidget);

      repository.succeed(call: 1);
      await tester.pump();

      expect(find.byKey(LoginKeys.successView), findsOneWidget);
      expect(find.byKey(LoginKeys.errorMessage), findsNothing);
      expect(repository.calls, hasLength(2));
    });

    testWidgets('un nuevo intento limpia los errores de validación previos '
        '(LOGIN-34)', (tester) async {
      await _pumpScreen(tester, repository);
      await _tapSubmit(tester);
      expect(find.text(LoginTexts.emailRequired), findsOneWidget);

      await _enterCredentials(
        tester,
        email: 'demo@fitnotes.dev',
        password: 'Demo1234',
      );
      await _tapSubmit(tester);

      expect(find.text(LoginTexts.emailRequired), findsNothing);
      expect(find.text(LoginTexts.passwordRequired), findsNothing);
      expect(find.byKey(LoginKeys.progressIndicator), findsOneWidget);
    });

    testWidgets('un fallo tras el error de validación sustituye los mensajes '
        '(LOGIN-34)', (tester) async {
      await _pumpScreen(tester, repository);
      await _tapSubmit(tester);
      await _enterCredentials(tester, email: 'otra@ejemplo.com', password: 'x');
      await _tapSubmit(tester);

      repository.fail(const InvalidCredentialsException());
      await tester.pump();

      expect(find.text(LoginTexts.emailRequired), findsNothing);
      expect(find.text(LoginTexts.invalidCredentials), findsOneWidget);
    });
  });

  group('ciclo de vida', () {
    testWidgets('si la pantalla se retira durante la carga, completar la '
        'solicitud no provoca errores', (tester) async {
      await _pumpScreen(tester, repository);
      await _enterCredentials(
        tester,
        email: 'demo@fitnotes.dev',
        password: 'Demo1234',
      );
      await _tapSubmit(tester);

      await tester.pumpWidget(const SizedBox());
      repository.succeed();
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('flujo de extremo a extremo con MockAuthRepository', () {
    Future<void> submit(
      WidgetTester tester, {
      required String email,
      required String password,
    }) async {
      await _enterCredentials(tester, email: email, password: password);
      await tester.tap(find.byKey(LoginKeys.submitButton));
      await tester.pumpAndSettle();
    }

    testWidgets('credenciales de éxito terminan en éxito cada vez, también con '
        'espacios y mayúsculas (LOGIN-04, 08, 13, 16, 21, 24, 28)', (
      tester,
    ) async {
      await _pumpScreen(tester, const MockAuthRepository());

      for (final email in [
        MockAuthRepository.successEmail,
        '  demo@fitnotes.dev  ',
        'DEMO@FitNotes.dev',
      ]) {
        await submit(
          tester,
          email: email,
          password: MockAuthRepository.successPassword,
        );

        expect(
          find.byKey(LoginKeys.successView),
          findsOneWidget,
          reason: email,
        );
        expect(find.text(LoginTexts.welcome('Demo FitNotes')), findsOneWidget);
        expect(find.text('demo@fitnotes.dev'), findsOneWidget);

        await tester.tap(find.byKey(LoginKeys.backButton));
        await tester.pump();
      }
    });

    testWidgets('fallo@fitnotes.dev termina en error técnico con cualquier '
        'contraseña (LOGIN-05, 09, 22)', (tester) async {
      await _pumpScreen(tester, const MockAuthRepository());

      for (final (email, password) in [
        ('fallo@fitnotes.dev', 'x'),
        ('fallo@fitnotes.dev', 'Demo1234'),
        ('FALLO@fitnotes.dev', 'x'),
      ]) {
        await submit(tester, email: email, password: password);

        expect(
          find.text(LoginTexts.serviceUnavailable),
          findsOneWidget,
          reason: email,
        );
      }
    });

    testWidgets('cualquier otra combinación termina en credenciales inválidas '
        '(LOGIN-05, 09, 17, 23)', (tester) async {
      await _pumpScreen(tester, const MockAuthRepository());

      for (final (email, password) in [
        ('otra@ejemplo.com', 'x'),
        ('a@b.c', 'x'),
        ('demo@fitnotes.dev', 'demo1234'),
        ('demo@fitnotes.dev', ' Demo1234'),
        ('demo@fitnotes.dev', '   '),
        ('otro@fitnotes.dev', 'Demo1234'),
      ]) {
        await submit(tester, email: email, password: password);

        expect(
          find.text(LoginTexts.invalidCredentials),
          findsOneWidget,
          reason: '$email / "$password"',
        );
      }
    });

    testWidgets('tras un error se pueden corregir las credenciales y entrar '
        '(LOGIN-31)', (tester) async {
      await _pumpScreen(tester, const MockAuthRepository());
      await submit(tester, email: 'demo@fitnotes.dev', password: 'demo1234');
      expect(find.text(LoginTexts.invalidCredentials), findsOneWidget);
      expect(_textOf(tester, LoginKeys.emailField), 'demo@fitnotes.dev');

      await submit(tester, email: 'demo@fitnotes.dev', password: 'Demo1234');

      expect(find.byKey(LoginKeys.successView), findsOneWidget);
      expect(find.text(LoginTexts.invalidCredentials), findsNothing);
    });
  });
}
