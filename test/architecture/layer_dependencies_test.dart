// Comprobación automatizada de las reglas de dependencia entre capas.
//
// Lee los `.dart` de `lib/` con `dart:io`, extrae las directivas `import` y
// `export` (rutas `package:fit_notes/...` y rutas relativas) y verifica:
//
// - `domain` no importa `package:flutter`, `data` ni `presentation`.
// - `data` solo importa `domain` (y su propia capa), además de `dart:core`,
//   `dart:async` y `dart:convert`.
// - `presentation` no importa `data`.
// - Solo `lib/app.dart` conoce la implementación `MockAuthRepository`.
//
// Las funciones de análisis son puras y se autocomprueban con fuentes sintéticas
// para que el test nunca pase en vacío.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _packageName = 'fit_notes';
const String _mockRepositoryPath =
    'features/auth/data/mock_auth_repository.dart';
const String _compositionRoot = 'app.dart';

const Set<String> _dataAllowedDartLibraries = {
  'dart:core',
  'dart:async',
  'dart:convert',
};

enum _Layer { domain, data, presentation, other }

/// Directiva `import` o `export` con su URI literal.
class _Directive {
  const _Directive(this.keyword, this.uri);

  final String keyword;
  final String uri;

  @override
  String toString() => "$keyword '$uri'";
}

/// Extrae las directivas `import` y `export` (incluidas las URI de
/// configuraciones condicionales `if (...) 'uri'`) del prefijo de directivas de
/// un archivo Dart. Se detiene en la primera declaración que no es una
/// directiva, de modo que cadenas o comentarios posteriores no cuentan.
List<_Directive> _parseDirectives(String source) {
  final directives = <_Directive>[];
  var index = 0;

  bool atEnd() => index >= source.length;

  void skipTrivia() {
    while (!atEnd()) {
      if (source.startsWith('//', index)) {
        final newline = source.indexOf('\n', index);
        index = newline == -1 ? source.length : newline + 1;
      } else if (source.startsWith('/*', index)) {
        var depth = 0;
        while (!atEnd()) {
          if (source.startsWith('/*', index)) {
            depth++;
            index += 2;
          } else if (source.startsWith('*/', index)) {
            depth--;
            index += 2;
            if (depth == 0) {
              break;
            }
          } else {
            index++;
          }
        }
      } else if (source.codeUnitAt(index) <= 0x20 ||
          source.codeUnitAt(index) == 0xFEFF) {
        index++;
      } else {
        return;
      }
    }
  }

  final wordPattern = RegExp(r'[A-Za-z_]+');
  final literalPattern = RegExp(r'''r?(?:'([^'\n]*)'|"([^"\n]*)")''');
  final conditionalPattern = RegExp(
    r'''if\s*\([^)]*\)\s*(?:'([^'\n]*)'|"([^"\n]*)")''',
  );

  while (true) {
    skipTrivia();
    if (atEnd()) {
      break;
    }

    final word = wordPattern.matchAsPrefix(source, index)?.group(0);
    if (word == null) {
      break;
    }

    if (word == 'library' || word == 'part') {
      final end = source.indexOf(';', index);
      if (end == -1) {
        break;
      }
      index = end + 1;
      continue;
    }

    if (word != 'import' && word != 'export') {
      break;
    }

    final end = source.indexOf(';', index);
    if (end == -1) {
      break;
    }

    final statement = source.substring(index + word.length, end);
    final main = literalPattern.matchAsPrefix(statement.trimLeft());
    if (main != null) {
      directives.add(_Directive(word, main.group(1) ?? main.group(2)!));
    }
    for (final match in conditionalPattern.allMatches(statement)) {
      directives.add(_Directive(word, match.group(1) ?? match.group(2)!));
    }
    index = end + 1;
  }

  return directives;
}

/// Ruta de [uri] relativa a `lib/` si apunta a este paquete; `null` si apunta
/// a `dart:` o a otro paquete.
String? _resolveToLibPath(String fromLibPath, String uri) {
  if (uri.startsWith('dart:')) {
    return null;
  }

  if (uri.startsWith('package:')) {
    final prefix = 'package:$_packageName/';
    return uri.startsWith(prefix) ? uri.substring(prefix.length) : null;
  }

  final base = Uri.parse(fromLibPath);

  return base.resolve(uri).path;
}

