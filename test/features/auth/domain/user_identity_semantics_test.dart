// Verificación independiente de la identidad de la entidad `User`: la igualdad
// por id debe cumplir el contrato de `==`/`hashCode` en colecciones.
import 'package:fit_notes/features/auth/domain/email.dart';
import 'package:fit_notes/features/auth/domain/user.dart';
import 'package:flutter_test/flutter_test.dart';

User _user(String id, {String name = 'Demo', String email = 'demo@x.com'}) {
  return User(id: id, name: name, email: Email.parse(email));
}

void main() {
  group('identidad de User por id', () {
    test('igualdad reflexiva, simétrica y transitiva con datos distintos', () {
      final a = _user('1', name: 'A', email: 'a@x.com');
      final b = _user('1', name: 'B', email: 'b@x.com');
      final c = _user('1', name: 'C', email: 'c@x.com');

      expect(a, a);
      expect(a == b, isTrue);
      expect(b == a, isTrue);
      expect(b == c, isTrue);
      expect(a == c, isTrue);
    });

    test('el id distingue mayúsculas y no se recorta', () {
      expect(_user('Abc'), isNot(_user('abc')));
      expect(_user('abc'), isNot(_user('abc ')));
    });

    test('mismos datos con otro id son usuarios distintos', () {
      expect(_user('1'), isNot(_user('2')));
    });

    test('no es igual a un valor de otro tipo, aunque coincida su id', () {
      final user = _user('user-demo-001');

      expect(user, isNot(equals('user-demo-001')));
      expect(user == Object(), isFalse);
      expect(user == (null as Object?), isFalse);
    });

    test('un Set y un Map tratan como el mismo usuario a los que comparten '
        'id', () {
      final first = _user('1', name: 'Primero');
      final sameId = _user('1', name: 'Segundo');
      final other = _user('2');

      final set = {first, sameId, other};
      final map = {first: 'a'}..[sameId] = 'b';

      expect(set, hasLength(2));
      expect(set.contains(_user('1', name: 'Tercero')), isTrue);
      expect(map, hasLength(1));
      expect(map[_user('1', name: 'Otro')], 'b');
    });

    test(
      'el hashCode es estable entre llamadas y coherente con la igualdad',
      () {
        final a = _user('1', name: 'A');
        final b = _user('1', name: 'B');

        expect(a.hashCode, a.hashCode);
        expect(a.hashCode, b.hashCode);
      },
    );
  });
}
