// Verificación independiente de la frontera de datos: el DTO atraviesa una
// serialización JSON real (`jsonEncode`/`jsonDecode`) y las políticas ante
// datos mal formados se mantienen. Complementa a `user_dto_test.dart`, que
// trabaja con mapas en memoria.
import 'dart:convert';

import 'package:fit_notes/features/auth/data/mock_auth_repository.dart';
import 'package:fit_notes/features/auth/data/user_dto.dart';
import 'package:fit_notes/features/auth/domain/email.dart';
import 'package:fit_notes/features/auth/domain/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> decode(String text) {
    return jsonDecode(text) as Map<String, dynamic>;
  }

  group('ida y vuelta por texto JSON', () {
    test('entidad -> DTO -> texto JSON -> DTO -> entidad conserva id, nombre y '
        'correo, incluso con Unicode y espacios internos', () {
      final user = User(
        id: 'user-ñandú-001',
        name: '  José   Peña 💪 ',
        email: Email.parse('José@Ejemplo.ES'),
      );

      final text = jsonEncode(UserDTO.fromEntity(user).toJson());
      final restored = UserDTO.fromJson(decode(text)).toEntity();

      expect(restored, user);
      expect(restored.id, user.id);
      expect(restored.name, user.name, reason: 'el nombre no se recorta');
      expect(restored.email, user.email);
    });

    test('el JSON producido contiene exactamente las claves id, name y email '
        'como texto', () {
      final json = decode(
        jsonEncode(
          UserDTO.fromEntity(
            User(id: 'u1', name: 'Ana', email: Email.parse('ana@ejemplo.com')),
          ).toJson(),
        ),
      );

      expect(json.keys.toSet(), {'id', 'name', 'email'});
      expect(json.values.every((value) => value is String), isTrue);
    });

    test('DTO -> JSON -> DTO conserva el correo tal cual (el DTO no normaliza) '
        'y la entidad sí lo normaliza', () {
      const raw = 'Demo@FitNotes.DEV';
      final dto = UserDTO.fromJson(
        decode(jsonEncode({'id': 'u1', 'name': 'Ana', 'email': raw})),
      );

      expect(dto.email, raw);
      expect(dto.toJson()['email'], raw);
      expect(dto.toEntity().email.value, 'demo@fitnotes.dev');
    });

    test('las claves desconocidas se ignoran y no aparecen al volver a '
        'serializar', () {
      final dto = UserDTO.fromJson(
        decode(
          '{"id":"u1","name":"Ana","email":"ana@ejemplo.com","rol":"admin"}',
        ),
      );

      expect(dto.toJson(), {
        'id': 'u1',
        'name': 'Ana',
        'email': 'ana@ejemplo.com',
      });
    });
  });

  group('datos mal formados desde texto JSON', () {
    test(
      'un valor null o numérico en cualquier clave lanza FormatException',
      () {
        for (final key in ['id', 'name', 'email']) {
          for (final bad in [null, 7, true, <String>[]]) {
            final json = {
              'id': 'u1',
              'name': 'Ana',
              'email': 'ana@ejemplo.com',
              key: bad,
            };

            expect(
              () => UserDTO.fromJson(decode(jsonEncode(json))),
              throwsFormatException,
              reason: '$key = $bad',
            );
          }
        }
      },
    );

    test('una clave ausente lanza FormatException', () {
      for (final key in ['id', 'name', 'email']) {
        final json = {'id': 'u1', 'name': 'Ana', 'email': 'ana@ejemplo.com'}
          ..remove(key);

        expect(
          () => UserDTO.fromJson(decode(jsonEncode(json))),
          throwsFormatException,
          reason: 'falta $key',
        );
      }
    });

    test('id o nombre en blanco (incluidos tabuladores y saltos de línea) '
        'lanzan FormatException', () {
      for (final blank in ['', ' ', '\t', '\n', ' \t\n ']) {
        for (final key in ['id', 'name']) {
          final json = {
            'id': 'u1',
            'name': 'Ana',
            'email': 'ana@ejemplo.com',
            key: blank,
          };

          expect(
            () => UserDTO.fromJson(decode(jsonEncode(json))),
            throwsFormatException,
            reason: '$key = ${jsonEncode(blank)}',
          );
        }
      }
    });

    test('un correo en blanco o inválido pasa fromJson pero toEntity propaga '
        'InvalidEmailException con su motivo', () {
      final blank = UserDTO.fromJson({'id': 'u1', 'name': 'Ana', 'email': ' '});
      final invalid = UserDTO.fromJson({
        'id': 'u1',
        'name': 'Ana',
        'email': 'sin-arroba',
      });

      expect(
        blank.toEntity,
        throwsA(
          isA<InvalidEmailException>().having(
            (e) => e.error,
            'error',
            EmailValidationError.required,
          ),
        ),
      );
      expect(
        invalid.toEntity,
        throwsA(
          isA<InvalidEmailException>().having(
            (e) => e.error,
            'error',
            EmailValidationError.invalidFormat,
          ),
        ),
      );
    });
  });

  group('frontera con el repositorio simulado', () {
    test('el usuario del escenario de éxito sobrevive a una ida y vuelta por '
        'texto JSON', () async {
      final user = await const MockAuthRepository().login(
        email: Email.parse('demo@fitnotes.dev'),
        password: 'Demo1234',
      );

      final text = jsonEncode(UserDTO.fromEntity(user).toJson());

      expect(UserDTO.fromJson(decode(text)).toEntity(), user);
      expect(decode(text), {
        'id': 'user-demo-001',
        'name': 'Demo FitNotes',
        'email': 'demo@fitnotes.dev',
      });
    });
  });
}
