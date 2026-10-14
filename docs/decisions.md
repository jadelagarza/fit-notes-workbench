# Registro de decisiones

Registro breve de las decisiones tomadas al crear FitNotes y su inicio de sesión simulado: **qué** se decidió, **por qué** y **quién** decidió. Estado a 2026-10-14.

Convenciones:

- **Usuario**: la persona propietaria del proyecto. Sus decisiones son firmes mientras no las cambie.
- **Equipo**: el `engineering-orchestrator` o los agentes especialistas. Sus decisiones son **propuestas pendientes de aprobación humana**; mientras tanto son supuestos de trabajo. Una persona puede aprobarlas, ajustarlas o rechazarlas. Una decisión derivada por los agentes se atribuye al equipo aunque parezca obvia o se deduzca de la petición; solo se atribuye al usuario lo que él decidió o pidió.
- Si una decisión cambia, no borres la anterior: marca la antigua como sustituida y registra la nueva, para conservar el historial.
- El comportamiento exacto (requisitos LOGIN-01 a LOGIN-36) está en [quality-contracts/login.md](quality-contracts/login.md). Procedencia: **HUMAN** solo LOGIN-01 a LOGIN-03; LOGIN-04 a LOGIN-36 son **AGENT-PROPOSED**. Estado: el usuario confirmó la procedencia y aceptó las propuestas **en el chat el 2026-10-14**, pero el contrato **no tiene aprobación formal atestada** (ver [assurance/verification.md](assurance/verification.md)). Este registro explica las decisiones; no sustituye al contrato.

## Decisiones del usuario

