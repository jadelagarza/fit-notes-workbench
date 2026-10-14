// Verificación independiente del contrato: recorre la tabla "Ejemplos de
// referencia" de `docs/quality-contracts/login.md` con el caso de uso real y el
// repositorio simulado real (sin dobles de comportamiento), y comprueba las
// invariantes de `Email` y del usuario identificado.
//
// Aporta lo que las pruebas unitarias separadas no pueden: que la composición
// `LoginUseCase` + `MockAuthRepository` produce, para cada fila del contrato, el
// resultado exacto y que se repite siempre igual (LOGIN-24).
import 'package:fit_notes/features/auth/data/mock_auth_repository.dart';
import 'package:fit_notes/features/auth/domain/auth_exceptions.dart';
import 'package:fit_notes/features/auth/domain/auth_repository.dart';
import 'package:fit_notes/features/auth/domain/email.dart';
import 'package:fit_notes/features/auth/domain/login_use_case.dart';
import 'package:fit_notes/features/auth/domain/user.dart';
import 'package:flutter_test/flutter_test.dart';

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

sealed class _Expected {
  const _Expected();
}

class _Success extends _Expected {
  const _Success();
}

class _InvalidCredentials extends _Expected {
  const _InvalidCredentials();
}

class _ServiceFailure extends _Expected {
  const _ServiceFailure();
}

class _Validation extends _Expected {
  const _Validation({this.email, this.password});

  final EmailValidationError? email;
  final PasswordValidationError? password;
}

typedef _Row = (String email, String password, _Expected expected, String ids);

const _formatError = _Validation(email: EmailValidationError.invalidFormat);
const _emailRequired = _Validation(email: EmailValidationError.required);
const _passwordRequired = _Validation(
  password: PasswordValidationError.required,
);

const List<_Row> _referenceRows = [
  ('', 'Demo1234', _emailRequired, 'LOGIN-01, 14, 19'),
  ('   ', 'Demo1234', _emailRequired, 'LOGIN-13, 14'),
  ('\t \n', 'Demo1234', _emailRequired, 'LOGIN-14'),
  ('demo@fitnotes.dev', '', _passwordRequired, 'LOGIN-03, 19'),
  (
    '',
    '',
    _Validation(
      email: EmailValidationError.required,
      password: PasswordValidationError.required,
    ),
    'LOGIN-20',
  ),
  ('demofitnotes.dev', 'x', _formatError, 'LOGIN-02, 15, 32'),
  ('a@@b.com', 'x', _formatError, 'LOGIN-15'),
  ('a@b@c.com', 'x', _formatError, 'LOGIN-15'),
  ('@b.com', 'x', _formatError, 'LOGIN-15'),
  ('a@b', 'x', _formatError, 'LOGIN-15'),
  ('a@b..c', 'x', _formatError, 'LOGIN-15'),
  ('a@.com', 'x', _formatError, 'LOGIN-15'),
  ('a@b.', 'x', _formatError, 'LOGIN-15'),
  ('de mo@fitnotes.dev', 'x', _formatError, 'LOGIN-15'),
  ('de\tmo@fitnotes.dev', 'x', _formatError, 'LOGIN-15'),
  ('de\nmo@fitnotes.dev', 'x', _formatError, 'LOGIN-15'),
  ('de\rmo@fitnotes.dev', 'x', _formatError, 'LOGIN-15'),
  ('a@b.c', 'x', _InvalidCredentials(), 'LOGIN-15, 23'),
  ('demo@fitnotes.dev', 'Demo1234', _Success(), 'LOGIN-21'),
  ('  demo@fitnotes.dev  ', 'Demo1234', _Success(), 'LOGIN-13, 21'),
  ('\tdemo@fitnotes.dev\n', 'Demo1234', _Success(), 'LOGIN-13, 21'),
  ('DEMO@FitNotes.dev', 'Demo1234', _Success(), 'LOGIN-16, 21'),
  ('demo@fitnotes.dev', 'demo1234', _InvalidCredentials(), 'LOGIN-23'),
  ('demo@fitnotes.dev', 'DEMO1234', _InvalidCredentials(), 'LOGIN-23'),
  ('demo@fitnotes.dev', ' Demo1234', _InvalidCredentials(), 'LOGIN-17, 23'),
  ('demo@fitnotes.dev', 'Demo1234 ', _InvalidCredentials(), 'LOGIN-17, 23'),
  ('demo@fitnotes.dev', 'Demo1234\n', _InvalidCredentials(), 'LOGIN-17, 23'),
  ('demo@fitnotes.dev', '   ', _InvalidCredentials(), 'LOGIN-17, 23'),
  ('demo@fitnotes.dev', 'x', _InvalidCredentials(), 'LOGIN-18, 23'),
  ('otro@fitnotes.dev', 'Demo1234', _InvalidCredentials(), 'LOGIN-23'),
  ('demo@fitnotes.com', 'Demo1234', _InvalidCredentials(), 'LOGIN-23'),
  ('otra@ejemplo.com', 'x', _InvalidCredentials(), 'LOGIN-23'),
  ('fallo@fitnotes.dev', 'x', _ServiceFailure(), 'LOGIN-22'),
  ('fallo@fitnotes.dev', 'Demo1234', _ServiceFailure(), 'LOGIN-22'),
  ('fallo@fitnotes.dev', '   ', _ServiceFailure(), 'LOGIN-17, 22'),
  ('FALLO@fitnotes.dev', 'x', _ServiceFailure(), 'LOGIN-16, 22'),
  ('  fallo@fitnotes.dev ', 'x', _ServiceFailure(), 'LOGIN-13, 22'),
  ('fallo@fitnotes.dev', '', _passwordRequired, 'LOGIN-03, 19'),
];

