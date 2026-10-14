# FitNotes

Aplicación Flutter (iOS y Android) cuya primera funcionalidad es una pantalla de **inicio de sesión simulado** con correo y contraseña. Sirve como proyecto de referencia: su estructura, sus pruebas y su preparación de assurance están pensadas para replicarse en otros proyectos (ver [docs/replication-guide.md](docs/replication-guide.md)).

> **Aviso: el inicio de sesión es SIMULADO y no ofrece ninguna seguridad real.**
>
> - No hay backend, red ni persistencia de sesión.
> - Las credenciales de prueba (`demo@fitnotes.dev` / `Demo1234`) están escritas en el código fuente y no protegen nada.
> - El repositorio simulado (`MockAuthRepository`) está conectado en **todos** los modos de ejecución (debug, profile y release): `lib/app.dart` lo instancia sin condiciones. No publiques esta aplicación como si autenticara a alguien. Antes de usar autenticación real hay que sustituir ese repositorio por una implementación real de `AuthRepository` en `lib/app.dart`.

## Requisitos

Versiones observadas en el entorno donde se desarrolló y verificó (2026-10-14):

| Herramienta | Versión | Fuente |
| --- | --- | --- |
| Flutter | 3.47.4 (canal stable, revisión `9584c6713b`) | `flutter --version` |
| Dart | 3.13.3 | `dart --version`; `pubspec.yaml` exige `sdk: ^3.13.3` |
| Plataformas | `ios/` y `android/` | carpetas existentes; no hay `web/`, `macos/`, etc. |

