# Guía de replicación

Cómo llevar a **otro proyecto Flutter**, nuevo o existente, la estructura de código y la preparación de assurance de FitNotes. Todo lo descrito existe en este repositorio; los comandos se verificaron contra él, salvo los marcados como "no ejecutado". Las referencias al workbench son rutas dentro de su repositorio (`engineering-assurance/...`), no enlaces relativos, para que no se rompan al copiar esta guía.

Lecturas previas: [../README.md](../README.md), [architecture.md](architecture.md) y [assurance/verification.md](assurance/verification.md).

## 1. Qué copiar y qué adaptar

| Elemento | Origen en FitNotes | ¿Copiar tal cual? | Qué adaptar |
| --- | --- | --- | --- |
| Estructura *feature-first* con `domain`/`data`/`presentation` y `app.dart` como raíz de composición | `lib/` | Sí, como patrón | Nombres de feature y de clases |
| Test de arquitectura | `test/architecture/layer_dependencies_test.dart` | Casi: copia el archivo | Constantes `_packageName`, `_mockRepositoryPath` y `_compositionRoot`; la regla 4 ("solo la raíz conoce la implementación simulada"); `_layerOf` si tu estructura no es `features/<f>/domain\|data\|presentation`; los tests de autocomprobación que mencionan `fit_notes` y `MockAuthRepository` |
| `.engineering-assurance/project-assurance.json` | raíz del proyecto | No | Nombre, rutas, comandos y capacidades (sección 5) |
| `AGENTS.md` | raíz del proyecto | Plantilla | Rutas de producción, fuentes a leer y reglas propias |
| Quality Contract | `docs/quality-contracts/login.md` | No: es el de login | Redáctalo con la plantilla del workbench (sección 3) |
| Inventario | `login.inventory.json` | No | Un inventario por contrato, con su hash |
| `analysis_options.yaml` | raíz | Sí | Nada: es **el que genera `flutter create`** (Flutter 3.47.4), sin cambios. Contiene `include: package:flutter_lints/flutter.yaml`, `analyzer.exclude` con `build/**`, `android/**` e `ios/**` (el analizador no revisa esas carpetas) y un bloque `linter.rules` vacío con comentarios. Se comprobó que es idéntico, byte a byte, al de un proyecto generado con los mismos argumentos. Si tu proyecto añade carpetas con código Dart propio fuera de `lib/` y `test/`, revisa si la exclusión te conviene |
| Workflow de CI | `.github/workflows/ci.yml` | Casi: copia el archivo | Versión y commit de Flutter, SHAs de las actions, comandos de `checks` y rama (sección 9) |
| Documentación (`README`, `docs/architecture.md`, `docs/decisions.md`, `docs/assurance/verification.md`) | `docs/` | Como esqueleto | Contenido del proyecto; verifica cada comando antes de afirmarlo |

## 2. Estructura de código y pruebas

1. Crea `lib/features/<feature>/{domain,data,presentation}/` y una raíz de composición `lib/app.dart`; `lib/main.dart` solo llama a `runApp`.
2. Respeta la dirección de dependencias: `domain` no importa Flutter, `data` ni `presentation`; `data` solo importa `domain`; `presentation` no importa `data`; solo `app.dart` conoce la implementación concreta del repositorio.
3. Replica la estructura de `lib/` bajo `test/` (`test/features/<feature>/...`).
4. Escribe cada rebanada de comportamiento con TDD: esqueleto compilable, test, RED **por aserción** (no por compilación), implementación mínima, GREEN, refactor.
5. En pruebas de widget, usa un repositorio doble con `Completer` para observar la carga y contar llamadas, y el repositorio simulado con latencia cero para el flujo de extremo a extremo.

### Añadir el test de arquitectura

1. Copia `test/architecture/layer_dependencies_test.dart` a tu proyecto.
2. Ajusta `_packageName` (nombre en `pubspec.yaml`), `_mockRepositoryPath` y `_compositionRoot`.
3. Ejecútalo desde la raíz del paquete (lee `lib/` con rutas relativas):

   ```bash
   flutter test test/architecture
   ```

4. Comprueba que **detecta** una infracción: añade temporalmente un import prohibido (por ejemplo, `domain` importando `package:flutter/material.dart`), confirma que falla con el archivo y el import infractor, y retíralo. Las pruebas de autocomprobación del propio archivo cubren esto con fuentes sintéticas, pero conviene verlo una vez en tu código.

Las reglas están codificadas en el test, no inferidas: si cambias tus capas, cambia el test.

## 3. Redactar el Quality Contract y su inventario

