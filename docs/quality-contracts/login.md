# Quality Contract — inicio de sesión simulado (FitNotes)

## Procedencia y estado

**Estado: PENDIENTE DE APROBACIÓN HUMANA.**

- **HUMAN**: requisitos que reformulan, sin añadir reglas, la petición literal de la persona de crear desde cero una aplicación básica de Flutter con un inicio de sesión simulado. Están pendientes de aprobación formal.
- **AGENT-PROPOSED**: decisiones propuestas por el engineering-orchestrator al renunciar la persona al borrador, y casos añadidos por la especificación para cubrir dimensiones de comportamiento que la petición no definía. Son supuestos de trabajo hasta que la persona los apruebe, los ajuste o los rechace.
- Ningún agente puede aprobar este contrato, su inventario ni ninguno de sus requisitos. Solo la persona puede hacerlo, mediante un evento de aprobación verificable registrado fuera del control de los agentes. Que este archivo exista en Git no constituye aprobación.
- Este contrato se creó como configuración para cambios futuros durante un trabajo ordinario; no certifica el trabajo que lo originó.
- Base: proyecto nuevo, sin comportamiento previo que preservar.

## Objetivo

Permitir que una persona pruebe un flujo básico de inicio de sesión con correo electrónico y contraseña. El flujo se resuelve con datos simulados y deterministas, sin backend, sin persistencia y sin credenciales reales, de modo que los resultados de éxito y de error se puedan reproducir a voluntad y comprobar automáticamente.

## Comportamiento esperado

1. **Estado inicial** (AGENT-PROPOSED): la pantalla muestra un formulario con los campos correo y contraseña vacíos, sin mensajes, y un control de envío disponible.
2. **Intento de envío** (HUMAN y AGENT-PROPOSED): al intentar enviar, se validan el correo y la contraseña. Si hay errores de validación, se muestran junto a su campo y no se envía ninguna solicitud de inicio de sesión.
3. **Carga** (HUMAN y AGENT-PROPOSED): si los datos son válidos, comienza el inicio de sesión simulado. Mientras está en curso, se ve un indicador de progreso, el envío está deshabilitado y ningún intento adicional genera otra solicitud.
4. **Éxito** (HUMAN y AGENT-PROPOSED): se muestra un mensaje de bienvenida con el nombre y el correo del usuario identificado, y un botón para volver al formulario. Volver devuelve la pantalla al estado inicial; es un reinicio local, no un cierre de sesión real.
5. **Error** (HUMAN y AGENT-PROPOSED): se muestra un mensaje visible, distinto para credenciales inválidas y para error técnico. El formulario conserva los valores introducidos, sigue editable y permite reintentar.
6. **Terminación** (AGENT-PROPOSED): toda solicitud iniciada termina en éxito o en error.

La interfaz se presenta en español (AGENT-PROPOSED).

## Reglas de negocio

- El correo no puede estar vacío (HUMAN).
- El correo debe tener formato válido (HUMAN). La definición de formato válido es AGENT-PROPOSED:
  - exactamente una arroba;
  - parte local no vacía;
  - dominio con al menos un punto;
  - ninguna etiqueta de dominio vacía;
  - ningún espacio en blanco interno.
  - No se pretende cumplir todo el RFC 5322.
- Antes de validar el correo, se recortan los espacios en blanco iniciales y finales. Un correo que queda vacío tras el recorte produce el error correo obligatorio (AGENT-PROPOSED).
- Un correo aceptado se normaliza a minúsculas (AGENT-PROPOSED). Motivo: en este inicio de sesión simulado el correo se compara sin distinguir mayúsculas, aunque la parte local sea técnicamente sensible a mayúsculas según el RFC.
- La contraseña no puede estar vacía (HUMAN). No se recorta, solo es vacía con cero caracteres y no tiene reglas de complejidad (AGENT-PROPOSED).
- Si existe algún error de validación, no se envía ninguna solicitud de inicio de sesión y se muestran todos los errores por campo a la vez (AGENT-PROPOSED).
- El inicio de sesión se resuelve con datos simulados, sin backend (HUMAN). El mock permite reproducir el éxito y el error (HUMAN). Sus escenarios se activan solo mediante las credenciales introducidas (AGENT-PROPOSED):
  - correo demo@fitnotes.dev con contraseña Demo1234: éxito con el usuario de id user-demo-001, nombre Demo FitNotes y correo demo@fitnotes.dev;
  - correo fallo@fitnotes.dev con cualquier contraseña no vacía: error técnico servicio no disponible;
  - cualquier otra combinación que supere la validación: error credenciales inválidas;
  - la contraseña se compara exactamente, distinguiendo mayúsculas, minúsculas y espacios.
