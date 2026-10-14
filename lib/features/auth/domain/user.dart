import 'email.dart';

/// Usuario identificado tras un inicio de sesión exitoso.
///
/// Es una entidad: su identidad es [id], de modo que dos usuarios con el mismo
/// [id] son el mismo usuario aunque otros datos difieran.
class User {
  const User({required this.id, required this.name, required this.email});

  final String id;
  final String name;
  final Email email;

  @override
  bool operator ==(Object other) => other is User && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