1. Parte de la plantilla del workbench `engineering-assurance/templates/QUALITY_CONTRACT.md` y de su guía `engineering-assurance/docs/QUALITY_CONTRACT_GUIDE.md`. Guárdalo en `docs/quality-contracts/<feature>.md` (o la ubicación que declares en `quality_contract.locations`).
2. Describe **qué debe hacer** el sistema, no cómo: objetivo, comportamiento esperado, reglas de negocio, invariantes, pruebas con ID estable (`FEATURE-01`...), casos de error conocidos, fuera de alcance, decisiones pendientes y glosario. No fijes riesgo, TDD, superficies ni diseño de clases: eso es decisión técnica.
3. Marca la **procedencia** de cada requisito: `HUMAN` (lo pidió la persona literalmente) o `AGENT-PROPOSED` (lo derivó o propuso un agente; hasta que una persona lo acepte, está pendiente). No etiquetes como HUMAN lo que una persona no pidió literalmente, aunque parezca obvio. Aplica la regla de la persona (ver más abajo).
4. En cada prueba HUMAN, la primera oración tras el título es el **pasaje literal** que se cita en el inventario. No lo reformules después.
5. Crea el inventario `docs/quality-contracts/<feature>.inventory.json` solo con los requisitos HUMAN:

   ```json
   {
     "schema_version": "1.0",
     "contract_sha256": "<sha256 de los bytes del contrato>",
     "requirements": [
       { "requirement_id": "FEATURE-01", "excerpt": "<oración literal del contrato>" }
     ]
   }
   ```

6. Calcula el hash y comprueba cada pasaje:

   ```bash
   shasum -a 256 docs/quality-contracts/<feature>.md          # macOS; en Linux: sha256sum
   grep -Fxq "Un intento de inicio de sesión con el correo vacío se rechaza con un error de validación del correo." \
     docs/quality-contracts/<feature>.md && echo "pasaje literal OK"
   ```

   Para comprobarlos todos de una vez (verificado en este proyecto con `login.inventory.json`):

   ```bash
   python3 - <<'PY'
   import json, hashlib
   inv = json.load(open("docs/quality-contracts/<feature>.inventory.json"))
   text = open("docs/quality-contracts/<feature>.md", encoding="utf-8").read()
   print("hash coincide:", inv["contract_sha256"] == hashlib.sha256(text.encode()).hexdigest())
   lines = text.split("\n")
   for r in inv["requirements"]:
       print(r["requirement_id"], "literal" if r["excerpt"] in lines else "NO ENCUENTRO EL PASAJE")
   PY
   ```

7. Guarda los requisitos AGENT-PROPOSED aparte (en FitNotes, `login.proposed-requirements.json`: `provenance: AGENT-PROPOSED`, mismo `contract_sha256` y un `status` que refleje el estado real: `PENDING_HUMAN_APPROVAL` mientras nadie los acepte; `ACCEPTED_BY_USER_IN_CHAT_NOT_ATTESTED` con `accepted_on` desde que la persona los aceptó en el chat, 2026-10-14, sin evento firmado). Aceptar una propuesta no la convierte en HUMAN ni la mueve al inventario: conserva su procedencia.
8. Si cambias el contrato: recalcula el hash en todos los JSON, revisa los pasajes y vuelve a pedir aprobación. Una aprobación anterior no cubre bytes nuevos.

Un hash comprueba bytes; no acredita autoría ni que el inventario cubra todo el contrato. Eso lo revisa una persona.

### Regla de la persona sobre las pruebas HUMAN y las propuestas

En FitNotes la persona la fijó en el chat el 2026-10-14. Replícala como política del contrato:

- Las pruebas **HUMAN se respetan siempre**: no se debilitan, no se eliminan y no se reinterpretan, aunque se agreguen otros casos.
- Los agentes pueden **proponer escenarios adicionales** cuando lo vean necesario, con procedencia **AGENT-PROPOSED**.
- **Solo es HUMAN lo que la persona pidió literalmente.** Lo que derivan los agentes es AGENT-PROPOSED aunque parezca obvio.

**Lección aprendida (FitNotes).** Al principio se etiquetaron como HUMAN doce requisitos (LOGIN-01 a LOGIN-12), pero solo tres eran lo que la persona pidió ("Valida correo no vacío y con formato válido, y contraseña no vacía"). Los otros nueve (éxito y error reproducibles, usuario identificado, estados de carga, de éxito y de error, sin backend, documentación de escenarios y comprobaciones automatizadas) eran reformulaciones de los agentes. La persona corrigió la procedencia: HUMAN es solo LOGIN-01 a LOGIN-03 y LOGIN-04 a LOGIN-36 son AGENT-PROPOSED, que aceptó en el chat. Para evitarlo, antes de etiquetar un requisito como HUMAN pregunta si la persona lo pidió con esas palabras; si lo dedujo un agente, es AGENT-PROPOSED. Corregir la procedencia cambia los bytes del contrato: hubo que recalcular `contract_sha256` en el inventario y en el archivo de propuestos, y ninguna aprobación anterior cubría los bytes nuevos.

## 4. Aprobar: solo una persona, con evento externo

