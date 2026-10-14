/// Motivo por el que un correo introducido no es aceptable.
enum EmailValidationError {
  /// El correo está vacío, o solo tiene espacios en blanco.
  required,

  /// El correo no cumple el formato pragmático de [Email].
  invalidFormat,
}

/// Se lanza cuando se intenta construir un [Email] con un valor no válido.
class InvalidEmailException implements Exception {
  const InvalidEmailException(this.error);

  final EmailValidationError error;

  @override
  String toString() => 'InvalidEmailException($error)';
}

/// Correo electrónico válido y normalizado (recortado y en minúsculas).
///
/// El formato es pragmático, no pretende cumplir el RFC 5322: exactamente una
/// arroba, parte local no vacía, dominio con al menos un punto, ninguna
/// etiqueta de dominio vacía y ningún espacio en blanco interno.
class Email {
  const Email._(this.value);

  /// Construye un [Email] normalizado a partir de [raw].
  ///
  /// Lanza [InvalidEmailException] si [raw] no supera [validate].
  factory Email.parse(String raw) {
    final error = validate(raw);
    if (error != null) {
      throw InvalidEmailException(error);
    }

    return Email._(raw.trim().toLowerCase());
  }

  /// Correo normalizado: sin espacios alrededor y en minúsculas.
  final String value;

  /// Devuelve el motivo por el que [raw] no es válido, o `null` si lo es.
  ///
  /// Se evalúa el correo recortado, igual que hace [Email.parse].
  static EmailValidationError? validate(String raw) {
    final candidate = raw.trim();
    if (candidate.isEmpty) {
      return EmailValidationError.required;
    }

    if (!_hasValidFormat(candidate)) {
      return EmailValidationError.invalidFormat;
    }

    return null;
  }

  static bool _hasValidFormat(String candidate) {
    if (_hasWhitespace(candidate)) {
      return false;
    }

    final parts = candidate.split('@');
    if (parts.length != 2) {
      return false;
    }

    final [local, domain] = parts;
    if (local.isEmpty) {
      return false;
    }

    final labels = domain.split('.');

    return labels.length >= 2 && labels.every((label) => label.isNotEmpty);
  }

  /// Usa la misma definición de espacio en blanco que [String.trim], con la
  /// que se recorta el correo; así lo que se recorta en los extremos es
  /// exactamente lo que se rechaza en el interior.
  static bool _hasWhitespace(String candidate) {
    return candidate.runes.any(
      (rune) => String.fromCharCode(rune).trim().isEmpty,
    );
  }

  @override
  bool operator ==(Object other) => other is Email && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
