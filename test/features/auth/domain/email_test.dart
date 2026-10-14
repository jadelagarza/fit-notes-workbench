import 'package:fit_notes/features/auth/domain/email.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Email.validate', () {
    test('rechaza el correo vacío como obligatorio', () {
      expect(Email.validate(''), EmailValidationError.required);
    });

    test('rechaza un correo formado solo por espacios como obligatorio', () {
      expect(Email.validate('   '), EmailValidationError.required);
      expect(Email.validate('\t\n \u00A0'), EmailValidationError.required);
    });

    test('acepta los correos válidos de referencia', () {
      for (final raw in [
        'demo@fitnotes.dev',
        'a@b.c',
        'DEMO@FitNotes.dev',
        'otra@ejemplo.com',
        'fallo@fitnotes.dev',
      ]) {
        expect(Email.validate(raw), isNull, reason: raw);
      }
    });

    test('recorta espacios iniciales y finales antes de validar', () {
      expect(Email.validate('  demo@fitnotes.dev  '), isNull);
      expect(Email.validate('\u00A0demo@fitnotes.dev\n'), isNull);
    });

    test('recorta y rechaza con la misma definición de espacio en blanco '
        '(F-01)', () {
      // U+0085 (NEL) es espacio para String.trim(): si se recorta en los
      // extremos, también debe rechazarse en el interior.
      expect(Email.validate('\u0085demo@fitnotes.dev\u0085'), isNull);
      expect(Email.validate('\u0085'), EmailValidationError.required);
      expect(
        Email.validate('a\u0085b@c.com'),
        EmailValidationError.invalidFormat,
      );
      expect(
        Email.validate('a@b\u0085c.com'),
        EmailValidationError.invalidFormat,
      );
    });

    test('rechaza formatos inválidos de la tabla de referencia', () {
      for (final raw in [
        'demofitnotes.dev', // sin arroba
        'a@@b.com', // más de una arroba
        'a@b@c.com', // más de una arroba
        '@b.com', // parte local vacía
        'a@', // dominio vacío
        'a@b', // dominio sin punto
        'a@b..c', // etiqueta vacía en medio
        'a@.com', // etiqueta vacía al inicio
        'a@b.', // etiqueta vacía al final
        'a@.', // solo etiquetas vacías
        'de mo@fitnotes.dev', // espacio interno en la parte local
        'demo@fit notes.dev', // espacio interno en el dominio
        'de\tmo@fitnotes.dev', // tabulador interno
        'de\u00A0mo@fitnotes.dev', // espacio no separable interno
        'a\u0085b@c.com', // NEL (U+0085) interno: es espacio para trim
      ]) {
        expect(
          Email.validate(raw),
          EmailValidationError.invalidFormat,
          reason: raw,
        );
      }
    });
  });

  group('Email.parse', () {
    test('recorta y normaliza a minúsculas', () {
      expect(Email.parse('  DEMO@FitNotes.dev ').value, 'demo@fitnotes.dev');
    });

    test('lanza InvalidEmailException con el motivo para un correo vacío', () {
      expect(
        () => Email.parse('   '),
        throwsA(
          isA<InvalidEmailException>().having(
            (e) => e.error,
            'error',
            EmailValidationError.required,
          ),
        ),
      );
    });

    test('lanza InvalidEmailException con el motivo de formato inválido', () {
      expect(
        () => Email.parse('a@b'),
        throwsA(
          isA<InvalidEmailException>().having(
            (e) => e.error,
            'error',
            EmailValidationError.invalidFormat,
          ),
        ),
      );
    });

    test('es un objeto de valor: igualdad y hashCode por valor', () {
      final first = Email.parse('Demo@fitnotes.dev');
      final second = Email.parse(' demo@FITNOTES.dev');
      final other = Email.parse('otra@ejemplo.com');

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(other));
    });

    test('toString expone el valor normalizado', () {
      expect(Email.parse('Demo@fitnotes.dev').toString(), 'demo@fitnotes.dev');
    });
  });
}