Ningún agente puede aprobar el contrato, el inventario ni sus requisitos, y que los archivos estén en Git no es una aprobación. La aprobación es un evento verificable (quién, cuándo, hash aprobado) registrado **fuera del control de los agentes**, por un ejecutor independiente (ver `engineering-assurance/docs/OPERADOR_INDEPENDIENTE.md` del workbench). Mientras tanto, mantén el estado del contrato como "PENDIENTE DE APROBACIÓN HUMANA" (o, si la persona ya confirmó la procedencia y aceptó las propuestas en el chat, como "sin aprobación formal atestada", que es el estado de `docs/quality-contracts/login.md`). No escribas en el contrato IDs de ejecución, firmas ni aprobaciones supuestas.

## 5. Adaptar `project-assurance.json`

Parte de `engineering-assurance/project-assurance.example.json` del workbench y compáralo con `.engineering-assurance/project-assurance.json` de FitNotes. Campos (esquema `schema_version: "1.3"`):

| Campo | Qué poner |
| --- | --- |
| `project` | Nombre del proyecto |
| `entrypoint` | Siempre `engineering-orchestrator` con `required_for_production_changes: true` |
| `paths.production` | Código que cambia comportamiento: en FitNotes `lib/**`, `android/**`, `ios/**`, `pubspec.yaml`, `pubspec.lock` y `.github/**` (este último es un cambio de política que en otro proyecto necesita aprobación humana; en FitNotes lo aprobó el usuario en el chat el 2026-10-14, sin atestación; ver sección 9) |
| `paths.tests` | `test/**`, `integration_test/**` |
| `paths.assurance` | `.engineering-assurance/**` |
| `paths.other` | Todo lo demás versionado: `README.md`, `AGENTS.md`, `docs/**`, `.gitignore`, `.metadata`, `analysis_options.yaml` |
| `quality_contract.locations` | `docs/quality-contracts/*.md` |
| `review_triggers.dependencies` | Patrones que disparan la revisión de dependencias: `pubspec.yaml`, `pubspec.lock`, `**/*.gradle`, `**/*.gradle.kts`, `ios/Podfile`, `ios/Podfile.lock` y `.github/workflows/**` (las actions fijadas cuentan como dependencias; mismo estado de aprobación que `.github/**`: en otro proyecto necesita aprobación humana; en FitNotes, aprobado en el chat y sin atestar) |
| `checks` | Comandos reales: `test`, `build`, `analyze`, `architecture`, `dependency_validation`, y `null` en `performance`, `runtime_validation` y `reliability` si no existen. Todas las claves son obligatorias |
| `capabilities` | Capacidades **requeridas/esperadas** para el trabajo del proyecto, las que el preflight debe acreditar: `true` = requerida; `false` = no requerida (no significa "no disponible"). `multi_agent`, `workspace_write`, `git` y `tests` las exige siempre el validador (`validate_bundle.py`), aunque pongas `false`; además se exige cualquier capacidad que la clasificación del cambio implique. FitNotes declara esas cuatro en `true` y el resto en `false` (por ejemplo, `device_simulator: false` = no se exige acreditar un simulador, aunque la máquina tenga uno) |

**Cada archivo versionado debe caer en exactamente una categoría de `paths`.** El validador del workbench (`validate_bundle.py`) lo exige sobre los archivos que cambian, con `fnmatch` (donde `*` también cruza `/`, de modo que `lib/**` equivale a `lib/*`). Un archivo en ninguna categoría o en dos produce `UNCATEGORIZED_CHANGED_PATH`. Comprobación equivalente, ejecutada sobre FitNotes (los archivos no ignorados cumplían la regla: 0 incumplimientos al escribir esta guía):

```bash
python3 - <<'PY'
import fnmatch, json, subprocess
cfg = json.load(open(".engineering-assurance/project-assurance.json"))
files = [f for f in subprocess.check_output(["git", "ls-files", "-co", "--exclude-standard"]).decode().split("\n") if f]
for f in files:
    cats = [k for k, pats in cfg["paths"].items() if any(fnmatch.fnmatch(f, p) for p in pats)]
    if len(cats) != 1:
        print("revisar:", f, cats)
print(len(files), "archivos comprobados")
PY
```

Si añades carpetas (por ejemplo `web/`, `macos/` o `integration_test/`), añádelas a la categoría que corresponda. Los directorios generados que `.gitignore` excluye (`build/`, `.dart_tool/`, `.idea/`) no cuentan.

Después, desde la raíz del **workbench** (Python 3.11 o posterior y las dependencias de `engineering-assurance/requirements.txt`):

```bash
python3 engineering-assurance/tools/project_doctor.py /ruta/al/proyecto
```

Su `PASS` acredita solo la configuración estática (configuración, `AGENTS.md` y presencia del contrato). Ver los límites en [assurance/verification.md](assurance/verification.md).

## 6. `AGENTS.md`

