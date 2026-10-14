import '../domain/email.dart';
import '../domain/user.dart';

/// Representación primitiva de un [User] en la frontera de datos.
///
/// Política ante datos mal formados:
/// - [UserDTO.fromJson] lanza [FormatException] si falta una clave, si su valor
///   no es texto, o si `id` o `name` están en blanco.
/// - [toEntity] delega en [Email.parse] y propaga [InvalidEmailException] si el
///   correo no es válido.
class UserDTO {
  const UserDTO({required this.id, required this.name, required this.email});

  factory UserDTO.fromJson(Map<String, dynamic> json) {
    return UserDTO(
      id: _readRequiredText(json, 'id'),
      name: _readRequiredText(json, 'name'),
      email: _readText(json, 'email'),
    );
  }

  factory UserDTO.fromEntity(User user) {
    return UserDTO(id: user.id, name: user.name, email: user.email.value);
  }

  final String id;
  final String name;
  final String email;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'id': id, 'name': name, 'email': email};
  }

  User toEntity() {
    return User(id: id, name: name, email: Email.parse(email));
  }

  static String _readText(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('El campo "$key" debe ser texto.', json);
    }

    return value;
  }

  static String _readRequiredText(Map<String, dynamic> json, String key) {
    final value = _readText(json, key);
    if (value.trim().isEmpty) {
      throw FormatException('El campo "$key" no puede estar vacío.', json);
    }

    return value;
  }
}
