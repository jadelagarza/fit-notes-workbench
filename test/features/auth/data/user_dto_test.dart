import 'package:fit_notes/features/auth/data/user_dto.dart';
import 'package:fit_notes/features/auth/domain/email.dart';
import 'package:fit_notes/features/auth/domain/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validJson = <String, dynamic>{
    'id': 'user-demo-001',
    'name': 'Demo FitNotes',
    'email': 'demo@fitnotes.dev',
  };

  group('UserDTO.fromJson', () {
    test('lee id, nombre y correo del JSON', () {
      final dto = UserDTO.fromJson(validJson);

      expect(dto.id, 'user-demo-001');
      expect(dto.name, 'Demo FitNotes');
      expect(dto.email, 'demo@fitnotes.dev');
    });

    test('lanza FormatException si falta una clave', () {
      for (final key in validJson.keys) {
        final json = {...validJson}..remove(key);

        expect(
          () => UserDTO.fromJson(json),
          throwsFormatException,
          reason: 'sin $key',
        );
      }
    });

    test('lanza FormatException si un valor no es texto', () {
      for (final key in validJson.keys) {
        final json = {...validJson, key: 42};

        expect(
          () => UserDTO.fromJson(json),
          throwsFormatException,
          reason: '$key numérico',
        );
      }
    });

    test('lanza FormatException si el id o el nombre están en blanco', () {
      expect(
        () => UserDTO.fromJson({...validJson, 'id': '  '}),
        throwsFormatException,
      );
      expect(
        () => UserDTO.fromJson({...validJson, 'name': ''}),
        throwsFormatException,
      );
    });
  });

  group('UserDTO.toJson', () {
    test('serializa los tres campos primitivos', () {
      const dto = UserDTO(
        id: 'user-demo-001',
        name: 'Demo FitNotes',
        email: 'demo@fitnotes.dev',
      );

      expect(dto.toJson(), validJson);
    });

    test('es el inverso de fromJson', () {
      expect(UserDTO.fromJson(validJson).toJson(), validJson);
    });
  });

  group('UserDTO.toEntity', () {
    test('convierte a User con el correo como Email normalizado', () {
      final user = UserDTO.fromJson({
        ...validJson,
        'email': 'DEMO@FitNotes.dev',
      }).toEntity();

      expect(user.id, 'user-demo-001');
      expect(user.name, 'Demo FitNotes');
      expect(user.email, Email.parse('demo@fitnotes.dev'));
      expect(user.email.value, 'demo@fitnotes.dev');
    });

    test('propaga InvalidEmailException si el correo del DTO es inválido', () {
      final dto = UserDTO.fromJson({...validJson, 'email': 'sin-arroba'});

      expect(dto.toEntity, throwsA(isA<InvalidEmailException>()));
    });
  });

  group('UserDTO.fromEntity', () {
    test('copia id, nombre y valor del correo de la entidad', () {
      final user = User(
        id: 'user-demo-001',
        name: 'Demo FitNotes',
        email: Email.parse('demo@fitnotes.dev'),
      );

      final dto = UserDTO.fromEntity(user);

      expect(dto.toJson(), validJson);
    });

    test('ida y vuelta entidad -> DTO -> entidad conserva el usuario', () {
      final user = User(
        id: 'user-demo-001',
        name: 'Demo FitNotes',
        email: Email.parse('demo@fitnotes.dev'),
      );

      final roundTrip = UserDTO.fromEntity(user).toEntity();

      expect(roundTrip, user);
      expect(roundTrip.name, user.name);
      expect(roundTrip.email, user.email);
    });
  });
}