Declara `engineering-orchestrator` como entrada obligatoria para los cambios de producción y de comportamiento, lista las fuentes a leer (contrato, inventario, requisitos propuestos, configuración y `docs/assurance/verification.md`) y recoge las reglas del repositorio (conservar los requisitos HUMAN, TDD con RED por aserción, mantener las dependencias entre capas, registrar comando, resultado y estado de código, que los checks de `.github/workflows/ci.yml` coincidan con `checks`, y no hacer commits ni cambios globales sin autorización). Usa el de FitNotes como base.

## 7. Proyecto nuevo y proyecto existente

- **Nuevo**: crea el andamiaje con `flutter create`, aplica las secciones 2 a 6 antes de escribir lógica, y empieza cada funcionalidad por su contrato.
- **Existente**:
  1. Documenta primero el comportamiento actual en un contrato (qué hace hoy), sin inventar requisitos ni reescribir el historial.
  2. Añade pruebas de caracterización de lo que ya funciona antes de refactorizar.
  3. Migra a la estructura de capas por funcionalidad, una a una; añade el test de arquitectura con las reglas que ya cumplas y endurécelo conforme migres.
  4. Haz la base (commit) antes de añadir `project-assurance.json`: a partir de ese momento cada cambio se coordina como certificación formal.

## 8. Pedir trabajo al orquestador para obtener evidencia verificable

Una buena petición dice qué comportamiento, qué contrato, qué está autorizado y qué evidencia se espera. Ejemplo:

```text
Invoca engineering-orchestrator. Implementa FEATURE-01 a FEATURE-05 de
docs/quality-contracts/<feature>.md (pendiente de aprobación; úsalo como referencia de trabajo).
Autorizado: implementar y ejecutar flutter pub get, flutter analyze, flutter test y dart format
(la comprobación de formato es dart format --output=none --set-exit-if-changed lib test).
Prohibido: git add/commit/push, cambios de configuración global, ejecutar la app en simulador,
añadir dependencias, editar docs/quality-contracts/**, .engineering-assurance/** y AGENTS.md.
Exige: TDD por rebanadas con RED por aserción, flutter test test/architecture en verde,
hallazgos clasificados como bloqueantes o mejoras, revisores independientes según el riesgo,
y un informe con comandos, salidas reales, estado de código y limitaciones (sin PASS global).
```

Qué esperar de vuelta: archivos cambiados, trazabilidad requisito → prueba, tabla RED/GREEN por rebanada, salidas reales de analyze y test, hallazgos con su clasificación, y lo que quedó sin verificar.

## 9. Añadir el CI de GitHub Actions