_Layer _layerOf(String libPath) {
  final segments = libPath.split('/');
  if (segments.length >= 4 && segments.first == 'features') {
    switch (segments[2]) {
      case 'domain':
        return _Layer.domain;
      case 'data':
        return _Layer.data;
      case 'presentation':
        return _Layer.presentation;
    }
  }

  return _Layer.other;
}

/// Evalúa las reglas sobre [sources] (ruta relativa a `lib/` -> contenido) y
/// devuelve un mensaje por cada infracción, con el archivo y el import
/// infractor.
List<String> _findViolations(Map<String, String> sources) {
  final violations = <String>[];

  void report(String file, _Directive directive, String rule) {
    violations.add('lib/$file: $directive viola la regla "$rule"');
  }

  for (final entry in sources.entries) {
    final file = entry.key;
    final layer = _layerOf(file);

    for (final directive in _parseDirectives(entry.value)) {
      final uri = directive.uri;
      final target = _resolveToLibPath(file, uri);
      final targetLayer = target == null ? null : _layerOf(target);

      if (target == _mockRepositoryPath && file != _compositionRoot) {
        report(
          file,
          directive,
          'solo lib/$_compositionRoot conoce MockAuthRepository',
        );
      }

      switch (layer) {
        case _Layer.domain:
          if (uri.startsWith('package:flutter/') ||
              uri.startsWith('package:flutter_')) {
            report(file, directive, 'domain no importa package:flutter');
          } else if (targetLayer == _Layer.data) {
            report(file, directive, 'domain no importa data');
          } else if (targetLayer == _Layer.presentation) {
            report(file, directive, 'domain no importa presentation');
          }
        case _Layer.data:
          if (uri.startsWith('dart:')) {
            final library = uri.split('/').first;
            if (!_dataAllowedDartLibraries.contains(library)) {
              report(
                file,
                directive,
                'data solo importa dart:core, dart:async y dart:convert',
              );
            }
          } else if (target == null) {
            report(file, directive, 'data solo importa domain');
          } else if (targetLayer != _Layer.domain &&
              targetLayer != _Layer.data) {
            report(file, directive, 'data solo importa domain');
          }
        case _Layer.presentation:
          if (targetLayer == _Layer.data) {
            report(file, directive, 'presentation no importa data');
          }
        case _Layer.other:
          break;
      }
    }
  }

  return violations;
}