- El retardo de la respuesta simulada es configurable; en la aplicación es de 800 ms (AGENT-PROPOSED).
- Todas las credenciales de los escenarios son valores ficticios de prueba y no protegen nada real (AGENT-PROPOSED).

## Invariantes

- Nunca se envía una solicitud de inicio de sesión con un correo o una contraseña que no superen la validación (AGENT-PROPOSED).
- Como máximo hay una solicitud de inicio de sesión en curso a la vez, cualquiera que sea el medio de envío (AGENT-PROPOSED).
- Toda solicitud iniciada termina en éxito o en error; la pantalla nunca queda en carga indefinidamente (AGENT-PROPOSED).
- Un usuario identificado siempre tiene id, nombre y correo electrónico (HUMAN).
- El correo de un usuario identificado cumple las reglas de formato y está en minúsculas (AGENT-PROPOSED).
- Las mismas credenciales producen siempre el mismo resultado simulado (HUMAN: reproducibilidad; AGENT-PROPOSED: alcance determinista).
- La contraseña nunca se muestra en claro en la pantalla ni en los mensajes (AGENT-PROPOSED).

## Pruebas humanas

Cada prueba tiene un ID estable. En cada una, la primera oración después del título es el pasaje exacto que debe citarse literalmente en el inventario y en la trazabilidad (contract_excerpt). Si se necesita otra interpretación, hace falta una nueva aprobación humana acreditada.

Las pruebas HUMAN son obligatorias aunque se agreguen otros casos. Las pruebas AGENT-PROPOSED conservan su procedencia: no forman parte del inventario humano mientras la persona no las adopte expresamente.

Este archivo no contiene IDs de ejecución, firmas ni aprobaciones; esos datos los captura un ejecutor independiente.

### Requisitos HUMAN

### LOGIN-01 — Correo vacío

Un intento de inicio de sesión con el correo vacío se rechaza con un error de validación del correo.

**Procedencia:** HUMAN ("Valida correo no vacío").

**Pasos**
1. Dejar el correo vacío, escribir una contraseña no vacía e intentar enviar.

**Resultado esperado**
- Aparece un error de validación en el campo correo.
- No se inicia el inicio de sesión.

### LOGIN-02 — Correo con formato inválido

Un intento de inicio de sesión con un correo de formato inválido se rechaza con un error de validación del correo.

**Procedencia:** HUMAN ("con formato válido").

**Pasos**
1. Escribir un correo de formato inválido, por ejemplo demofitnotes.dev, y una contraseña no vacía.
2. Intentar enviar.

**Resultado esperado**
- Aparece un error de validación en el campo correo.
- No se inicia el inicio de sesión.

### LOGIN-03 — Contraseña vacía

Un intento de inicio de sesión con la contraseña vacía se rechaza con un error de validación de la contraseña.

**Procedencia:** HUMAN ("contraseña no vacía").

**Pasos**
1. Escribir un correo válido, dejar la contraseña vacía e intentar enviar.

**Resultado esperado**
- Aparece un error de validación en el campo contraseña.
- No se inicia el inicio de sesión.

### LOGIN-04 — Éxito reproducible

Con las credenciales documentadas para el escenario de éxito, el inicio de sesión simulado termina en éxito cada vez que se intenta.

**Procedencia:** HUMAN ("El mock debe permitir probar éxito [...] de forma reproducible").

**Pasos**
1. Usar las credenciales de éxito documentadas.
2. Iniciar sesión varias veces.

**Resultado esperado**
- Todos los intentos terminan en éxito.

### LOGIN-05 — Error reproducible