Objetivo: que un tercero (GitHub) ejecute las comprobaciones deterministas en cada pull request hacia `main` y en cada push a `main`. **No produce `ASSURANCE_PASS`** ni sustituye la aprobación humana, la firma ni el gate (ver [assurance/verification.md](assurance/verification.md#integración-continua-github-actions)).

1. Copia `.github/workflows/ci.yml` a tu proyecto.
2. Adapta, como mínimo:

   | Qué | Dónde | Cómo obtenerlo |
   | --- | --- | --- |
   | Versión y commit del SDK de Flutter | `env.FLUTTER_VERSION` y `env.FLUTTER_COMMIT` | `git ls-remote https://github.com/flutter/flutter.git refs/tags/<versión>` devuelve el commit de la etiqueta (verificado para `3.47.4`: `9584c6713b324636289d067944a46fd6b49df14b`). Si la etiqueta fuese anotada, el commit es el de la línea `refs/tags/<versión>^{}`. Comprueba además que coincide con `flutter --version` de tu SDK local |
   | SHAs de las actions | `uses:` de `actions/checkout` y `actions/cache` | `curl -s https://api.github.com/repos/actions/<repo>/releases/latest` para la etiqueta; `curl -s https://api.github.com/repos/actions/<repo>/git/refs/tags/<etiqueta>` para su objeto. Si `object.type` es `tag` (anotada), resuélvelo hasta el commit con la URL de `object.url`. Confirma con `.../commits/<sha>`. Conserva la versión en un comentario |
   | Comandos de las comprobaciones | Pasos desde "Comprobar el formato" | Los de `checks` en `project-assurance.json` (salvo `build`, que requiere macOS y se deja fuera) más la comprobación de formato. Deben coincidir con `docs/assurance/verification.md` |
   | Rama | `branches: [main]` | Tu rama por defecto |
   | Raíces de formato | `dart format ... lib test` | Las carpetas con código Dart de tu proyecto |

3. Conserva el grupo de `concurrency` por SHA en los pushes: con un grupo por referencia, GitHub sustituiría las ejecuciones pendientes de `main` y algunos commits no se verificarían.
4. No añadas filtros `paths` a los disparadores si vas a exigir el check: GitHub deja "pending" el check requerido de un workflow omitido por filtro y el merge queda bloqueado.
5. Actualiza la política: `.github/**` en `paths.production` y `.github/workflows/**` en `review_triggers.dependencies` (sección 5). Es un cambio de política que, en tu proyecto, requiere aprobación humana y la transición formal; no lo des por aprobado. En FitNotes el usuario lo aprobó en el chat (2026-10-14), pero esa aprobación es una decisión humana registrada, no una atestación: no hay un evento de aprobación firmado por un emisor independiente ni existe la transición formal (`approved_policy_transition_sha256`), y el gate sigue en `BLOCKED_ENVIRONMENT`.
6. Valida antes de subirlo: parsea el YAML y comprueba que cada `uses:` es un SHA de 40 caracteres hexadecimales que existe.

   ```bash
   ruby -ryaml -e 'YAML.load_file(".github/workflows/ci.yml")'    # solo sintaxis YAML
   ```

   En FitNotes además se comprobó cada SHA con `https://api.github.com/repos/<owner>/<repo>/commits/<sha>` y se ejecutaron en local los mismos comandos del workflow. `actionlint` no forma parte de las comprobaciones del proyecto ni estaba instalado; un revisor lo ejecutó una vez sin la autorización prevista y su resultado no se considera evidencia acreditada. El workflow **no se ha ejecutado nunca en GitHub**: tras subirlo, comprueba la primera ejecución y revisa los logs.

## 10. Exigir el check en `main` con un ruleset (pasos manuales)

Los hace la persona propietaria en la interfaz de GitHub; ningún agente debe hacerlos ni declararlos hechos. **No se ejecutaron** al escribir esta guía (cuando se redactó, el remoto previsto no estaba accesible; hoy `origin` está configurado en este repositorio, pero estos pasos siguen sin hacerse): los nombres de menú y de opciones proceden de la documentación de GitHub, no de haber usado la interfaz. Ver [Fuentes consultadas](#fuentes-consultadas).

**Requisito de plan.** Según la documentación de GitHub, los rulesets están disponibles en repositorios públicos con GitHub Free y en repositorios públicos y **privados** con GitHub Pro, Team y Enterprise Cloud. Para un repositorio privado de una cuenta personal, como el previsto para este proyecto, hace falta **GitHub Pro** (o pasar el repositorio a una organización con plan Team o Enterprise Cloud). No se comprobó el plan de la cuenta.

1. Sube el workflow y deja que se ejecute al menos una vez (por ejemplo en un pull request). GitHub documenta que un check requerido debe haberse completado con éxito en el repositorio durante los últimos siete días; si el selector de la interfaz exige ejecuciones previas no está documentado en las páginas consultadas, así que ejecútalo antes de configurar el ruleset.
2. En el repositorio: **Settings**; en la barra lateral, bajo "Code, planning, and automation", **Rulesets** y de nuevo **Rulesets**.
3. **New ruleset** y después **New branch ruleset**.
4. En "Ruleset name" escribe un nombre. El estado de aplicación por defecto es **Disabled**: cámbialo a **Active** para que se aplique al crearlo.
5. En "Target branches", **Add a target** y elige incluir la rama por defecto (`main`) o un patrón `fnmatch` que la cubra. Los nombres exactos de esas opciones no están en la documentación consultada.
6. En "Branch protections" selecciona estas reglas (todas necesarias):
   - **Restrict deletions** (seleccionada por defecto): solo quien tenga permiso de bypass puede borrar la rama.
   - **Block force pushes** (activada por defecto): impide los force push. Con esta regla, los administradores no pueden cambiar ni renombrar la rama por defecto salvo que puedan saltarse el ruleset.
   - **Require a pull request before merging**: **necesaria**, no opcional. Exige que todo cambio llegue a `main` mediante un pull request (la documentación aclara que no tiene que estar aprobado, pero sí abierto). Es el punto donde una persona puede revisar el diff, en particular el de `.github/**` (ver el riesgo residual más abajo).
   - **Require status checks to pass before merging** (la documentación también la nombra "Require status checks before merging"). En "Additional settings", escribe el nombre del check y pulsa el icono **+** para añadirlo.
     - Nombre: la documentación indica que, para un workflow, el formato del nombre es `<job name>`. El job de este workflow es `checks` (no tiene `name:`), así que debería mostrarse `checks`; compruébalo en la lista de checks de un pull request.
     - **Origen esperado**: elige la app **GitHub Actions**, no "any source". La documentación explica que cualquier persona o integración con permisos de escritura puede fijar el estado de cualquier check del repositorio, y que al añadir la regla puedes seleccionar una app como origen esperado de las actualizaciones; si el estado lo fija otra persona o integración, no se permite fusionar. La app debe haber enviado un check run recientemente, así que el workflow tiene que haberse ejecutado antes. El texto exacto con el que la interfaz muestra esa app no figura en las páginas consultadas: verifícalo al configurarlo.
     - Opcional: **Require branches to be up to date before merging** (estricto; para que la protección surta efecto hay que definir al menos un check).
7. "Bypass list": **déjala vacía**. Un actor en esa lista puede saltarse el ruleset, así que cualquier entrada debilita la garantía.
8. **Create**. Con estado "Active" se aplica de inmediato.

Notas verificadas en la documentación: el check debe pasar sobre el último commit; `success`, `skipped` y `neutral` cuentan como correctos; un workflow omitido por filtro de rama, de rutas o por una instrucción de omisión en el mensaje del commit deja el check en "pending" y bloquea el merge; para que un check de un job de Actions cuente, el workflow debe dispararse con `push`, `pull_request` u otros eventos admitidos (este usa `pull_request` y `push`).

**Qué cierra este ruleset** (con la configuración anterior, según la documentación):

- Un push directo de un commit no probado a `main` queda bloqueado: exige pull request y el check requerido.
- Un estado o check fijado por una persona o integración distinta de GitHub Actions no satisface el check requerido (origen esperado).
- Con la lista de bypass vacía, ningún actor puede saltarse las reglas directamente (la propietaria sí puede editar el ruleset; ver más abajo). Los force push y el borrado de `main` quedan bloqueados.

**Riesgo residual: lo que NO cierra.**

- **Un pull request puede redefinir el check.** La documentación indica que los checks requeridos no tienen en cuenta el workflow, la matriz ni el tipo de evento: se identifican solo por el nombre. Un pull request puede modificar `.github/workflows/ci.yml` (por ejemplo, vaciar los pasos de `checks`) o añadir otro workflow con un job llamado `checks`, y el check seguirá pasando con origen GitHub Actions. Existe la regla "Require workflows to pass before merging" para exigir un workflow definido fuera del repositorio, pero la documentación consultada la describe a nivel de organización o de empresa; no se encontró una vía para un repositorio de cuenta personal, así que aquí se considera no disponible.
- **La aprobación no es una opción realista.** En un repositorio con una sola persona, quien abre el pull request es también quien lo fusiona. Exigir aprobaciones puede dejar de ser viable (no se verificó en la documentación si GitHub permite aprobar el propio pull request).
- **La propietaria siempre puede editar o desactivar el ruleset**: quien tiene acceso de administrador puede crear, editar y borrar rulesets.

**Mitigación**: una persona debe revisar el diff de `.github/**` antes de fusionar cualquier pull request que lo toque. Es lo que persigue la política que trata `.github/**` como producción (ver [assurance/verification.md](assurance/verification.md#política-de-assurance-para-el-ci-aprobada-en-el-chat-sin-atestación)). En un proyecto donde esa política no esté aprobada, y en FitNotes mientras no exista la atestación ni el gate, esta revisión es solo una práctica recomendada, no un control técnico.

Qué **no** da este ruleset: aprobación humana independiente, firma, independencia de agentes ni `ASSURANCE_PASS`. Garantiza, como mucho, que un job llamado `checks` terminó correctamente en GitHub Actions antes de fusionar, no que ese job siga ejecutando las comprobaciones previstas.

## 11. Permisos del PAT para subir `.github/workflows/`

Para hacer `push` de archivos de `.github/workflows/` por HTTPS con un token personal. La propia documentación de GitHub recomienda los tokens fine-grained frente a los clásicos, porque se pueden limitar a repositorios concretos y a permisos concretos.

**Opción por defecto: PAT fine-grained.** En Settings > Developer settings > Personal access tokens > Fine-grained tokens > Generate new token:

- **Resource owner**: la cuenta propietaria del repositorio.
- **Expiration**: elige una expiración corta y explícita. La documentación indica que se puede elegir una expiración; que se permiten duraciones infinitas (pueden estar bloqueadas por una política de organización o empresa); y que en las plantillas de URL `expires_in` admite de 1 a 366 días o `none`, con 30 días por defecto. No uses una duración infinita. Qué opciones concretas ofrece el desplegable en este momento no figura en las páginas consultadas.
- **Repository access**: **Only select repositories**, limitado a este repositorio. Sin eso el token solo puede leer repositorios públicos (la documentación indica que todo token incluye lectura de los públicos).
- **Permissions** (de repositorio): **Contents: Read and write** y **Workflows: Read and write**. La documentación de GitHub muestra esta combinación (`contents=write` y `workflows=write`) en su plantilla "Update code and open a pull request", con la nota "Includes permission to edit workflow files for Actions". Workflows solo admite `write`. No concedas más permisos.
- Según la documentación, los tokens personales solo sirven para operaciones Git por HTTPS; si el remoto usa SSH hay que cambiarlo a HTTPS.

**Último recurso: PAT clásico** (Tokens (classic) > Generate new token (classic)). Necesita el scope **`workflow`** ("Grants the ability to add and update GitHub Actions workflow files") y, para acceder a repositorios privados desde la línea de comandos, `repo`. **Aviso: `repo` concede acceso completo a TODOS los repositorios, también privados, a los que tu cuenta tenga acceso (la documentación avisa de que un token clásico "can access every repository that you can access"), con lectura y escritura de código y de commit statuses.** `repo:status` forma parte de `repo` y permite leer y escribir estados de commit, es decir, crear estados que pueden aparentar ser checks externos. Úsalo solo si el fine-grained no sirve, con la expiración más corta posible, y revócalo al terminar. Según la documentación de scopes, un archivo de workflow puede subirse sin `workflow` solo si el mismo archivo (misma ruta y mismo contenido) ya existe en otra rama del repositorio.

No se probó ningún push: el remoto está configurado como `origin` en este repositorio (`https://github.com/jadelagarza/fit-notes-workbench.git`), pero no se hizo ni se intentó ningún push, y por tanto no se ha comprobado que el token ni sus permisos funcionen. No compartas el token con agentes y revócalo cuando termines.

## 12. Lista de comprobación final

- [ ] `lib/` con capas `domain`/`data`/`presentation` y `app.dart`; `main.dart` solo hace `runApp`.
- [ ] `flutter test test/architecture` en verde y comprobado que detecta una infracción real.
- [ ] Contrato con procedencia por requisito (HUMAN solo lo que la persona pidió literalmente) y estado "pendiente de aprobación" hasta que una persona lo apruebe de forma atestada. En FitNotes: procedencia confirmada y propuestas aceptadas en el chat, sin aprobación formal atestada.
- [ ] Inventario solo con requisitos HUMAN (en FitNotes, LOGIN-01 a LOGIN-03); `contract_sha256` coincide con el contrato; cada pasaje es literal.
- [ ] Requisitos AGENT-PROPOSED en un archivo aparte, con el mismo hash y con el `status` real (en FitNotes, `ACCEPTED_BY_USER_IN_CHAT_NOT_ATTESTED`).
- [ ] `project-assurance.json`: cada archivo versionado en exactamente una categoría; comandos reales; `capabilities` con `true` solo para lo que el trabajo requiere y el preflight debe acreditar (las cuatro que exige siempre el validador incluidas).
- [ ] `AGENTS.md` con la entrada obligatoria por el orquestador.
- [ ] `dart format --output=none --set-exit-if-changed lib test` (comprobación; `dart format lib test` solo aplica formato), `flutter analyze` y `flutter test` en verde, con comando y salida registrados.
- [ ] README con el aviso de que cualquier autenticación simulada no es segura, escenarios documentados y versiones observadas.
- [ ] `docs/decisions.md` con decisión, motivo y quién decidió; `docs/assurance/verification.md` con lo que sigue requiriendo criterio humano.
- [ ] Hallazgos bloqueantes en cero y revalidados por un verificador distinto de quien corrigió.
- [ ] CI: `.github/workflows/ci.yml` con triggers solo a `main`, `permissions: contents: read`, actions fijadas por SHA de 40 caracteres, commit del SDK verificado y comandos iguales a `checks`; YAML válido; primera ejecución en GitHub revisada.
- [ ] Política de `project-assurance.json` con `.github/**` y `.github/workflows/**`: en tu proyecto, registrada como pendiente hasta que una persona la apruebe (no como aprobada); cuando la apruebe, registra la decisión con su fecha y el medio, sin presentarla como atestación mientras falten el evento firmado por un emisor independiente y la transición formal (`approved_policy_transition_sha256`). En FitNotes está aprobada por el usuario en el chat (2026-10-14), no atestada.
- [ ] Ruleset de `main` creado por la persona propietaria: check `checks` requerido con origen GitHub Actions (no "any source"), "Require a pull request before merging" activada, sin force push ni borrado, lista de bypass vacía, y plan de GitHub que lo permite. Riesgo residual aceptado de forma explícita (un pull request puede redefinir el check) y revisión humana del diff de `.github/**` antes de fusionar.
- [ ] PAT fine-grained propio de la cuenta, "Only select repositories" con este repositorio, solo Contents y Workflows en lectura y escritura, y una expiración corta y explícita. El clásico (`repo` y `workflow`) solo como último recurso: `repo` da acceso a todos los repositorios privados de la cuenta; revócalo al terminar.
- [ ] Sin `PASS` global en trabajo ordinario; el `PASS` formal solo lo emite el gate externo del operador independiente.

## Fuentes consultadas

Consultadas el 2026-10-14. Varias páginas de `docs.github.com` se leyeron a partir de su Markdown fuente en el repositorio público `github/docs` (rama `main`, commit `8b39dc44a0…` al consultarlo), porque la herramienta de lectura resumía el contenido renderizado; ese Markdown contiene marcas de plantilla de GitHub que no se muestran en la página.

| URL | Qué se verificó |
| --- | --- |
| https://docs.github.com/en/billing/reference/actions-runner-pricing | Tarifas por minuto de los runners estándar: macOS 3 o 4 núcleos (M1 o Intel) $0.062; Linux 2 núcleos (x64) $0.006. El Markdown fuente conserva `redirect_from: /billing/reference/actions-minute-multipliers`, es decir, el antiguo documento de multiplicadores ahora publica tarifas y no un multiplicador, por eso no se cita ninguno |
| https://docs.github.com/en/billing/concepts/product-billing/github-actions | En repositorios privados el uso consume la cuota de la cuenta y el exceso se factura; el uso es gratuito en repositorios públicos con runners estándar; los runners de Windows y macOS cuestan más que los de Linux |
| https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets | Disponibilidad por plan (texto reutilizable `gated-features/repo-rules`: repositorios privados con Pro, Team o Enterprise Cloud); varios rulesets se suman |
| https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/creating-rulesets-for-a-repository | Ruta de menú (Settings, Rulesets, Rulesets), "New ruleset", "New branch ruleset", estado de aplicación, "Target branches", icono + para añadir checks |
| https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets | Nombres y comportamiento de "Restrict deletions", "Block force pushes", "Require status checks to pass before merging" y "Require a pull request before merging"; cualquier persona o integración con permisos de escritura puede fijar el estado de un check; al añadir la regla se puede elegir una app como origen esperado (y existe la opción "any source"), y la app debe haber enviado un check run recientemente; "Require a pull request before merging" exige un PR abierto, no necesariamente aprobado; "Require workflows to pass before merging" se describe a nivel de organización o empresa |
| https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/troubleshooting-rules | Nombre de un check de workflow: formato `<job name>`; los checks requeridos no tienen en cuenta el workflow, la matriz ni el tipo de evento |
| https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks | Un check requerido debe haberse completado con éxito en los últimos siete días; debe pasar sobre el último commit; eventos válidos; workflows omitidos por filtro dejan el check en pending |
| https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens | Permisos fine-grained `contents` (read, write) y `workflows` (write); plantilla con `contents=write` y `workflows=write`; los tokens fine-grained solo sirven para Git por HTTPS; seleccionar `repo` para acceder a repositorios desde la línea de comandos; GitHub recomienda los fine-grained y avisa de que un clásico "can access every repository that you can access"; pasos del fine-grained (Expiration, Resource owner, "Only select repositories"); infinito permitido pero posiblemente bloqueado por política, `expires_in` de 1 a 366 días o `none` con 30 por defecto en las plantillas; el clásico ofrece opciones de expiración por defecto o "Custom" |
| https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/scopes-for-oauth-apps | Scope `workflow` para añadir y actualizar archivos de workflow y la excepción de un archivo idéntico en otra rama; `repo` concede acceso completo a repositorios públicos y privados, con lectura y escritura de código y de commit statuses, y `repo:status` (lectura y escritura de commit statuses) figura como subscope |
| https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens | El permiso "Workflows" lista como escritura `PUT /repos/{owner}/{repo}/contents/{path}` y las rutas `git/refs`; esa página no trata `git push` |
| https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency y https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#concurrency | Con `concurrency`, GitHub sustituye por defecto la ejecución pendiente de un mismo grupo aunque `cancel-in-progress` sea falso (texto reutilizable `actions-group-concurrency`); límites por grupo; el grupo a nivel de workflow admite los contextos `github`, `inputs` y `vars` (`section-using-concurrency`). Por eso el workflow usa un grupo por SHA en los pushes |
| https://github.com/actions/runner-images/blob/main/images/ubuntu/Ubuntu2404-Readme.md | Imagen `ubuntu-24.04` 20261004.327.1; anuncio de que `ubuntu-latest` pasará a Ubuntu 26.04 en noviembre de 2026 |
| https://github.com/actions/runner-images/blob/main/images/ubuntu/toolsets/toolset-2404.json | Paquetes `apt` instalados que incluyen `curl`, `unzip`, `zip`, `xz-utils` y `file` |
| https://api.github.com/repos/actions/checkout/releases/latest y https://api.github.com/repos/actions/cache/releases/latest | Últimas releases estables: `v7.0.1` y `v6.1.0` |
| https://api.github.com/repos/actions/checkout/git/refs/tags/v7.0.1 y https://api.github.com/repos/actions/cache/git/refs/tags/v6.1.0 | Ambas etiquetas son ligeras (`object.type` = `commit`): `3d3c42e5aac5ba805825da76410c181273ba90b1` y `55cc8345863c7cc4c66a329aec7e433d2d1c52a9` |
| https://api.github.com/repos/flutter/flutter/git/refs/tags/3.47.4 | La etiqueta `3.47.4` apunta al commit `9584c6713b324636289d067944a46fd6b49df14b` (confirmado también con `git ls-remote`) |
