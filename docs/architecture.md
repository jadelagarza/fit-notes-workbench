# Arquitectura

Describe la organización del código de FitNotes tal como está implementado (verificado contra `lib/` y `test/architecture/layer_dependencies_test.dart`). Es una plantilla replicable: para llevarla a otro proyecto, ver [replication-guide.md](replication-guide.md).

## Capas y raíz de composición

Estructura *feature-first*: cada funcionalidad vive en `lib/features/<feature>/` con tres capas.

```text
lib/
  main.dart                       solo runApp(const FitNotesApp())
  app.dart                        FitNotesApp: raíz de composición
  features/auth/
    domain/
      email.dart                  Email (VO), EmailValidationError, InvalidEmailException
      user.dart                   User (entidad)
      auth_repository.dart        AuthRepository (contrato)
      auth_exceptions.dart        InvalidCredentialsException, ServiceUnavailableException,
                                  LoginValidationException, PasswordValidationError
      login_use_case.dart         LoginUseCase
    data/
      user_dto.dart               UserDTO
      mock_auth_repository.dart   MockAuthRepository (implementa AuthRepository)
    presentation/
      login_screen.dart           LoginScreen (StatefulWidget)
      user_model.dart             UserModel
      login_texts.dart            todas las cadenas visibles (español)
      login_keys.dart             claves estables de widgets, para las pruebas
      widgets/                    LoginForm, LoginSuccessView, LoginErrorBanner
```

| Capa | Contiene | Depende de |
| --- | --- | --- |
| `domain` | Reglas de negocio, entidades, objetos de valor, contratos y casos de uso. Dart puro | nada (ni Flutter ni otras capas) |
| `data` | Implementaciones de los contratos y objetos de transferencia | `domain` |
| `presentation` | Pantallas, widgets, textos y modelos de visualización | `domain` y su propio código |
| `app.dart` | Compone las piezas: `MockAuthRepository(latency: 800 ms)` → `LoginUseCase` → `LoginScreen` | todas |

`app.dart` es la **única** que conoce la implementación `MockAuthRepository`. Sustituir el mock por un repositorio real consiste en cambiar esa línea de composición; `domain` y `presentation` no se tocan.

El caso de uso (`LoginUseCase`) pertenece a `domain` y contiene reglas de negocio: valida los dos campos a la vez y solo delega en el repositorio si ambos son válidos.

## Regla de dirección de dependencias

```text
presentation ──► domain ◄── data
      ▲                       ▲
      └────────── app.dart ───┘   (app.dart ve todo)
```

1. `domain` no importa `package:flutter`, `data` ni `presentation`.
2. `data` solo importa `domain` (y su propia capa). Además de `dart:core`, solo se permiten `dart:async` y `dart:convert`.
3. `presentation` no importa `data`.
4. Solo `lib/app.dart` conoce `MockAuthRepository`.

### Cómo se comprueba

`flutter test test/architecture` ejecuta `test/architecture/layer_dependencies_test.dart`, escrito por un test-engineer independiente. El test:

- Lee todos los `.dart` bajo `lib/` con `dart:io` (por eso hay que ejecutarlo desde la raíz del paquete; si falta `lib/`, falla con un mensaje explícito).
- Extrae las directivas `import` y `export` (rutas `package:fit_notes/...`, rutas relativas y URIs de configuraciones condicionales), ignorando comentarios y cadenas posteriores a las directivas.
- Clasifica cada archivo por capa según su ruta (`features/<feature>/domain|data|presentation`) y aplica las cuatro reglas, informando archivo e import infractor.
- Se autocomprueba con fuentes sintéticas (un import prohibido se detecta; un conjunto limpio no da infracciones) y verifica que cada capa tenga archivos, para que no pase en vacío.

Si añades una capa, otra feature o una nueva dependencia permitida, actualiza ese test: las reglas están codificadas en él, no inferidas.

## Responsabilidades de Entity, VO, DTO y Model