Con las credenciales documentadas para un escenario de error, el inicio de sesión simulado termina en error cada vez que se intenta.

**Procedencia:** HUMAN ("El mock debe permitir probar [...] error de forma reproducible").

**Pasos**
1. Usar las credenciales documentadas de cada escenario de error.
2. Iniciar sesión varias veces.

**Resultado esperado**
- Todos los intentos terminan en error.

### LOGIN-06 — Usuario identificado

Un inicio de sesión exitoso identifica a un usuario con id, nombre y correo electrónico.

**Procedencia:** HUMAN ("User con id, name y email").

**Pasos**
1. Iniciar sesión con las credenciales de éxito.

**Resultado esperado**
- El resultado identifica a un usuario con id, nombre y correo electrónico.

### LOGIN-07 — Estado de carga

Mientras el inicio de sesión está en curso, la pantalla de inicio de sesión muestra un estado de carga.

**Procedencia:** HUMAN ("estados de carga").

**Pasos**
1. Enviar credenciales válidas.
2. Observar la pantalla antes de que llegue la respuesta.

**Resultado esperado**
- Se ve el estado de carga.

### LOGIN-08 — Estado de éxito

Cuando el inicio de sesión termina en éxito, la pantalla de inicio de sesión muestra un estado de éxito.

**Procedencia:** HUMAN ("estados de [...] éxito").

**Pasos**
1. Enviar las credenciales de éxito y esperar la respuesta.

**Resultado esperado**
- Se ve el estado de éxito.

### LOGIN-09 — Estado de error

Cuando el inicio de sesión termina en error, la pantalla de inicio de sesión muestra un estado de error.

**Procedencia:** HUMAN ("estados de [...] error").

**Pasos**
1. Enviar las credenciales de un escenario de error y esperar la respuesta.

**Resultado esperado**
- Se ve el estado de error.

### LOGIN-10 — Sin backend

El inicio de sesión se resuelve con datos simulados, sin contactar ningún backend.

**Procedencia:** HUMAN ("implementación con un mock, sin backend").

**Pasos**
1. Iniciar sesión en cada escenario sin conexión de red.

**Resultado esperado**
- Cada escenario produce su resultado sin realizar comunicaciones de red.

### LOGIN-11 — Documentación de escenarios

La documentación del proyecto explica cómo activar cada escenario simulado de éxito y de error.

**Procedencia:** HUMAN ("documenta cómo activar cada escenario").

**Pasos**
1. Leer la documentación del proyecto.
2. Seguir sus instrucciones para cada escenario.

**Resultado esperado**
- Cada escenario documentado produce el resultado descrito.

### LOGIN-12 — Comprobaciones automatizadas

Existen comprobaciones automatizadas de las validaciones, del flujo de inicio de sesión y de sus estados de carga, éxito y error.

**Procedencia:** HUMAN ("Incluye comprobaciones automatizadas de las validaciones, el flujo de inicio de sesión y sus estados de carga, éxito y error").

**Pasos**
1. Revisar la suite de pruebas.
2. Ejecutarla.

**Resultado esperado**
- Hay comprobaciones de cada validación, del flujo y de cada estado.
- Todas pasan.

### Requisitos AGENT-PROPOSED (decisiones del orquestador)

### LOGIN-13 — Recorte del correo

Antes de validarlo, el correo se recorta de los espacios en blanco iniciales y finales.

**Procedencia:** AGENT-PROPOSED (engineering-orchestrator, decisión 1).

**Pasos**
1. Escribir un correo válido con espacios al principio y al final, junto con la contraseña de éxito.
2. Enviar.

**Resultado esperado**
- El correo se acepta como si no tuviera esos espacios.

### LOGIN-14 — Correo obligatorio

Un correo vacío o formado solo por espacios en blanco muestra el error correo obligatorio.

**Procedencia:** AGENT-PROPOSED (engineering-orchestrator, decisión 1).

**Pasos**
1. Enviar con el correo vacío.
2. Enviar con un correo formado solo por espacios.

**Resultado esperado**
- En ambos casos se muestra el error correo obligatorio.

### LOGIN-15 — Definición de formato válido

