import '../domain/user.dart';

/// Datos de visualización de un [User] para la pantalla.
class UserModel {
  const UserModel({required this.displayName, required this.email});

  factory UserModel.fromEntity(User user) {
    return UserModel(displayName: user.name, email: user.email.value);
  }

  final String displayName;
  final String email;
}