| Concepto | Clase | Capa | Responsabilidad | Igualdad |
| --- | --- | --- | --- | --- |
| Objeto de valor | `Email` | domain | Garantiza que un correo es válido y está normalizado. Constructor privado: solo se crea con `Email.parse` | por valor (`value`) |
| Entidad | `User` | domain | Usuario identificado: `id`, `name`, `email` (`Email`). No conoce DTO ni Model | por `id` |
| DTO | `UserDTO` | data | Forma primitiva (`String`) de un usuario en la frontera de datos; JSON ↔ entidad | n/a |
| Model | `UserModel` | presentation | Datos listos para mostrar (`displayName`, `email` como texto). No conoce el DTO | n/a |

Convención de nombres: la entidad es `User` (sin el sufijo `Entity`); el objeto de valor lleva el nombre del dominio (`Email`), sin sufijo genérico.

### `Email`: validar y normalizar en un único sitio

- `Email.validate(String raw)` devuelve `EmailValidationError?` (`required` o `invalidFormat`) o `null` si es válido. Es la **única** fuente de la regla: la pantalla no la repite.
- `Email.parse(String raw)` lanza `InvalidEmailException` si no es válido; si lo es, devuelve el correo recortado y en minúsculas.
- Recorte y rechazo de espacios internos usan la misma definición de espacio en blanco (la de `String.trim`).

```dart
Email.parse('  DEMO@FitNotes.dev ').value;   // 'demo@fitnotes.dev'
Email.validate('');                          // EmailValidationError.required
Email.validate('a@b');                       // EmailValidationError.invalidFormat
```

### Conversiones entre entidad, DTO y Model

```text
JSON ──UserDTO.fromJson──► UserDTO ──toEntity()──► User ──UserModel.fromEntity──► UserModel
                              ▲                      │
                              └──UserDTO.fromEntity──┘
```

Ejemplo real, el del escenario de éxito del mock (`MockAuthRepository`):

```dart
const json = {'id': 'user-demo-001', 'name': 'Demo FitNotes', 'email': 'demo@fitnotes.dev'};

final dto = UserDTO.fromJson(json);     // UserDTO(id, name, email) con texto
final user = dto.toEntity();            // User(id: 'user-demo-001', name: 'Demo FitNotes',
                                        //      email: Email.parse('demo@fitnotes.dev'))
final model = UserModel.fromEntity(user); // displayName: 'Demo FitNotes', email: 'demo@fitnotes.dev'
```

Política ante JSON mal formado (documentada en `UserDTO` y probada):

- `UserDTO.fromJson` lanza `FormatException` si falta una clave, si su valor no es texto, o si `id` o `name` están en blanco. Las claves desconocidas se ignoran.
- `UserDTO.toEntity` no valida el correo por sí mismo: delega en `Email.parse` y propaga `InvalidEmailException` si el correo del DTO no es válido.
- `UserDTO.fromEntity` copia `id`, `name` y `email.value`; el DTO no normaliza.

## Flujo completo del inicio de sesión

```text
LoginScreen            LoginUseCase                  AuthRepository (MockAuthRepository)
    │  call(email, password)  │                                   │
    │ ───────────────────────►│ Email.validate + password.isEmpty │
    │                         │   ├─ algún error ► LoginValidationException (sin llamar)
    │                         │   └─ ok: login(Email.parse(email), password)
    │                         │ ─────────────────────────────────►│ espera la latencia
    │                         │                                   │ decide por credenciales
    │                         │                                   │ JSON → UserDTO → User
    │ ◄────────────────────── User ◄──────────────────────────────│   (o lanza una excepción)
    │ UserModel.fromEntity(user) → pantalla de éxito
```

Resultado de `MockAuthRepository.login` (tras esperar `latency`):

| Entrada | Resultado |
| --- | --- |
| `fallo@fitnotes.dev`, cualquier contraseña | lanza `ServiceUnavailableException` |
| `demo@fitnotes.dev` con `Demo1234` exacta | JSON fijo → `UserDTO.fromJson(...).toEntity()` → devuelve `User` |
| cualquier otra | lanza `InvalidCredentialsException` |

Excepciones y cómo las traduce la pantalla (`LoginScreen._submit`):

| Excepción (dominio) | Origen | Qué muestra la pantalla |
| --- | --- | --- |
| `LoginValidationException` (`emailError`, `passwordError`) | `LoginUseCase`, antes de llamar al repositorio | Error junto a cada campo (`InputDecoration.errorText`), sin estado de carga |
| `InvalidCredentialsException` | repositorio | Mensaje de credenciales inválidas; formulario editable con valores conservados |
| `ServiceUnavailableException` | repositorio | Mensaje de error técnico ("servicio no disponible") |
| cualquier otro error (`on Object`) | cualquier punto | El mismo mensaje técnico; la pantalla nunca queda en carga |