Un correo tiene formato válido solo si contiene exactamente una arroba, una parte local no vacía, un dominio con al menos un punto, ninguna etiqueta de dominio vacía y ningún espacio en blanco interno.

**Procedencia:** AGENT-PROPOSED (engineering-orchestrator, decisión 1).

**Pasos**
1. Validar los correos de la tabla de ejemplos de referencia.

**Resultado esperado**
- Cada correo se acepta o se rechaza según la tabla.

### LOGIN-16 — Normalización a minúsculas

Un correo aceptado se normaliza a minúsculas antes de usarse para iniciar sesión.

**Procedencia:** AGENT-PROPOSED (engineering-orchestrator, decisión 1).

**Pasos**
1. Enviar DEMO@FitNotes.dev con la contraseña Demo1234.

**Resultado esperado**
- El inicio de sesión termina en éxito.

### LOGIN-17 — Contraseña sin recorte

La contraseña no se recorta y solo es vacía cuando tiene cero caracteres, por lo que una contraseña formada solo por espacios no es vacía.

**Procedencia:** AGENT-PROPOSED (engineering-orchestrator, decisión 2).

**Pasos**
1. Enviar un correo válido con una contraseña de tres espacios.

**Resultado esperado**
- No hay error de validación de la contraseña.

### LOGIN-18 — Sin reglas de complejidad

Cualquier contraseña de al menos un carácter supera la validación, porque no hay reglas de complejidad.

**Procedencia:** AGENT-PROPOSED (engineering-orchestrator, decisión 2).

**Pasos**
1. Enviar un correo válido con la contraseña x.

**Resultado esperado**
- No hay error de validación de la contraseña.

### LOGIN-19 — Validación previa a la solicitud

Si existe algún error de validación, no se envía ninguna solicitud de inicio de sesión.

**Procedencia:** AGENT-PROPOSED (engineering-orchestrator, decisión 3).

**Pasos**
1. Intentar enviar con datos inválidos.

**Resultado esperado**
- No se registra ninguna solicitud de inicio de sesión.
- No aparece el estado de carga.

### LOGIN-20 — Errores simultáneos por campo

Si el correo y la contraseña son inválidos a la vez, la pantalla muestra ambos errores, cada uno asociado a su campo.

**Procedencia:** AGENT-PROPOSED (engineering-orchestrator, decisión 3).

**Pasos**
1. Intentar enviar con los dos campos vacíos.

**Resultado esperado**
- Se ven a la vez el error del correo y el de la contraseña, cada uno junto a su campo.

### LOGIN-21 — Escenario de éxito

Con el correo demo@fitnotes.dev y la contraseña Demo1234, el inicio de sesión termina en éxito con el usuario de id user-demo-001, nombre Demo FitNotes y correo demo@fitnotes.dev.

**Procedencia:** AGENT-PROPOSED (engineering-orchestrator, decisión 4).

**Pasos**
1. Enviar esas credenciales.

**Resultado esperado**
- El inicio de sesión termina en éxito con ese usuario.

### LOGIN-22 — Escenario de error técnico

Con el correo fallo@fitnotes.dev y cualquier contraseña no vacía, el inicio de sesión termina en el error técnico servicio no disponible.

**Procedencia:** AGENT-PROPOSED (engineering-orchestrator, decisión 4).

**Pasos**
1. Enviar fallo@fitnotes.dev con la contraseña x.
2. Enviar fallo@fitnotes.dev con la contraseña Demo1234.

**Resultado esperado**
- En ambos casos se produce el error técnico servicio no disponible.

### LOGIN-23 — Escenario de credenciales inválidas

Cualquier otra combinación de correo y contraseña que supere la validación termina en el error credenciales inválidas.

**Procedencia:** AGENT-PROPOSED (engineering-orchestrator, decisión 4).

**Pasos**
1. Enviar otra@ejemplo.com con la contraseña x.
2. Enviar demo@fitnotes.dev con la contraseña demo1234.

**Resultado esperado**
- En ambos casos se produce el error credenciales inválidas.

### LOGIN-24 — Activación solo por credenciales

Los escenarios simulados se activan únicamente mediante las credenciales introducidas, y las mismas credenciales producen siempre el mismo resultado.

