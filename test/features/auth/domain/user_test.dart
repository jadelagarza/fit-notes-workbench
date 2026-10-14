import 'package:fit_notes/features/auth/domain/email.dart';
import 'package:fit_notes/features/auth/domain/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  User buildUser({
    String id = 'user-demo-001',
    String name = 'Demo FitNotes',
    String email = 'demo@fitnotes.dev',
  }) {
    return User(id: id, name: name, email: Email.parse(email));
  }

  group('User', () {
    test('expone id, nombre y correo', () {
      final user = buildUser();

      expect(user.id, 'user-demo-001');
      expect(user.name, 'Demo FitNotes');
      expect(user.email, Email.parse('demo@fitnotes.dev'));
    });

    test('es igual a otro usuario con el mismo id', () {
      final user = buildUser();
      final sameId = buildUser(name: 'Otro nombre', email: 'otro@ejemplo.com');

      expect(user, sameId);
      expect(user.hashCode, sameId.hashCode);
    });

    test('es distinto de un usuario con otro id', () {
      expect(buildUser(), isNot(buildUser(id: 'user-demo-002')));
    });
  });
}