Los errores se señalan con excepciones de dominio, no con un tipo `Result`. Los textos están en `login_texts.dart` (`LoginTexts`) y las pruebas los referencian desde ahí; el contrato no fija su redacción exacta.

## Patrón `StatefulWidget` sin gestor de estado

`LoginScreen` recibe `LoginUseCase` por constructor y guarda su estado localmente en `_LoginScreenState`. No usa Bloc, Provider ni similares.

Estado local:

- Un enum privado `_LoginStatus { idle, loading, success, failure }`.
- Los errores por campo (`String?`), el mensaje de fallo (`String?`) y el `UserModel?` del éxito.
- Dos `TextEditingController`, liberados en `dispose`.

Transiciones:

```text
idle ──enviar──► loading ──éxito──► success ──"Volver al formulario"──► idle (campos y mensajes limpios)
                    │
                    ├─ LoginValidationException ─► idle (errores por campo)
                    └─ otra excepción ───────────► failure (mensaje; valores conservados) ──enviar──► loading
```

Decisiones de diseño del patrón:

- **Guarda contra doble envío**: `_submit` retorna de inmediato si el estado ya es `loading`, sea cual sea el medio de envío (botón o teclado). Además, el botón queda deshabilitado (`onPressed: null`) durante la carga.
- **Pasar a `loading` antes de validar**: la validación vive en el caso de uso (una única fuente de la regla) y su firma es asíncrona. Para que la guarda funcione desde el primer toque, el estado cambia a `loading` de forma síncrona dentro de `setState`, antes del `await`. Si la validación falla, la pantalla vuelve a `idle` con los errores en la misma ráfaga de microtareas, antes de que se pinte otro fotograma; por eso el indicador de progreso no llega a verse (inferencia sobre el planificador de Flutter, respaldada por pruebas que comprueban que no aparece el indicador tras un error de validación).
- **`mounted` tras cada `await`**: si la pantalla se retiró mientras la solicitud estaba en curso, no se llama a `setState`. Hay pruebas que completan la solicitud después de retirar la pantalla y comprueban que no hay excepciones ni contaminación de una pantalla posterior.
- **Al iniciar un intento** se limpian los errores y el mensaje del intento anterior.
- **`dispose`** libera los controllers.
- **Campos durante la carga**: no se deshabilitan; solo el envío está deshabilitado.
- **Contraseña** con `obscureText: true`; nunca se muestra en claro.
- `build` es declarativo: elige entre `LoginSuccessView` y `LoginForm` según el estado. Los widgets de `widgets/` no deciden nada; muestran lo que reciben y avisan con callbacks.
- Los widgets tienen claves estables (`LoginKeys`: `login_email_field`, `login_password_field`, `login_submit_button`, `login_progress_indicator`, `login_error_message`, `login_success_view`, `login_back_button`) para localizarlos en las pruebas de widget.

## Cómo se prueba cada capa

| Qué | Dónde | Enfoque |
| --- | --- | --- |
| `Email`, `User`, `LoginUseCase` | `test/features/auth/domain/` | Pruebas unitarias con un repositorio doble que cuenta llamadas; incluyen la tabla de ejemplos de referencia del contrato |
| `UserDTO`, `MockAuthRepository` | `test/features/auth/data/` | Conversión JSON ↔ entidad, JSON mal formado, los tres escenarios y el retardo (con `testWidgets` y `pump` para controlar el reloj) |
| `UserModel`, `LoginScreen` | `test/features/auth/presentation/` | Pruebas de widget: repositorio doble con `Completer` para observar la carga y contar llamadas; `MockAuthRepository` con latencia cero para el flujo de extremo a extremo |
| Composición | `test/app_test.dart` | La app arranca en el inicio de sesión y el resultado tarda 800 ms |
| Capas | `test/architecture/` | Reglas de dependencia (ver arriba) |

La trazabilidad completa requisito → prueba del contrato vive en el informe de verificación de cada cambio; este documento no la duplica.