**Procedencia:** AGENT-PROPOSED (engineering-orchestrator, decisión 4).

**Pasos**
1. Repetir cada escenario con las mismas credenciales, sin cambiar ninguna otra configuración.

**Resultado esperado**
- Cada repetición produce el mismo resultado.

### LOGIN-25 — Retardo simulado

El retardo de la respuesta simulada es configurable y en la aplicación es de 800 ms.

**Procedencia:** AGENT-PROPOSED (engineering-orchestrator, decisión 4; la decisión decía unos 800 ms).

**Pasos**
1. En la aplicación, enviar credenciales válidas.
2. Observar cuándo aparece el resultado.

**Resultado esperado**
- El estado de carga dura el retardo configurado de 800 ms antes de que aparezca el resultado.

### LOGIN-26 — Indicador y envío deshabilitado

Durante la carga se muestra un indicador de progreso y el envío está deshabilitado.

**Procedencia:** AGENT-PROPOSED (engineering-orchestrator, decisión 5).

**Pasos**
1. Enviar credenciales válidas.
2. Observar la pantalla durante la carga.

**Resultado esperado**
- Se ve un indicador de progreso y el control de envío está deshabilitado.

### LOGIN-27 — Sin doble envío

Un nuevo intento de envío durante la carga no genera otra solicitud de inicio de sesión.

**Procedencia:** AGENT-PROPOSED (engineering-orchestrator, decisión 5).

**Pasos**
1. Enviar credenciales válidas.
2. Volver a intentar el envío antes de la respuesta.

**Resultado esperado**
- Solo se registra una solicitud.

### LOGIN-28 — Bienvenida

El estado de éxito muestra un mensaje de bienvenida con el nombre y el correo del usuario.

**Procedencia:** AGENT-PROPOSED (engineering-orchestrator, decisión 5).

**Pasos**
1. Iniciar sesión con las credenciales de éxito.

**Resultado esperado**
- Se ve una bienvenida con Demo FitNotes y demo@fitnotes.dev.

### LOGIN-29 — Volver al formulario

Desde el estado de éxito, el botón para volver al formulario devuelve la pantalla a su estado inicial sin cerrar ninguna sesión real.

**Procedencia:** AGENT-PROPOSED (engineering-orchestrator, decisión 5).

**Pasos**
1. Desde el estado de éxito, pulsar el botón para volver al formulario.

**Resultado esperado**
- Se ve el estado inicial: formulario vacío y sin mensajes.
- No ocurre ninguna otra acción.

### LOGIN-30 — Errores distinguibles

El error de credenciales inválidas y el error técnico muestran mensajes visibles y distintos entre sí.

**Procedencia:** AGENT-PROPOSED (engineering-orchestrator, decisión 5).

**Pasos**
1. Provocar el error credenciales inválidas.
2. Provocar el error técnico servicio no disponible.

**Resultado esperado**
- Los dos mensajes son visibles y se distinguen entre sí.

### LOGIN-31 — Reintento tras error

Tras un error de inicio de sesión, el formulario conserva los valores introducidos, sigue editable y permite reintentar.

**Procedencia:** AGENT-PROPOSED (engineering-orchestrator, decisión 5; la conservación de valores es una propuesta de la especificación).

**Pasos**
1. Provocar un error.
2. Corregir las credenciales a las de éxito y volver a enviar.

**Resultado esperado**
- Los valores seguían en el formulario después del error.
- El nuevo intento termina en éxito.

### Requisitos AGENT-PROPOSED (añadidos por la especificación)

### LOGIN-32 — Error de formato distinto

Un correo no vacío con formato inválido muestra un error de formato distinto del error correo obligatorio.

**Procedencia:** AGENT-PROPOSED (requirement-specifier).

**Pasos**
1. Intentar enviar con el correo a@b.

**Resultado esperado**
- Se ve un error de formato que no es el error correo obligatorio.

### LOGIN-33 — Momento de la validación

Las validaciones se evalúan al intentar enviar el formulario, y el envío está disponible siempre que no haya una solicitud en curso.

**Procedencia:** AGENT-PROPOSED (requirement-specifier).

**Pasos**
1. Con los campos vacíos, comprobar que el envío está disponible.
2. Intentar enviar.