Map<String, String> _readLibSources() {
  final lib = Directory('lib');
  expect(
    lib.existsSync(),
    isTrue,
    reason: 'Ejecuta las pruebas desde la raíz del paquete (falta lib/).',
  );

  final sources = <String, String>{};
  for (final entity in lib.listSync(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final relative = entity.path
          .substring(lib.path.length + 1)
          .replaceAll(r'\', '/');
      sources[relative] = entity.readAsStringSync();
    }
  }

  return sources;
}

void main() {
  group('autocomprobación del detector', () {
    test('extrae import y export, en comillas simples y dobles, multilínea y '
        'condicionales', () {
      final directives = _parseDirectives('''
// import 'package:comentado/no.dart';
/* import 'package:bloque/no.dart'; */
library demo;

import 'package:flutter/material.dart';
import "../data/dobles.dart" as dobles show Algo;
export 'src/a.dart'
    hide Otro;
import 'stub.dart'
    if (dart.library.io) 'io.dart'
    if (dart.library.html) 'web.dart';

class Declaracion {
  static const texto = "import 'package:flutter/no_cuenta.dart';";
}
import 'package:no/despues_de_declaraciones.dart';
''');

      expect(directives.map((d) => d.toString()), [
        "import 'package:flutter/material.dart'",
        "import '../data/dobles.dart'",
        "export 'src/a.dart'",
        "import 'stub.dart'",
        "import 'io.dart'",
        "import 'web.dart'",
      ]);
    });

    test('resuelve rutas package: y relativas', () {
      expect(
        _resolveToLibPath(
          'features/auth/domain/user.dart',
          'package:fit_notes/features/auth/data/user_dto.dart',
        ),
        'features/auth/data/user_dto.dart',
      );
      expect(
        _resolveToLibPath(
          'features/auth/domain/user.dart',
          '../data/user_dto.dart',
        ),
        'features/auth/data/user_dto.dart',
      );
      expect(
        _resolveToLibPath('features/auth/domain/user.dart', 'email.dart'),
        'features/auth/domain/email.dart',
      );
      expect(_resolveToLibPath('app.dart', 'dart:io'), isNull);
      expect(_resolveToLibPath('app.dart', 'package:otro/x.dart'), isNull);
    });

    test('un import prohibido de domain a Flutter se detecta con archivo e '
        'import', () {
      final violations = _findViolations({
        'features/auth/domain/ejemplo.dart':
            "import 'package:flutter/material.dart';\n",
      });

      expect(violations, hasLength(1));
      expect(violations.single, contains('features/auth/domain/ejemplo.dart'));
      expect(
        violations.single,
        contains("import 'package:flutter/material.dart'"),
      );
    });

    test('detecta cada regla con rutas package: y relativas', () {
      final violations = _findViolations({
        'features/a/domain/d1.dart': "import '../data/x.dart';",
        'features/a/domain/d2.dart':
            "import 'package:fit_notes/features/a/presentation/y.dart';",
        'features/a/domain/d3.dart': "export 'package:flutter/widgets.dart';",
        'features/a/data/m1.dart': "import 'dart:io';",
        'features/a/data/m2.dart': "import '../presentation/z.dart';",
        'features/a/data/m3.dart': "import 'package:http/http.dart';",
        'features/a/data/m4.dart': "import 'dart:convert';",
        'features/a/data/m5.dart': "import '../domain/ok.dart';",
        'features/a/presentation/p1.dart':
            "import 'package:fit_notes/features/a/data/mock.dart';",
        'features/a/presentation/p2.dart': "import '../../../app.dart';",
        'features/auth/presentation/p3.dart':
            "import '../data/mock_auth_repository.dart';",
        'main.dart': "import 'package:fit_notes/features/auth/data/mock_auth_repository.dart';",
        'app.dart':
            "import 'features/auth/data/mock_auth_repository.dart';\n"
            "import 'package:flutter/material.dart';",
      });

      bool mentions(String file) => violations.any((v) => v.contains(file));

      expect(mentions('d1.dart'), isTrue);
      expect(mentions('d2.dart'), isTrue);
      expect(mentions('d3.dart'), isTrue);
      expect(mentions('m1.dart'), isTrue);
      expect(mentions('m2.dart'), isTrue);
      expect(mentions('m3.dart'), isTrue);
      expect(mentions('m4.dart'), isFalse);
      expect(mentions('m5.dart'), isFalse);
      expect(mentions('p1.dart'), isTrue);
      expect(mentions('p2.dart'), isFalse);
      expect(
        violations.any(
          (v) => v.contains('p3.dart') && v.contains('MockAuthRepository'),
        ),
        isTrue,
      );
      expect(violations.any((v) => v.startsWith('lib/main.dart:')), isTrue);
      expect(violations.any((v) => v.startsWith('lib/app.dart:')), isFalse);
    });

    test('un conjunto sin infracciones devuelve una lista vacía', () {
      expect(
        _findViolations({
          'features/a/domain/ok.dart': "import 'user.dart';",
          'features/a/data/ok.dart':
              "import 'dart:async';\nimport '../domain/ok.dart';",
          'features/a/presentation/ok.dart':
              "import 'package:flutter/material.dart';\n"
              "import '../domain/ok.dart';",
        }),
        isEmpty,
      );
    });
  });

  group('dependencias reales de lib/', () {
    late Map<String, String> sources;

    setUpAll(() {
      sources = _readLibSources();
    });

    test('se encontraron archivos en cada capa (el análisis no es vacío)', () {
      for (final layer in [_Layer.domain, _Layer.data, _Layer.presentation]) {
        expect(
          sources.keys.where((file) => _layerOf(file) == layer),
          isNotEmpty,
          reason: 'No hay archivos de la capa ${layer.name} en lib/',
        );
      }
      expect(sources.keys, contains(_compositionRoot));
      expect(sources.keys, contains(_mockRepositoryPath));
    });

    test('se respetan las reglas de dependencia entre capas', () {
      final violations = _findViolations(sources);

      expect(
        violations,
        isEmpty,
        reason: 'Infracciones de arquitectura:\n${violations.join('\n')}',
      );
    });
  });
}