Future<Object> _outcome(LoginUseCase useCase, String email, String password) {
  return useCase(
    email: email,
    password: password,
  ).then<Object>((user) => user, onError: (Object error) => error);
}

void main() {
  late _CountingRepository repository;
  late LoginUseCase useCase;

  setUp(() {
    repository = _CountingRepository(const MockAuthRepository());
    useCase = LoginUseCase(repository);
  });

  group('tabla de ejemplos de referencia con repositorio simulado real', () {
    for (final (email, password, expected, ids) in _referenceRows) {
      String show(String raw) {
        return raw
            .replaceAll('\t', r'\t')
            .replaceAll('\n', r'\n')
            .replaceAll('\r', r'\r');
      }

      test('[$ids] "${show(email)}" / "${show(password)}"', () async {
        // Se repite para comprobar el determinismo (LOGIN-24).
        for (var attempt = 0; attempt < 3; attempt++) {
          final outcome = await _outcome(useCase, email, password);

          switch (expected) {
            case _Success():
              expect(outcome, isA<User>());
              final user = outcome as User;
              expect(user.id, 'user-demo-001');
              expect(user.name, 'Demo FitNotes');
              expect(user.email.value, 'demo@fitnotes.dev');
              expect(repository.calls, attempt + 1);
            case _InvalidCredentials():
              expect(outcome, isA<InvalidCredentialsException>());
              expect(repository.calls, attempt + 1);
            case _ServiceFailure():
              expect(outcome, isA<ServiceUnavailableException>());
              expect(repository.calls, attempt + 1);
            case _Validation(:final email, :final password):
              expect(outcome, isA<LoginValidationException>());
              final failure = outcome as LoginValidationException;
              expect(failure.emailError, email);
              expect(failure.passwordError, password);
              expect(repository.calls, 0, reason: 'LOGIN-19: sin solicitud');
          }
        }
      });
    }
  });

  group('invariantes del correo y del usuario identificado', () {
    const raws = [
      'demo@fitnotes.dev',
      '  DEMO@FitNotes.dev  ',
      '\tDemo@FITNOTES.dev\n',
      'A@B.C',
      'Ñandú@Ejemplo.ES',
    ];

    test('Email.parse es idempotente, está en minúsculas, recortado y supera '
        'su propia validación', () {
      for (final raw in raws) {
        final email = Email.parse(raw);

        expect(email.value, email.value.toLowerCase(), reason: raw);
        expect(email.value, email.value.trim(), reason: raw);
        expect(Email.validate(email.value), isNull, reason: raw);
        expect(Email.parse(email.value), email, reason: raw);
        expect(Email.parse(email.value).value, email.value, reason: raw);
      }
    });

    test(
      'Email.validate y Email.parse coinciden: parse falla exactamente cuando '
      'validate informa un error',
      () {
        const candidates = [
          '',
          ' ',
          'a',
          'a@b',
          'a@b.c',
          'a b@c.d',
          '@@',
          '.@.',
          'a@b.c.d',
          'a@b-c.d',
          'a+tag@b.co',
        ];

        for (final raw in candidates) {
          final error = Email.validate(raw);
          if (error == null) {
            expect(() => Email.parse(raw), returnsNormally, reason: raw);
          } else {
            expect(
              () => Email.parse(raw),
              throwsA(
                isA<InvalidEmailException>().having(
                  (e) => e.error,
                  'error',
                  error,
                ),
              ),
              reason: raw,
            );
          }
        }
      },
    );

    test('el usuario devuelto por el escenario de éxito cumple las invariantes '
        'de usuario identificado', () async {
      final user = await useCase(
        email: 'DEMO@FitNotes.dev',
        password: 'Demo1234',
      );

      expect(user.id, isNotEmpty);
      expect(user.name, isNotEmpty);
      expect(Email.validate(user.email.value), isNull);
      expect(user.email.value, user.email.value.toLowerCase());
    });
  });

  group(
    'espacio en blanco interno: misma definición que el recorte (LOGIN-15)',
    () {
      // F-01 (corregido): `trim()` trataba U+0085 (NEL) como espacio en blanco
      // pero el formato lo aceptaba en el interior. Lo que se recorta en los
      // extremos debe ser exactamente lo que se rechaza en el interior.
      const whitespace = <String, String>{
        'espacio': ' ',
        'tabulador': '\t',
        'salto de línea': '\n',
        'tabulación vertical': '\u000b',
        'avance de página': '\u000c',
        'retorno de carro': '\r',
        'NEL U+0085': '\u0085',
        'NBSP U+00A0': ' ',
        'ogham U+1680': ' ',
        'em space U+2003': ' ',
        'separador de línea U+2028': ' ',
        'separador de párrafo U+2029': ' ',
        'NNBSP U+202F': ' ',
        'MMSP U+205F': ' ',
        'ideográfico U+3000': '　',
        'BOM U+FEFF': '﻿',
      };

      for (final MapEntry(key: name, value: char) in whitespace.entries) {
        test('$name: interno en la parte local o el dominio se rechaza por '
            'formato; solo en los extremos se recorta y se acepta', () {
          expect(
            Email.validate('a${char}b@c.com'),
            EmailValidationError.invalidFormat,
            reason: 'parte local',
          );
          expect(
            Email.validate('a@b${char}c.com'),
            EmailValidationError.invalidFormat,
            reason: 'dominio',
          );
          expect(
            Email.validate('${char}a@b.com$char'),
            isNull,
            reason: 'extremos',
          );
          expect(Email.parse('${char}A@B.COM$char').value, 'a@b.com');
          expect(Email.validate(char), EmailValidationError.required);
        });
      }

      test('caracteres que no son espacio en blanco para el recorte no se '
          'rechazan (límite documentado)', () {
        for (final char in ['​', '᠎', '\u001c', '\u001f']) {
          expect(Email.validate('a${char}b@c.com'), isNull, reason: char);
        }
      });
    },
  );
}
