import 'package:fit_notes/features/auth/domain/email.dart';
import 'package:fit_notes/features/auth/domain/user.dart';
import 'package:fit_notes/features/auth/presentation/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel.fromEntity', () {
    test('expone el nombre y el correo como texto de visualización', () {
      final user = User(
        id: 'user-demo-001',
        name: 'Demo FitNotes',
        email: Email.parse('DEMO@fitnotes.dev'),
      );

      final model = UserModel.fromEntity(user);

      expect(model.displayName, 'Demo FitNotes');
      expect(model.email, 'demo@fitnotes.dev');
    });
  });
}