**Resultado esperado**
- Los errores aparecen al intentar enviar, no antes.

### LOGIN-34 — Sustitución de mensajes previos

Al iniciar un nuevo intento de envío, los mensajes del intento anterior se sustituyen por el resultado del nuevo intento.

**Procedencia:** AGENT-PROPOSED (requirement-specifier).

**Pasos**
1. Provocar el error credenciales inválidas.
2. Reenviar las credenciales de éxito.

**Resultado esperado**
- El mensaje de error anterior desaparece y se ve el resultado nuevo.

### LOGIN-35 — Contraseña oculta

El campo de contraseña oculta los caracteres introducidos.

**Procedencia:** AGENT-PROPOSED (requirement-specifier).

**Pasos**
1. Escribir Demo1234 en el campo contraseña.

**Resultado esperado**
- Los caracteres no se ven en claro.

### LOGIN-36 — Fallo inesperado

Un fallo inesperado durante el inicio de sesión se muestra como error técnico y la pantalla nunca queda en carga indefinidamente.

**Procedencia:** AGENT-PROPOSED (requirement-specifier).

**Pasos**
1. Provocar con un doble de prueba un fallo no previsto durante el inicio de sesión.

**Resultado esperado**
- La pantalla sale de la carga y muestra el error técnico.

## Ejemplos de referencia

| Correo introducido | Contraseña | Resultado | IDs |
| --- | --- | --- | --- |
| vacío | Demo1234 | error correo obligatorio; sin solicitud | LOGIN-01, LOGIN-14, LOGIN-19 |
| tres espacios | Demo1234 | error correo obligatorio; sin solicitud | LOGIN-13, LOGIN-14 |
| demo@fitnotes.dev | vacía | error de contraseña; sin solicitud | LOGIN-03, LOGIN-19 |
| vacío | vacía | ambos errores a la vez | LOGIN-20 |
| demofitnotes.dev | x | error de formato | LOGIN-02, LOGIN-15, LOGIN-32 |
| a@@b.com, a@b@c.com | x | error de formato (más de una arroba) | LOGIN-15 |
| @b.com | x | error de formato (parte local vacía) | LOGIN-15 |
| a@b | x | error de formato (dominio sin punto) | LOGIN-15 |
| a@b..c, a@.com, a@b. | x | error de formato (etiqueta vacía) | LOGIN-15 |
| de mo@fitnotes.dev | x | error de formato (espacio interno) | LOGIN-15 |
| a@b.c | x | supera la validación; credenciales inválidas | LOGIN-15, LOGIN-23 |
| demo@fitnotes.dev con espacios alrededor | Demo1234 | éxito | LOGIN-13, LOGIN-21 |
| DEMO@FitNotes.dev | Demo1234 | éxito | LOGIN-16, LOGIN-21 |
| demo@fitnotes.dev | demo1234 | credenciales inválidas | LOGIN-23 |
| demo@fitnotes.dev | Demo1234 con un espacio inicial | credenciales inválidas | LOGIN-17, LOGIN-23 |
| demo@fitnotes.dev | tres espacios | credenciales inválidas (no es vacía) | LOGIN-17, LOGIN-23 |
| otro@fitnotes.dev | Demo1234 | credenciales inválidas | LOGIN-23 |
| fallo@fitnotes.dev | x o Demo1234 | error técnico servicio no disponible | LOGIN-22 |
| FALLO@fitnotes.dev | x | error técnico servicio no disponible | LOGIN-16, LOGIN-22 |
| fallo@fitnotes.dev | vacía | error de contraseña; sin solicitud | LOGIN-03, LOGIN-19 |
| otra@ejemplo.com | x | credenciales inválidas | LOGIN-23 |

## Casos conocidos de error

- No hay defectos conocidos: el proyecto parte de un andamiaje nuevo.
- Riesgos de comportamiento que deben vigilarse:
  - doble solicitud por envíos repetidos durante la carga (LOGIN-27);
  - carga que nunca termina ante un fallo no previsto (LOGIN-36);
  - un correo con mayúsculas o espacios alrededor que no active el escenario esperado (LOGIN-13, LOGIN-16);
  - recortar la contraseña por error (LOGIN-17);
  - confundir los mensajes de credenciales inválidas y de error técnico (LOGIN-30).

