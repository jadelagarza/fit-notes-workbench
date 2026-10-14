# Verificación y assurance

Explica qué es cada artefacto de assurance del proyecto, qué evidencia debe producir un cambio, cómo ejecutar las comprobaciones existentes y qué sigue requiriendo criterio humano. Las reglas provienen del workbench `engineering-assurance` (rutas del workbench: `engineering-assurance/ORCHESTRATOR_CONTRACT.md` y `engineering-assurance/README.md`; no son enlaces relativos porque este proyecto puede copiarse a otro lugar). Para aplicarlo a otro proyecto, ver [../replication-guide.md](../replication-guide.md).

## Artefactos

| Artefacto | Qué es |
| --- | --- |
| [`.engineering-assurance/project-assurance.json`](../../.engineering-assurance/project-assurance.json) | Configuración versionada del proyecto: categorías de rutas (`production`, `tests`, `assurance`, `other`), ubicación del contrato, patrones que disparan la revisión de dependencias, comandos de comprobación y capacidades requeridas (las que el preflight debe acreditar). Su existencia hace que todo cambio futuro se coordine como **certificación formal** (ver más abajo) |
| [`AGENTS.md`](../../AGENTS.md) | Instrucciones para agentes: entrada obligatoria por `engineering-orchestrator` para cambios de producción o de comportamiento, fuentes que leer y reglas del repositorio |
| [`docs/quality-contracts/login.md`](../quality-contracts/login.md) | Quality Contract: **qué debe hacer** el inicio de sesión (LOGIN-01 a LOGIN-36), con procedencia por requisito. Estado: procedencia confirmada y propuestas aceptadas en el chat el 2026-10-14; **sin aprobación formal atestada** |
| [`docs/quality-contracts/login.inventory.json`](../quality-contracts/login.inventory.json) | Inventario de los requisitos **HUMAN** (solo LOGIN-01 a LOGIN-03): ID, pasaje literal y `contract_sha256` |
| [`docs/quality-contracts/login.proposed-requirements.json`](../quality-contracts/login.proposed-requirements.json) | Requisitos **AGENT-PROPOSED** (LOGIN-04 a LOGIN-36). Estado `ACCEPTED_BY_USER_IN_CHAT_NOT_ATTESTED`: la persona los aceptó en el chat el 2026-10-14; esa aceptación no es una aprobación atestada y no los convierte en HUMAN |
| [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) | Workflow de GitHub Actions que repite las comprobaciones deterministas en un runner de GitHub (ver [Integración continua](#integración-continua-github-actions)). Nunca se ha ejecutado en GitHub |
| `test/**` | Las comprobaciones ejecutables: pruebas unitarias, de widget, de composición (`test/app_test.dart`) y de arquitectura (`test/architecture/`) |

### Por qué el inventario contiene solo requisitos HUMAN

`validate_bundle.py` (del workbench) exige que el inventario coincida **exactamente** con los requisitos HUMAN activos de la trazabilidad, y que cada pasaje aparezca literal en el contrato. Si LOGIN-04 a LOGIN-36 se incluyeran en el inventario, habría que etiquetarlos como HUMAN y se falsearía su procedencia: los derivaron o propusieron los agentes, y la persona confirmó en el chat (2026-10-14) que el conjunto HUMAN es solo LOGIN-01 a LOGIN-03. Aceptar las propuestas en el chat no cambia su procedencia: siguen siendo AGENT-PROPOSED, viven en `login.proposed-requirements.json` y no entran en el inventario. Esa aceptación es una decisión humana registrada, no una atestación; la aprobación formal del contrato y del inventario sigue sin existir. Una propuesta solo pasaría al inventario si una persona la adoptara expresamente como suya (por ejemplo, porque la pide literalmente), conservando el historial de origen.

### Regla de la persona sobre las pruebas HUMAN y las propuestas

La persona fijó esta regla en el chat el 2026-10-14:

- Las pruebas **HUMAN se respetan siempre**: no se debilitan, no se eliminan y no se reinterpretan, aunque se agreguen otros casos.
- Los agentes pueden **proponer escenarios adicionales** cuando lo vean necesario, con procedencia **AGENT-PROPOSED**.
- **Solo es HUMAN lo que la persona pidió literalmente.** Lo que derivan los agentes de la petición es AGENT-PROPOSED aunque parezca obvio. En FitNotes la petición literal es "Valida correo no vacío y con formato válido, y contraseña no vacía", que da LOGIN-01, LOGIN-02 y LOGIN-03.

### Cómo se calculan los hashes

`contract_sha256` es el SHA-256 de los **bytes** de `login.md`. Cualquier cambio de un byte lo invalida.

```bash
shasum -a 256 docs/quality-contracts/login.md      # macOS; en Linux: sha256sum
```

El resultado debe coincidir con `contract_sha256` de `login.inventory.json` y de `login.proposed-requirements.json`. Comprobación hecha el 2026-10-14: coinciden (`ef9d4cda…e8e3`), y cada pasaje del inventario aparece como línea literal de `login.md`.

Si cambias `login.md`: recalcula el hash en ambos JSON, revisa los pasajes y **pide una nueva aprobación**; ninguna aprobación anterior cubre bytes nuevos.

## Evidencia que debe producir un cambio

Antes de planificar, el orquestador decide si el trabajo es **ordinario** o **formal**. Aquí es **formal** en cuanto existe `.engineering-assurance/project-assurance.json` en la base. Sin un operador independiente (ver abajo), el gate formal queda en `BLOCKED_ENVIRONMENT`; ningún agente puede convertirlo en trabajo ordinario.

| Evidencia / criterio | Trabajo ordinario | Certificación formal |
| --- | --- | --- |
| Estado de código | `HEAD` y, si hay cambios sin commit, `git diff` o hashes de los archivos relevantes | `HEAD` final con checkout limpio, base aprobada y diff Git base→`HEAD` |
| Comportamiento | Petición, código y documentación vigentes; el contrato ayuda pero no es obligatorio | Quality Contract humano + inventario aprobado por una persona (evento externo) |
| TDD | RED por **aserción** (no error de compilación, importación o entorno) y GREEN, por rebanada de comportamiento | RED/GREEN registrados por un ejecutor independiente (comando, salida, commit, `failure_kind=ASSERTION`) |
| `flutter analyze` y `flutter test` | En verde, con comando y salida reales | En verde, observados por el ejecutor |
| Test de arquitectura | `flutter test test/architecture` en verde | Ídem |
| Revisiones independientes | Según el riesgo: code, security, dependencies | Las derivadas de clasificación, superficies y diff real |
| Hallazgos | Cada uno clasificado como **bloqueante** o **mejora no bloqueante**. Bloqueantes en cero; revalidados por un verificador distinto de quien corrigió | Todo hallazgo bloqueante abierto bloquea el PASS; quien corrige no cierra su propio hallazgo |
| Lenguaje de evidencia | `Verified` / `Likely` / `Unverified` / `Failed`, y `VALID` / `STALE` / `SUPERSEDED` | Igual; `Likely` no satisface un gate material REQUIRED |
| Conclusión | Informe de alcance, decisiones, verificaciones, hallazgos, pendientes y backlog. **Nunca `PASS` global** | `ASSURANCE_PASS` solo lo emite el gate externo, con bundle y atestación del operador |

Reglas que aplican siempre:

- Un resultado `Verified` está respaldado por código inspeccionado o por un comando que realmente se ejecutó. Una ejecución que no ocurrió es `Unverified`, no `Likely`.
- Si cambia el código, la especificación o el plan, evalúa qué evidencia deja de ser vigente: márcala `STALE` y repite lo invalidado.
- Una verificación material fallida, pendiente o no observada impide declarar verificación completa; se entrega con pendientes explícitos.
- Un bug se corrige donde está su causa (especificación, diseño, implementación, pruebas o entorno). No se cambia una expectativa de negocio sin autoridad humana, ni se debilita una prueba para acomodar el código.

## Comprobaciones existentes

Comandos declarados en `project-assurance.json` (`checks`) y otros usados en el desarrollo. Ejecútalos desde la raíz del proyecto.

| Comprobación | Comando | Qué demuestra | Estado en el desarrollo (2026-10-14) |
| --- | --- | --- | --- |
| Formato (comprobación) | `dart format --output=none --set-exit-if-changed lib test` | Que el código ya está formateado: no escribe archivos y sale con código distinto de 0 si algún archivo cambiaría | Ejecutado: exit 0, "0 changed" |
| Análisis estático | `flutter analyze` | Sin errores ni avisos del analizador | Ejecutado: "No issues found!" |
| Pruebas | `flutter test` | Suite completa | Ejecutado: todas pasan, ninguna omitida |
| Arquitectura | `flutter test test/architecture` | Dirección de dependencias entre capas | Ejecutado: pasa |
| Dependencias | `flutter pub deps` | Árbol de dependencias (disparador de la revisión de dependencias: `pubspec.yaml`, `pubspec.lock`, `*.gradle*`, `ios/Podfile*` y, con el cambio de política aprobado en el chat pero sin atestar, `.github/workflows/**`) | Ejecutado: exit 0 (lo ejecutaron el revisor de dependencias y el orquestador) |
| Compilación iOS | `flutter build ios --simulator --debug` | Que la app compila para el simulador | Ejecutado: exit 0, `✓ Built build/ios/iphonesimulator/Runner.app`. Solo compila; no instala ni ejecuta la app |

Nota sobre el hallazgo F-01: el test-engineer independiente lo descubrió con una prueba condicionada (`--dart-define=RUN_KNOWN_FINDINGS=true`) para conservar la evidencia del fallo sin romper la suite. Tras la corrección y su revalidación independiente, quitó la condición: la prueba forma parte de la suite normal. Es el patrón recomendado para un hallazgo abierto: evidencia fallida reproducible, corrección por otra persona y revalidación por quien lo descubrió.

No cuentes pruebas en esta documentación: el número cambia con cada commit. Para saber el número actual, ejecuta `flutter test` y lee su salida. Qué cubre cada archivo está en [../architecture.md](../architecture.md#cómo-se-prueba-cada-capa).

Estado de código de esa evidencia: los resultados de esta tabla son **históricos del repositorio de origen** (`/Users/Alfredo/Desktop/fit-notes`): se obtuvieron sobre el árbol de trabajo que constituyó su commit inicial `79e15ee`. Esa historia no existe en este repositorio, donde el commit inicial es `774d5af` ("chore: creación del repositorio", solo `README.md`) y el proyecto llega en un commit posterior de la rama `feat/importar-proyecto-fit-notes` (commit de importación). Aquí la evidencia se repite sobre el commit de importación, y su SHA se informa fuera del repositorio (un commit no puede contener su propio SHA); hasta que se repita, los resultados de la tabla no están asociados a ningún `HEAD` de este repositorio. En cambios posteriores, asocia la evidencia al `HEAD` y, con cambios sin commit, a hashes de archivo, por ejemplo:

```bash
git ls-files -z -co --exclude-standard | xargs -0 shasum -a 256 | shasum -a 256
```

### Herramientas del workbench (solo configuración y preflight)

Se ejecutaron en el repositorio de origen, desde la raíz del workbench (no desde este proyecto) con un entorno virtual efímero de Python 3.9.6 con `jsonschema` 4.23.0 y `cryptography` 46.0.7. **Limitación**: el workbench documenta Python 3.11 o posterior y no había otra versión instalada. Los ejecutó el orquestador; esta documentación recoge sus resultados y no los ha reproducido.

Registro histórico de lo ejecutado, con las rutas absolutas del repositorio de origen (`/Users/Alfredo/Desktop/fit-notes`). Quien replique (o repita esto en este repositorio) sustituye esa ruta por `<raíz del proyecto>`; la forma genérica va después del registro.

```bash
python engineering-assurance/tools/project_doctor.py /Users/Alfredo/Desktop/fit-notes
# PASS: configuración estática mínima de Engineering Assurance presente
# UNVERIFIED: capacidades dinámicas del runtime ...        (exit 0)

python engineering-assurance/tools/runtime_preflight.py /Users/Alfredo/Desktop/fit-notes \
  --config /Users/Alfredo/Desktop/fit-notes/.engineering-assurance/project-assurance.json \
  --work-id FIT-NOTES-INIT --output <ruta externa>/runtime-preflight.json
# BLOCKED_ENVIRONMENT: multi_agent                          (exit 1)
```

Forma genérica, sin ejecutar en este repositorio:

```bash
python engineering-assurance/tools/project_doctor.py <raíz del proyecto>

python engineering-assurance/tools/runtime_preflight.py <raíz del proyecto> \
  --config <raíz del proyecto>/.engineering-assurance/project-assurance.json \
  --work-id <id de trabajo> --output <ruta externa>/runtime-preflight.json
```

- El `PASS` de `project_doctor.py` acredita **solo la configuración estática** (configuración, `AGENTS.md` y presencia del Quality Contract). No acredita calidad, capacidades del runtime ni aprobación.
- En el preflight, `workspace_write`, `git` y `tests` quedaron `AVAILABLE`; `multi_agent` y el resto, `UNAVAILABLE`, porque requieren atestación firmada por un ejecutor externo. Una cadena escrita por el operador no las demuestra.
- El bloqueo se debe a que `project-assurance.json` declara `multi_agent: true` (capacidad requerida) y sin esa atestación el preflight no puede observarla como `AVAILABLE`. Las capacidades en `false` (por ejemplo `device_simulator`) significan "no requeridas", no "no disponibles".
- `assurance_gate.py` **no se ejecutó**: no hay operador, bundle ni clave. `validate_bundle.py`, cuando se ejecuta, solo informa `CONSISTENT`, que no es el `PASS` del gate.
- En trabajo ordinario el workbench no pide ejecutar `project_doctor.py` ni `runtime_preflight.py` por defecto.

## Integración continua (GitHub Actions)

El workflow [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) (`name: CI`, un único job `checks`) ejecuta las comprobaciones deterministas del proyecto en `ubuntu-24.04`. Su objetivo es que las ejecute un tercero (GitHub) sobre un commit concreto y que el resultado no dependa de lo que informe un agente.

### Cuándo se ejecuta

- `pull_request` con destino `main` y `push` a `main`. No usa `pull_request_target`, no usa secretos ni tokens y declara `permissions: contents: read`.
- No tiene filtros `paths`: según la documentación de GitHub, un workflow omitido por filtro deja su check requerido en "pending" y bloquea el merge (ver [../replication-guide.md](../replication-guide.md#10-exigir-el-check-en-main-con-un-ruleset-pasos-manuales)).
- `concurrency`: en pull requests el grupo es workflow más referencia y una ejecución nueva cancela la anterior; en pushes a `main` el grupo es workflow más SHA del commit, de modo que cada commit de `main` tiene su propio grupo y ninguna ejecución se cancela ni se sustituye. Motivo: GitHub sustituye por defecto la ejecución **pendiente** de un mismo grupo aunque `cancel-in-progress` sea falso (ver [../decisions.md](../decisions.md#integración-continua-ci)). Que los grupos por SHA no interfieran entre sí se deduce de la documentación y no se ha observado en GitHub.

### Qué acredita y qué no

Acredita: que los comandos de la tabla se ejecutaron en un runner de GitHub sobre un commit concreto y terminaron con el resultado que muestran sus logs, visibles en la pestaña Actions. Es evidencia determinista de ejecución, independiente del informe de un agente.

**No** acredita:

- aprobación humana del contrato, del inventario ni de los requisitos;
- independencia de los agentes ni revisión de código, seguridad o dependencias;
- la firma Ed25519, el bundle, el operador independiente ni el gate: **no produce `ASSURANCE_PASS`**;
- el comportamiento en plataforma o runtime: no compila iOS ni Android, ni ejecuta la app en simulador o dispositivo;
- que las pruebas cubran el contrato (el CI solo ejecuta las que existen);
- que el job `checks` siga ejecutando lo previsto: los checks requeridos de GitHub se identifican por nombre y no por workflow ni por evento, y un pull request puede modificar `.github/workflows/ci.yml` o añadir otro workflow con un job `checks` (riesgo residual del ruleset descrito en [../replication-guide.md](../replication-guide.md#10-exigir-el-check-en-main-con-un-ruleset-pasos-manuales); en una cuenta personal no se dispone de "Require workflows to pass before merging" a nivel de organización).

### Pasos

El orden y los comandos de los pasos 7 a 12 son los que se ejecutaron en local. Desde la instalación, cada comprobación se ejecuta aunque falle una anterior (siempre que la instalación haya ido bien), para que cada resultado quede visible.

| # | Paso | Comando | Relación con `checks` |
| --- | --- | --- | --- |
| 1 | Obtener el código | `actions/checkout` (con `persist-credentials: false`) | — |
| 2 | Caché del SDK de Flutter | `actions/cache`, clave basada en el commit de Flutter | — |
| 3 | Clonar Flutter (solo si la caché no acierta) | `git clone --depth 1 --branch 3.47.4 https://github.com/flutter/flutter.git` | — |
| 4 | Verificar el commit del SDK (siempre, también con caché) | `git rev-parse HEAD` debe ser `9584c6713b324636289d067944a46fd6b49df14b`; si no, falla | — |
| 5 | Añadir Flutter al `PATH`, desactivar analítica y mostrar versión | `flutter --disable-analytics`, `flutter --version` | — |
| 6 | Caché de pub | `actions/cache` sobre `~/.pub-cache`, clave con `hashFiles('pubspec.lock')` y el commit de Flutter | — |
| 7 | Instalar dependencias | `flutter pub get --enforce-lockfile` (falla si `pubspec.lock` cambiaría) | — |
| 8 | Formato | `dart format --output=none --set-exit-if-changed lib test` | No está en `checks`; es una comprobación usada desde el desarrollo |
| 9 | Análisis estático | `flutter analyze` | `checks.analyze` |
| 10 | Pruebas | `flutter test` | `checks.test` |
| 11 | Arquitectura | `flutter test test/architecture` | `checks.architecture` |
| 12 | Dependencias | `flutter pub deps` | `checks.dependency_validation` |

Las dos actions son de primera parte (`actions/checkout` v7.0.1 y `actions/cache` v6.1.0) y están fijadas por el SHA completo de su commit; la versión queda en un comentario. La versión y el commit de Flutter están en el `env` del workflow, único sitio donde se actualizan.

Limitación de la verificación del paso 4: comprueba el commit del repositorio Git del SDK, también cuando la caché acierta; no comprueba el contenido de los artefactos ya descargados en `bin/cache`.

**Fuera del workflow: `checks.build`** (`flutter build ios --simulator --debug`). Requiere macOS y ya tiene evidencia local (ver la tabla de comprobaciones). Queda como posible job futuro. Motivo de coste: en repositorios privados los minutos consumen la cuota de la cuenta, y la documentación de GitHub publica tarifas por minuto de $0.062 para macOS (3 o 4 núcleos) frente a $0.006 para Linux de 2 núcleos (ver [../replication-guide.md](../replication-guide.md#fuentes-consultadas)). Esas páginas ya no publican un multiplicador, y aquí no se afirma ninguno.

### Estado

**No ejecutado en GitHub todavía**: el remoto `origin` (`https://github.com/jadelagarza/fit-notes-workbench.git`) está configurado en este repositorio, pero al redactar esto no se ha hecho ni intentado ningún push, así que GitHub no ha visto el workflow. Lo verificado hasta ahora (2026-10-14, en el repositorio de origen):

- Los comandos de los pasos 7 a 12 se ejecutaron en local, en ese orden, con exit 0, usando el SDK local (Flutter 3.47.4, commit `9584c6713b…`). Eso no demuestra que el workflow funcione en el runner.
- El YAML se parseó con Ruby y cada `uses:` apunta a un SHA de 40 caracteres hexadecimales que existe en la API pública de GitHub.
- `actionlint` no forma parte de las comprobaciones del proyecto ni está instalado. Un revisor lo ejecutó una vez (v1.7.12, con el binario descargado al directorio temporal de trabajo sin la autorización prevista y sin `shellcheck`) y no informó errores. Ese resultado **no se considera evidencia acreditada**.
- No verificado: la clonación y las cachés en el runner, los tiempos y el límite de 20 minutos, y que `ubuntu-24.04` tenga todo lo que Flutter necesita (la definición de la imagen instala `curl`, `unzip`, `zip`, `xz-utils` y `file`; no se comprobó nada más).

### Política de assurance para el CI: aprobada en el chat, sin atestación

Para que `.github/workflows/ci.yml` quede cubierto por la política del workbench, `project-assurance.json` cambia así:

| Campo | Cambio |
| --- | --- |
| `paths.production` | Se añade `.github/**` |
| `review_triggers.dependencies` | Se añade `.github/workflows/**` |

Motivo, según `validate_bundle.py` del workbench:

- **Cada archivo en exactamente una categoría.** Para cada ruta cambiada, el validador exige exactamente una categoría de `paths` (con `fnmatch`); con 0 o más de 1 informa `UNCATEGORIZED_CHANGED_PATH`. Comprobado en el repositorio de origen con la configuración de su `HEAD` `79e15ee` (sin el cambio): `.github/workflows/ci.yml` no cae en ninguna categoría; con el cambio, cae solo en `production`.
- **Revisión de código.** Si el diff toca una ruta `production`, el validador exige `code-reviewer` entre los agentes ejecutados. Además, un handoff con rol `ASSURANCE` o `ARCHITECTURE` que modifique rutas de producción produce `ASSURANCE_MODIFIED_PRODUCTION`: el workflow debe implementarlo un rol que no sea de assurance.
- **Las actions fijadas cuentan como dependencias.** Si el diff toca una ruta de `review_triggers.dependencies`, el validador exige `dependencies-reviewer` con requisito `REQUIRED`.
- **Transición de política.** Si la configuración de la base difiere de la del commit final, el validador exige `approved_policy_transition_sha256` en los datos acreditados por el emisor independiente: el SHA-256 de `{base_sha, head_sha, before, after}` (la configuración antes y después). Sin él informa `PROJECT_CONFIG_CHANGE_UNAPPROVED`. Como incluye `base_sha` y `head_sha`, una aprobación previa no cubre commits posteriores.

**Estado: aprobada por el usuario en el chat el 2026-10-14; no atestada.** El usuario aprobó en el chat este cambio de `project-assurance.json` (ver [Decisiones del usuario](../decisions.md#decisiones-del-usuario)). Es una decisión humana registrada, **no una atestación**. Sigue sin existir:

- un evento de aprobación firmado por un emisor independiente;
- la transición formal (`approved_policy_transition_sha256`): no se ha calculado ni se ha acreditado ninguna en este repositorio;
- un gate formal en verde: sigue en `BLOCKED_ENVIRONMENT`.

El cambio figura en el `project-assurance.json` que se importa a este repositorio (la base `main` de este repositorio no contiene ese archivo, así que el commit de importación lo introduce entero). Esta aprobación no es un `PASS` ni un `ASSURANCE_PASS`: nadie debe declararlos mientras el gate siga en `BLOCKED_ENVIRONMENT`.

## Consecuencia: los cambios futuros son certificación formal

Con `project-assurance.json` versionado, todo cambio futuro parte de una base que lo contiene y se coordina como **certificación formal** (lo recoge también [AGENTS.md](../../AGENTS.md)). Sin un **operador independiente** (clave Ed25519 externa, runner protegido y eventos autenticados; ver `engineering-assurance/docs/OPERADOR_INDEPENDIENTE.md` del workbench), el gate queda en `BLOCKED_ENVIRONMENT`. Eso no impide implementar ni probar: impide declarar el `PASS` formal. Este proyecto se creó mediante trabajo ordinario, que no certifica el estado actual.

## Qué reduce la revisión humana, y qué no

Reduce la revisión línea a línea: la persona revisa **el contrato, el inventario y la evidencia** (comandos, salidas, hallazgos y su revalidación) en lugar de cada línea de código.

Sigue requiriendo criterio humano:

- **Aprobar el contrato y el inventario** (LOGIN-01 a LOGIN-03), con un evento registrado fuera del control de los agentes. La confirmación de procedencia y la aceptación de las propuestas en el chat no lo sustituyen.
- **Atestar la aceptación de los requisitos AGENT-PROPOSED** LOGIN-04 a LOGIN-36. La persona ya los aceptó en el chat el 2026-10-14; falta el evento firmado por un emisor independiente.
- **Revisar el diff de `.github/**` antes de fusionar** cualquier pull request que lo toque: es la mitigación del riesgo anterior (un pull request puede redefinir el check `checks`) y coincide con tratar esa ruta como producción. Aunque la política está aprobada en el chat, sin la transición formal ni el gate sigue siendo una práctica recomendada y no un control técnico.
- **Atestar el cambio de política** que añade `.github/**` a `paths.production` y `.github/workflows/**` a `review_triggers.dependencies`. El usuario ya lo aprobó en el chat (ver [la política de assurance para el CI](#política-de-assurance-para-el-ci-aprobada-en-el-chat-sin-atestación)); falta el evento de aprobación firmado por el emisor independiente y la transición formal (`approved_policy_transition_sha256`).
- **El operador independiente, la firma y el gate** (provisionar clave, base, emisor y runner protegido).
- **La validación en runtime** en un dispositivo o simulador: las pruebas de widget no sustituyen ejecutar la aplicación (la superficie PLATFORM no se ejecutó).
- **Las decisiones de producto** (por ejemplo, qué textos mostrar o si el mock debe existir en release).
- **La exhaustividad semántica del inventario**: el validador comprueba coincidencia mecánica de IDs y pasajes, no que el inventario cubra todo lo que el contrato promete.