- El SDK se gestiona con [fvm](https://fvm.app). El repositorio **no** tiene `.fvmrc`: la versión no queda fijada por el proyecto para el desarrollo local, solo está documentada aquí. El workflow de CI sí la fija (versión y commit) en su propio `env` (ver [Integración continua](#integración-continua-ci)).
- En la shell zsh del autor, `flutter` es un alias de `fvm flutter`. Los alias no existen en scripts ni en la mayoría de herramientas externas; en ellos usa la ruta del SDK, por ejemplo `/Users/Alfredo/.fvm/default/bin/flutter`, o añade ese directorio al `PATH`.
- Para ejecutar en iOS hace falta Xcode; para Android, el SDK de Android. Este README no verifica esos prerrequisitos.
- El identificador de aplicación es el valor por defecto de `flutter create`: `com.example.fit_notes` (Android) y `com.example.fitNotes` (iOS). Es un marcador de posición: cámbialo antes de publicar.

## Instalar, ejecutar y probar

Desde la raíz del proyecto:

```bash
flutter pub get                  # instala dependencias
flutter run                      # ejecuta en un simulador o dispositivo conectado
flutter test                     # toda la suite de pruebas
flutter test test/architecture   # solo las reglas de dependencia entre capas
flutter analyze                  # análisis estático
dart format --output=none --set-exit-if-changed lib test   # COMPRUEBA el formato: no escribe nada y falla (exit distinto de 0) si algún archivo cambiaría
dart format lib test             # APLICA el formato: reescribe archivos y siempre sale con 0, así que no sirve como comprobación
```

- `flutter run` requiere un simulador o dispositivo; elige uno con `flutter devices` y `flutter run -d <id>`. La ejecución en simulador **no** forma parte de las comprobaciones automatizadas ni se ha ejecutado al escribir esta documentación.
- `flutter pub get`, `flutter analyze`, `flutter test` y la comprobación de formato (`dart format --output=none --set-exit-if-changed lib test`) se ejecutaron con éxito durante el desarrollo; `dart format lib test` solo aplica formato, no es una comprobación. El resultado de cada comprobación depende del estado del código en el momento de ejecutarla; vuelve a ejecutarlas para conocer el estado actual.

## Integración continua (CI)

El workflow [`.github/workflows/ci.yml`](.github/workflows/ci.yml) ejecuta en GitHub Actions las comprobaciones deterministas del proyecto: comprobación de formato, `flutter analyze`, `flutter test`, `flutter test test/architecture` y `flutter pub deps`, tras `flutter pub get --enforce-lockfile`. Se dispara en cada pull request hacia `main` y en cada push a `main`, y usa Flutter 3.47.4 sobre `ubuntu-24.04`. No ejecuta la compilación de iOS (`flutter build ios`), que requiere macOS.

**Estado: el workflow nunca se ha ejecutado en GitHub.** El remoto `origin` (`https://github.com/jadelagarza/fit-notes-workbench.git`) está configurado en este repositorio, pero, al redactar esto, no se ha hecho ni intentado ningún push, así que GitHub no ha visto el workflow. Que pase no equivale a `ASSURANCE_PASS` ni a una aprobación humana. Qué acredita y qué no, el detalle de cada paso y la política de assurance para el CI (aprobada por el usuario en el chat, sin atestación) están en [docs/assurance/verification.md](docs/assurance/verification.md#integración-continua-github-actions).

## Escenarios del inicio de sesión simulado

El resultado depende **solo** de las credenciales introducidas; no hay otros interruptores ni configuración. Las mismas credenciales producen siempre el mismo resultado.

| Correo | Contraseña | Resultado |
| --- | --- | --- |
| `demo@fitnotes.dev` | `Demo1234` (exacta) | **Éxito**: bienvenida con `Demo FitNotes` y `demo@fitnotes.dev` (usuario `user-demo-001`) |
| `fallo@fitnotes.dev` | cualquier contraseña no vacía | **Error técnico** ("servicio no disponible") |
| cualquier otra combinación que supere la validación | cualquiera no vacía | **Credenciales inválidas** |

Reglas de entrada, aplicadas al pulsar "Iniciar sesión" (o al enviar desde el teclado):

- **Correo**: se recortan los espacios en blanco iniciales y finales y se pasa a minúsculas. `  DEMO@FitNotes.dev ` equivale a `demo@fitnotes.dev` y activa el escenario de éxito. Si queda vacío, se muestra "correo obligatorio". Formato válido: exactamente una arroba, parte local no vacía, dominio con al menos un punto, sin etiquetas de dominio vacías y sin ningún espacio en blanco interno. No pretende cumplir el RFC 5322.
- **Contraseña**: no se recorta y solo es vacía con cero caracteres. `demo1234` (minúscula), ` Demo1234` (espacio inicial) y tres espacios no activan el éxito: dan credenciales inválidas. No hay reglas de complejidad.
- Si ambos campos son inválidos, se muestran los dos errores a la vez y no se hace ninguna solicitud.
- **Retardo**: el mock espera 800 ms antes de responder en la aplicación (constante `simulatedLoginLatency` en `lib/app.dart`). Las pruebas lo configuran en 0 ms (`MockAuthRepository()` sin argumentos), salvo las que comprueban el propio retardo.
- Un error conserva los valores escritos y deja el formulario editable para reintentar. Tras un éxito, "Volver al formulario" reinicia la pantalla de forma local; no es un cierre de sesión real.

Para probar un escenario a mano, ejecuta la app y escribe las credenciales de la tabla. Para comprobarlo de forma automática, `test/features/auth/presentation/login_screen_test.dart` recorre estos mismos escenarios con `MockAuthRepository` y latencia cero.

## Estructura del código

```text
lib/
  main.dart                      solo runApp
  app.dart                       FitNotesApp: raíz de composición
  features/auth/
    domain/                      Email, User, AuthRepository, excepciones, LoginUseCase
    data/                        UserDTO, MockAuthRepository
    presentation/                LoginScreen, UserModel, LoginTexts, LoginKeys, widgets/
test/                            replica la estructura de lib/ (más test/architecture/)
```

La explicación completa de capas, responsabilidades y flujo está en [docs/architecture.md](docs/architecture.md).

## Mapa de la documentación

| Documento | Para qué sirve |
| --- | --- |
| [README.md](README.md) | Este archivo: qué es, cómo ejecutarlo y cómo activar cada escenario |
| [docs/architecture.md](docs/architecture.md) | Capas, dirección de dependencias, Entity/VO/DTO/Model, flujo del login y patrón `StatefulWidget` sin gestor de estado |
| [docs/decisions.md](docs/decisions.md) | Registro de decisiones: qué, por qué y quién decidió |
| [docs/assurance/verification.md](docs/assurance/verification.md) | Qué evidencia debe producir un cambio, cómo ejecutar las comprobaciones y qué sigue requiriendo criterio humano |
| [docs/replication-guide.md](docs/replication-guide.md) | Guía paso a paso para llevar esta estructura y esta preparación de assurance a otro proyecto Flutter |
| [docs/quality-contracts/login.md](docs/quality-contracts/login.md) | Contrato de calidad del inicio de sesión (LOGIN-01 a LOGIN-36). **Pendiente de aprobación humana** |
| [.github/workflows/ci.yml](.github/workflows/ci.yml) | Workflow de CI: comprobaciones deterministas en pull requests y pushes a `main` (sin ejecutar todavía en GitHub) |
| [AGENTS.md](AGENTS.md) | Instrucciones para agentes: entrada obligatoria por el orquestador y reglas del repositorio |
| [.engineering-assurance/project-assurance.json](.engineering-assurance/project-assurance.json) | Configuración de assurance: rutas, comandos y capacidades |
