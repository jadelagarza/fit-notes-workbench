# Instrucciones para agentes — FitNotes

## Entrada obligatoria

Invoca `engineering-orchestrator` para cualquier cambio de producción (`lib/**`, `android/**`, `ios/**`, `pubspec.yaml`, `pubspec.lock`, `.github/**`) y para cualquier cambio de comportamiento. El orquestador coordina y no implementa: especialistas distintos implementan y verifican, y quien corrige un hallazgo no certifica su propio cierre.

## Contexto de trabajo

Este repositorio versiona `.engineering-assurance/project-assurance.json`. Según el contrato canónico del workbench (`engineering-assurance/ORCHESTRATOR_CONTRACT.md`), cualquier cambio que parta de una base que contenga ese archivo se coordina como **certificación formal**. Mientras no exista un operador independiente (clave Ed25519 externa, runner protegido y eventos autenticados), el gate formal queda en `BLOCKED_ENVIRONMENT`. Ningún agente puede declarar `PASS` ni `ASSURANCE_PASS` sin él, ni convertir ese bloqueo en trabajo ordinario.

## Fuentes que debes leer antes de planificar

1. `docs/quality-contracts/login.md`: comportamiento acordado. Estado: procedencia confirmada y propuestas aceptadas por la persona en el chat (2026-10-14); **sin aprobación formal atestada**.
2. `docs/quality-contracts/login.inventory.json`: inventario de los requisitos HUMAN (solo LOGIN-01 a LOGIN-03), con el SHA-256 del contrato.
3. `docs/quality-contracts/login.proposed-requirements.json`: requisitos AGENT-PROPOSED (LOGIN-04 a LOGIN-36), aceptados por la persona en el chat el 2026-10-14 (`ACCEPTED_BY_USER_IN_CHAT_NOT_ATTESTED`). Conservan su procedencia y no entran en el inventario.
4. `.engineering-assurance/project-assurance.json`: rutas, comandos y capacidades requeridas (las que el preflight debe acreditar).
5. `docs/assurance/verification.md`: evidencia que debe producir un cambio y criterios para considerarlo verificado.

## Reglas

- Las pruebas HUMAN (LOGIN-01 a LOGIN-03) se respetan siempre: no las debilites, no las elimines ni las reinterpretes, y conserva su redacción literal. Solo es HUMAN lo que la persona pidió literalmente; lo que derivas tú es AGENT-PROPOSED aunque parezca obvio. Puedes proponer escenarios adicionales cuando lo veas necesario, siempre como AGENT-PROPOSED.
- Si cambia el contrato, recalcula su SHA-256 en el inventario y en el archivo de propuestos, y pide una nueva aprobación humana. Una aprobación anterior (incluida la aceptación en el chat) no cubre bytes nuevos.
- No elimines ni debilites pruebas para acomodar código. Aplica TDD (RED por aserción antes de GREEN) a cada cambio de lógica o de estados.
- Mantén la dirección de dependencias que comprueba `flutter test test/architecture`: `domain` no importa `data`, `presentation` ni Flutter.
- Registra para cada verificación el comando, el resultado y el estado de código: `HEAD` y, si hay cambios sin commit, `git diff` o los hashes de los archivos.
- Los checks deterministas del workflow `.github/workflows/ci.yml` deben coincidir con los de `checks` de `.engineering-assurance/project-assurance.json` (salvo `build`, que exige macOS y queda fuera del CI) y con los de `docs/assurance/verification.md`. Si cambias uno, cambia los demás en el mismo trabajo.
- Cambiar `.github/**` es un cambio de **producción** sujeto a revisión de código; cambiar `.github/workflows/**` dispara además la revisión de dependencias (las actions fijadas cuentan como dependencias). Esa política fue **aprobada por el usuario en el chat el 2026-10-14**, pero **no está atestada**: no hay un evento de aprobación firmado por un emisor independiente ni existe la transición formal (`approved_policy_transition_sha256`), y el gate formal sigue en `BLOCKED_ENVIRONMENT` (ver `docs/assurance/verification.md` y `docs/decisions.md`). Que el CI pase no equivale a `ASSURANCE_PASS`.
- No hagas commits, push ni cambios de configuración global sin autorización explícita de la persona.