## Fuera de alcance

- Navegación a otras pantallas.
- Persistencia de la sesión.
- Registro de usuarios.
- Recuperación de contraseña.
- Localización a otros idiomas; la interfaz está en español.
- Backend, red y credenciales reales.
- Cierre de sesión real.
- Cumplimiento completo del RFC 5322.
- Reglas de complejidad de la contraseña.
- Bloqueo o limitación de intentos de inicio de sesión.

## Decisiones pendientes

- Aprobar, ajustar o rechazar los requisitos AGENT-PROPOSED LOGIN-13 a LOGIN-36. Mientras tanto se usan como supuestos de trabajo y no bloquean el trabajo ordinario.
- Decidir si los requisitos AGENT-PROPOSED aprobados se adoptan como requisitos humanos del inventario, conservando el historial de su origen.
- Aprobar el inventario humano completo (`login.inventory.json`) mediante un evento registrado por un ejecutor independiente.
- Textos visibles exactos de los mensajes: no son contractuales; la implementación los define en un único lugar y las pruebas comprueban que cada mensaje identifica su causa.

## Notas

- La petición HUMAN también fija restricciones técnicas. Este contrato no las convierte en comportamiento, pero no deben perderse; el plan técnico y la revisión deben conservarlas:
  - objeto de valor para el correo;
  - entidad de dominio User con id, name y email;
  - contrato de repositorio implementado con un mock, sin backend;
  - caso de uso para iniciar sesión;
  - DTO y Model de usuario, con responsabilidades y conversiones claras entre entidad, DTO y Model;
  - pantalla de inicio de sesión con los widgets necesarios;
  - uso de StatefulWidget sin gestores de estado;
  - inicio de sesión canalizado mediante el caso de uso.
- Las comprobaciones automatizadas pueden configurar el retardo simulado en 0 ms. Es una decisión de prueba, no un requisito de comportamiento.

## Glosario

- **Correo electrónico**: identificador con el que la persona inicia sesión. Se evalúa recortado, debe cumplir las reglas de formato de este contrato y se usa en minúsculas.
- **Contraseña**: secreto introducido tal cual, sin recorte. Solo es vacía con cero caracteres.
- **Credenciales**: la pareja de correo y contraseña introducida en un intento.
- **Usuario**: persona identificada tras un inicio de sesión exitoso, con id, nombre y correo electrónico.
- **Inicio de sesión simulado**: operación que resuelve unas credenciales válidas en éxito o error con datos ficticios, sin backend ni persistencia.
- **Escenario simulado**: resultado determinista que se activa según las credenciales: éxito, error técnico o credenciales inválidas.
- **Error de validación**: rechazo de un campo antes de enviar ninguna solicitud. Se muestra junto al campo.
- **Credenciales inválidas**: error del inicio de sesión cuando unas credenciales válidas en formato no corresponden a ningún escenario de éxito.
- **Error técnico**: fallo simulado o inesperado del servicio de inicio de sesión, ajeno a las credenciales. Su mensaje es servicio no disponible.
- **Estado inicial**: formulario vacío, sin mensajes y con el envío disponible.
- **Estado de carga**: periodo con una solicitud en curso; hay un indicador de progreso y el envío está deshabilitado.
- **Estado de éxito**: bienvenida con el nombre y el correo del usuario, y un botón para volver al formulario.
- **Estado de error**: mensaje del error del inicio de sesión, con el formulario editable para reintentar.
- **Volver al formulario**: reinicio local al estado inicial. No es un cierre de sesión real.

---

## Regla de separación

Este documento define **qué debe hacer el sistema** y conserva la procedencia humana.

No debe fijar como verdad humana:

- nivel de riesgo de ingeniería;
- complejidad DDD;
- obligatoriedad de TDD;
- Verification Surfaces;
- selección de agentes o herramientas;
- diseño de clases, capas o dependencias.

Esas decisiones pertenecen al `engineering-orchestrator` y a los especialistas técnicos a partir de este contrato, el repositorio real y la evidencia disponible.