| Decisión | Motivo | Quién |
| --- | --- | --- |
| El inicio de sesión se implementa con un mock de **credenciales deterministas** (opción B): el resultado depende solo de las credenciales introducidas, sin backend | Reproducir a voluntad éxito y errores y comprobarlos automáticamente, sin red ni configuración extra | Usuario |
| Interfaz en **español, sin localización** a otros idiomas (confirmado por el usuario a través del coordinador) | Alcance mínimo: un solo idioma; la localización está fuera del alcance del contrato | Usuario |
| Inicializar un repositorio Git (`git init`) | Versionar el proyecto. Se ejecutó en el repositorio de origen (`/Users/Alfredo/Desktop/fit-notes`); el repositorio actual (`fit-notes-workbench`) se creó aparte, con su propio commit inicial (ver la fila siguiente) | Usuario |
| Hacer un commit inicial local con la identidad personal | Registrar el punto de partida con la identidad que corresponde al propietario del repositorio | Usuario (autorización e identidad). **Histórico del repositorio de origen** (`/Users/Alfredo/Desktop/fit-notes`, commit `79e15ee`): este registro formaba parte de aquel commit inicial. Esa historia **no existe en este repositorio**: aquí el commit inicial es `774d5af` ("chore: creación del repositorio", solo `README.md`) y el proyecto llega en un commit posterior de la rama `feat/importar-proyecto-fit-notes` (commit de importación). Su SHA se informa fuera del repositorio (un commit no puede contener su propio SHA) |
| Renunciar al borrador previo (flujo *draft-first*) y autorizar la implementación directa | Obtener el ejemplo funcional sin una ronda de aprobación del plan; por eso las ambigüedades se resolvieron como decisiones del equipo y los requisitos añadidos quedan como AGENT-PROPOSED | Usuario |
| Importar el proyecto FitNotes a este repositorio (`fit-notes-workbench`) y sustituir su README de una línea por el README completo del proyecto | Que este repositorio contenga el proyecto con su CI y su preparación de assurance, partiendo del repositorio de origen (`/Users/Alfredo/Desktop/fit-notes`). Se hizo en la rama `feat/importar-proyecto-fit-notes` (commit de importación) | Usuario |
| Crear `.engineering-assurance/project-assurance.json` | Dejar la configuración de assurance lista para cambios futuros; este trabajo inicial no se certifica con ella | Usuario |
| Añadir un workflow de GitHub Actions con las comprobaciones deterministas (**Fase 1**), implementado directamente (sin borrador previo) aunque el gate formal siga bloqueado | Que las comprobaciones las ejecute un tercero (GitHub) y no dependan de lo que informe un agente. No produce `ASSURANCE_PASS`; la firma Ed25519 con su gate (Fase 2) y los agentes headless (Fase 3) quedan fuera de alcance | Usuario (alcance de la Fase 1 y actuar directo) |
| **Libertad de los agentes para complementar escenarios**: pueden proponer escenarios adicionales cuando lo vean necesario, siempre con procedencia AGENT-PROPOSED. Las pruebas HUMAN se respetan siempre (no se debilitan, no se eliminan, no se reinterpretan). Solo es HUMAN lo que la persona pidió literalmente. Fecha: 2026-10-14; en el chat | Fijar una regla clara de procedencia y de respeto a lo que la persona pidió, sin limitar la cobertura que los agentes consideren necesaria. Ver [assurance/verification.md](assurance/verification.md#regla-de-la-persona-sobre-las-pruebas-human-y-las-propuestas) | Usuario |
| **Confirmar que el conjunto HUMAN es solo LOGIN-01, LOGIN-02 y LOGIN-03 y aceptar LOGIN-04 a LOGIN-36 como propuestas de los agentes** (conservan la procedencia AGENT-PROPOSED). Fecha: 2026-10-14; **en el chat, sin evento firmado**. Cita del usuario: "Aquellos escenarios en los que el humano solamente pensó solo son: LOGIN-01, LOGIN-02, LOGIN-03. Los demás, es decir, de LOGIN-04 a LOGIN-36 son propuestas del agente, las cuáles me parecen bien [...]" | Corregir la procedencia: LOGIN-04 a LOGIN-12 se habían etiquetado como HUMAN siendo reformulaciones de los agentes. Es una decisión humana registrada, **no una atestación**: no hay un evento de aprobación firmado por un emisor independiente, ni aprobación formal del contrato ni del inventario, y el gate formal sigue en `BLOCKED_ENVIRONMENT` | Usuario |
| **Aprobar el cambio de política** de `.engineering-assurance/project-assurance.json`: añadir `.github/**` a `paths.production` y `.github/workflows/**` a `review_triggers.dependencies` (propuesta del equipo; ver la última fila de [Integración continua](#integración-continua-ci)). Fecha: 2026-10-14; **aprobado por el usuario en el chat** | Que `.github/workflows/ci.yml` quede cubierto por la política (código de producción y dependencias); el motivo detallado está en la fila del equipo. Es una decisión humana registrada, **no una atestación**: no hay un evento de aprobación firmado por un emisor independiente, no existe la transición formal (`approved_policy_transition_sha256`) y el gate formal sigue en `BLOCKED_ENVIRONMENT` | Usuario |

## Decisiones del equipo (pendientes de aprobación)

Excepciones:

- La última fila de la sección [Integración continua](#integración-continua-ci) (política de `project-assurance.json`) ya cuenta con la aprobación del usuario en el chat; ver [Decisiones del usuario](#decisiones-del-usuario).
- Las reglas de la sección [Comportamiento (contrato)](#comportamiento-contrato) forman parte de los escenarios LOGIN-04 a LOGIN-36, que el usuario aceptó en el chat el 2026-10-14 (sin evento firmado ni aprobación formal atestada). La aceptación se refiere a esos escenarios tal como están redactados en el contrato (por ejemplo, LOGIN-25 solo cubre el retardo configurable y de 800 ms en la aplicación); las decisiones siguen siendo del equipo. Las decisiones de prueba que el contrato no recoge como requisito (como los 0 ms en las pruebas, en [Diseño](#diseño)) no están cubiertas por esa aceptación.

El resto sigue pendiente.

### Comportamiento (contrato)

| Decisión | Motivo | Quién |
| --- | --- | --- |
| Correo: recortar espacios y pasar a **minúsculas** antes de validar y usar (LOGIN-13, LOGIN-16) | El usuario lo dejó a criterio del equipo. Se compara sin distinguir mayúsculas aunque el RFC permita que la parte local sea sensible a ellas | Equipo |
| Contraseña **sin recorte**; solo es vacía con cero caracteres; sin reglas de complejidad (LOGIN-17, LOGIN-18) | Evitar alterar un secreto; la política de complejidad queda fuera de alcance | Equipo |
| Formato de correo **pragmático, no RFC 5322**: una arroba, parte local no vacía, dominio con punto, sin etiquetas vacías, sin espacio en blanco interno (LOGIN-15) | Suficiente para un inicio de sesión simulado; cumplir el RFC completo está fuera de alcance | Equipo |
| Escenarios del mock: `demo@fitnotes.dev` / `Demo1234` → éxito; `fallo@fitnotes.dev` + cualquier contraseña no vacía → error técnico; otra combinación → credenciales inválidas (LOGIN-21 a LOGIN-24) | Cubrir éxito y los dos tipos de error de forma determinista | Equipo |
| Retardo simulado **configurable** y de **800 ms** en la aplicación (LOGIN-25) | Hacer visible el estado de carga en la app | Equipo |
| Requisitos **LOGIN-04 a LOGIN-36** con procedencia `AGENT-PROPOSED`. Aceptados por el usuario en el chat el 2026-10-14 (ver [Decisiones del usuario](#decisiones-del-usuario)); conservan su procedencia | Cubrir las dimensiones que derivan de la petición o que esta no definía (éxito y error reproducibles, usuario identificado, estados de carga, éxito y error, sin backend, validación, reintento, textos distinguibles, fallos inesperados) | Equipo |
| ~~Requisitos **LOGIN-13 a LOGIN-36** con procedencia `AGENT-PROPOSED`~~ **Sustituida** por la fila anterior | Reflejaba la clasificación inicial, que etiquetaba LOGIN-04 a LOGIN-12 como HUMAN aunque eran reformulaciones de los agentes. El usuario corrigió la procedencia en el chat el 2026-10-14 | Equipo |
| El inventario humano contiene **solo LOGIN-01 a LOGIN-03** (procedencia HUMAN) | El validador exige que el inventario coincida exactamente con los requisitos HUMAN activos; marcar como HUMAN los AGENT-PROPOSED falsearía su procedencia. Los AGENT-PROPOSED aceptados en el chat no entran en el inventario: conservan su procedencia. Ver [assurance/verification.md](assurance/verification.md) | Equipo (la procedencia la confirmó el usuario en el chat) |
| ~~El inventario humano contiene **solo LOGIN-01 a LOGIN-12** (procedencia HUMAN)~~ **Sustituida** por la fila anterior | Etiquetaba como HUMAN a LOGIN-04 a LOGIN-12, que eran reformulaciones de los agentes. Al corregir la procedencia cambiaron los bytes del contrato: se recalculó `contract_sha256` en el inventario y en el archivo de propuestos, y ninguna aprobación anterior cubre los bytes nuevos | Equipo |

### Diseño

| Decisión | Motivo | Quién |
| --- | --- | --- |
| Excepciones de dominio (`InvalidCredentialsException`, `ServiceUnavailableException`, `LoginValidationException`) en lugar de un tipo `Result` | Mantener firmas simples (`Future<User>`); cada fallo tiene su propio tipo de excepción | Equipo |
| Nombres: la entidad es `User` (literal, sin el sufijo `Entity`); `UserDTO`; `UserModel`; el objeto de valor lleva el nombre del dominio (`Email`) | La petición original pedía `User`, `UserDTO` y `UserModel`; el sufijo por defecto de la convención solo es un respaldo | Equipo |
| Estructura *feature-first* con capas `domain`/`data`/`presentation` y raíz de composición `app.dart` | Dependencias claras y comprobables. Ver [architecture.md](architecture.md) | Equipo |
| `StatefulWidget` sin gestor de estado | Restricción técnica de la petición original | Equipo (derivada de la petición del usuario) |
| La regla de validación vive solo en `domain` (`Email.validate` y `LoginUseCase`); la pantalla muestra el resultado | Una única fuente de la regla | Equipo |
| `InvalidEmailException` y `EmailValidationError` en `email.dart`; `PasswordValidationError` en `auth_exceptions.dart` | Poner `InvalidEmailException` en `auth_exceptions.dart` habría creado un ciclo de imports con `email.dart` | Equipo (desarrollador) |
| `AuthRepository` como `abstract interface class` | Es un contrato puro | Equipo (desarrollador) |
| `LoginKeys` (archivo propio con las claves de los widgets) | Compartir las claves entre la pantalla y sus widgets sin imports circulares | Equipo (desarrollador) |
| La pantalla pasa a `loading` **de forma síncrona antes de validar** | La guarda contra doble envío debe ser efectiva desde el primer toque; la validación es asíncrona por vivir en el caso de uso. Ver [architecture.md](architecture.md) | Equipo (desarrollador) |
| Los campos **no se deshabilitan** durante la carga; solo el envío | El contrato solo exige deshabilitar el envío (LOGIN-26) | Equipo (desarrollador) |
| Política de `UserDTO` ante JSON mal formado: `FormatException` en `fromJson` (clave ausente, tipo incorrecto, `id` o `name` en blanco); `toEntity` propaga `InvalidEmailException` | Fallar de forma explícita en la frontera de datos | Equipo (desarrollador) |
| Constante pública `simulatedLoginLatency` en `app.dart` y un test de aplicación (`test/app_test.dart`) que comprueba los 800 ms | Dar evidencia ejecutable de LOGIN-25 | Equipo (desarrollador) |
| Retardo de **0 ms en las pruebas automatizadas** | No ralentizar las pruebas. `login.md` lo clasifica como decisión de prueba, no como requisito de comportamiento: LOGIN-25 solo dice que el retardo es configurable y de 800 ms en la aplicación. **No está cubierta por la aceptación en el chat del 2026-10-14**; sigue pendiente de aprobación | Equipo (equipo de prueba) |
| Hallazgo F-01 (correo con U+0085 interno superaba la validación): recorte y rechazo de espacios internos usan **la misma definición de espacio en blanco**, la de `String.trim` | Contradecía LOGIN-15 ("ningún espacio en blanco interno"). Estado: cerrado tras la revalidación independiente del test-engineer que lo descubrió (`Verified`) | Equipo (desarrollador corrige; verificador distinto revalida) |

### Proyecto y plataformas

| Decisión | Motivo | Quién |
| --- | --- | --- |
| Plataformas **iOS y Android** | Las carpetas `ios/` y `android/` son las generadas por `flutter create` | Equipo |
| Identificador de aplicación `com.example.*` (por defecto de `flutter create`) como **marcador de posición** | Sin identificador real definido; hay que cambiarlo antes de publicar | Equipo |
| Sin `.fvmrc`: la versión de Flutter (3.47.4) se documenta, no se fija para el desarrollo local (el workflow de CI sí la fija; ver más abajo) | No se registró un motivo; fijarla con fvm es una mejora posible | Equipo |

### Clasificación del cambio (assurance)

Clasificación registrada por el orquestador antes de delegar la implementación.

| Decisión | Motivo | Quién |
| --- | --- | --- |
| **Trabajo ordinario** (no certificación formal) para el cambio inicial | La base no tenía configuración de assurance; este trabajo la introduce para cambios futuros y no certifica el trabajo actual | Equipo (orquestador) |
| Riesgo **STANDARD**; DOMAIN-MODELING **mínimo** | El inicio de sesión es simulado: sin backend, red, persistencia, secretos ni credenciales reales, así que no se afecta materialmente ninguna regla de seguridad real. El dominio es pequeño (un VO, una entidad y reglas de validación), pero el VO protege una invariante | Equipo (orquestador) |
| TDD **REQUIRED** | Hay lógica de validación, un caso de uso y estados de pantalla verificables | Equipo (orquestador) |
| Superficies **DOMAIN**, **STATE_ORCHESTRATION** y **PRESENTATION**: REQUIRED. **PLATFORM**: OPTIONAL, no ejecutada. **INTEGRATION** y **OPERATIONAL**: NOT_APPLICABLE | Reglas, orquestación del estado y UI están implicadas; no hay integración real ni operación; la ejecución en dispositivo no se realizó | Equipo (orquestador) |
| Revisores: **code-reviewer**, **security-reviewer** y **dependencies-reviewer**; verificación independiente con **test-engineer** | Hay código de producción nuevo (code-reviewer); semántica de login y uso como plantilla (security-reviewer); el diff crea `pubspec.yaml` y `pubspec.lock`, que son disparadores de dependencias (dependencies-reviewer); cambio conductual (test-engineer) | Equipo (orquestador) |
| Especialistas no invocados: concurrencia/ciclo de vida **OPTIONAL** (cubierto por code-reviewer y por pruebas de `dispose`/doble envío); performance y reliability/observability **NOT_APPLICABLE** (sin rutas críticas, red ni operación); runtime validation **OPTIONAL**, no ejecutada (no se autorizó ejecutar la app en simulador o dispositivo) | Proporcionalidad al riesgo y a las superficies afectadas | Equipo (orquestador) |
| Hallazgo de seguridad **M1**: las credenciales de prueba están en el código y el mock está conectado en todos los modos; se mitiga con el aviso explícito del [README](../README.md) | Es una limitación aceptada de un inicio de sesión simulado; no se debe confundir con autenticación | Equipo (revisor de seguridad; mitigación documental) |

### Integración continua (CI)

Decisiones sobre [`.github/workflows/ci.yml`](../.github/workflows/ci.yml). Detalle de pasos y alcance en [assurance/verification.md](assurance/verification.md#integración-continua-github-actions). El workflow no se ha ejecutado todavía en GitHub.

| Decisión | Motivo | Quién |
| --- | --- | --- |
| Ejecutar en `ubuntu-24.04` (versión fija, no `ubuntu-latest`) | Evitar que el runner cambie sin aviso: la documentación de la imagen anuncia que la etiqueta `ubuntu-latest` pasará a Ubuntu 26.04 en noviembre de 2026. En las tarifas publicadas por GitHub, Linux de 2 núcleos ($0.006 por minuto) cuesta menos que Windows ($0.010) y macOS ($0.062) (ver la [guía de replicación](replication-guide.md#fuentes-consultadas)) | Equipo |
| Disparadores `pull_request` y `push`, ambos solo hacia/sobre `main`; nunca `pull_request_target`; sin filtros `paths`; `permissions: contents: read`; sin secretos ni tokens | Que cada PR y cada commit de `main` tenga resultado; mínimo privilegio. Un filtro `paths` dejaría el check requerido en "pending" | Equipo |
| Solo actions de primera parte (`actions/checkout`, `actions/cache`), fijadas por el SHA completo del commit con la versión en un comentario; `persist-credentials: false` | Reducir la superficie de cadena de suministro: una etiqueta puede moverse, un SHA no. Los SHA se obtuvieron de la API pública de GitHub (ver [verification.md](assurance/verification.md#integración-continua-github-actions)) | Equipo |
| Flutter sin action de terceros: `git clone --depth 1 --branch 3.47.4` y verificación de que `HEAD` es `9584c6713b324636289d067944a46fd6b49df14b` (también cuando la caché acierta); versión y commit en el `env` del workflow | Fijar el SDK por commit y no por una etiqueta; un único sitio donde actualizarlo. Limitación: la verificación comprueba el repositorio Git del SDK, no el contenido de `bin/cache` | Equipo |
| `flutter pub get --enforce-lockfile` | Que el CI falle si `pubspec.lock` cambiaría, en vez de resolver dependencias distintas de las versionadas | Equipo |
| Cada comprobación es un paso independiente con nombre propio y se ejecuta aunque falle una anterior (si la instalación fue bien) | Que cada resultado quede visible en una sola ejecución | Equipo |
| ~~`concurrency` por workflow y referencia (`group: workflow-ref`); `cancel-in-progress` solo en pull requests~~ **Sustituida** | Se descubrió que, por defecto, GitHub sustituye la ejecución *pendiente* de un mismo grupo aunque `cancel-in-progress` sea falso: varios pushes seguidos a `main` podían dejar commits intermedios sin ejecución, lo que contradecía el objetivo de que cada commit de `main` lo verifique un tercero. Triaje: hallazgo **bloqueante** | Equipo |
| `concurrency`: grupo `workflow-ref` en pull requests y `workflow-SHA` en pushes (`group: ${{ github.workflow }}-${{ github.event_name == 'pull_request' && github.ref || github.sha }}`); `cancel-in-progress: ${{ github.event_name == 'pull_request' }}` | En un pull request, una ejecución nueva cancela la anterior (obsoleta). Cada push a `main` tiene su propio grupo, así que no compite con otros y ninguna ejecución de `main` se cancela ni se sustituye. Según la documentación de GitHub, los límites de ejecución y de pendientes se aplican por grupo de concurrencia, y una expresión de grupo en el nivel de workflow puede usar el contexto `github` (`github.sha`, `github.event_name`, `github.ref`). Que dos grupos distintos no interfieran se deduce de esa regla; no se ha observado en GitHub | Equipo (corrección del hallazgo). Estado: **Verified** en la revalidación independiente del code-reviewer, contra la documentación oficial y **sin observación en GitHub** |
| `flutter build ios` queda **fuera** del CI (posible job futuro) | Requiere macOS; en repositorios privados cuesta más por minuto ($0.062 frente a $0.006 de Linux de 2 núcleos, según la documentación de GitHub) y el build ya tiene evidencia local | Equipo |
| Cambio de política en `project-assurance.json`: `.github/**` en `paths.production` y `.github/workflows/**` en `review_triggers.dependencies` | Que cada archivo caiga en exactamente una categoría, que los cambios en workflows exijan revisión de código y que las actions fijadas cuenten como dependencias. **Aprobado por el usuario en el chat el 2026-10-14** (ver [Decisiones del usuario](#decisiones-del-usuario)); esa aprobación es una decisión humana registrada, no una atestación. Sigue sin existir un evento de aprobación firmado por un emisor independiente ni la transición formal (`approved_policy_transition_sha256`), y el gate formal sigue en `BLOCKED_ENVIRONMENT` | Equipo (propuesta); aprobación del usuario (chat) |

## Qué hacer cuando cambia una decisión

1. Registra la nueva decisión aquí, y marca la anterior como sustituida (no la borres).
2. Si afecta al comportamiento, actualiza el contrato; si cambia el contrato humano, hay que recalcular `contract_sha256`, actualizar el inventario y pedir una nueva aprobación (ver [assurance/verification.md](assurance/verification.md)).
3. Marca como obsoleta (`STALE`) la evidencia que la decisión invalide y repite las comprobaciones afectadas.
