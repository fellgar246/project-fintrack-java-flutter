# 00 — Índice y convenciones transversales

> **SSOT:** [`../PLAN_MAESTRO_FINTRACK.md`](../PLAN_MAESTRO_FINTRACK.md).
> Este archivo NO es una fase de implementación: es el índice de los sub-planes y el recordatorio
> de las reglas que aplican a **todos** ellos. Léelo antes de empezar cualquier otro archivo.

---

## 1. Mapa de sub-planes

| # | Archivo | Fases del maestro | Entregable al terminar |
|---|---|---|---|
| 01 | [`01-CIMIENTOS.md`](01-CIMIENTOS.md) | F0.1 – F0.5 | Monorepo + Postgres en Docker + Spring arranca + Flutter arranca |
| 02 | [`02-AUTH-BACKEND.md`](02-AUTH-BACKEND.md) | F1.1 – F1.3 | Register/login/refresh/logout + JWT + Problem Details |
| 03 | [`03-AUTH-FLUTTER.md`](03-AUTH-FLUTTER.md) | F1.4 | Login/registro, tokens en secure storage, refresh automático |
| 04 | [`04-CUENTAS-Y-CATEGORIAS.md`](04-CUENTAS-Y-CATEGORIAS.md) | F2.1 – F2.3 | CRUD accounts (con saldo) + categories, back y front |
| 05 | [`05-TRANSACCIONES-BACKEND.md`](05-TRANSACCIONES-BACKEND.md) | F3.1 – F3.2 | CRUD transactions + listado paginado con filtros |
| 06 | [`06-TRANSACCIONES-FLUTTER.md`](06-TRANSACCIONES-FLUTTER.md) | F3.3 – F3.4 | Alta/edición + lista con filtros y scroll infinito |
| 07 | [`07-PRESUPUESTOS.md`](07-PRESUPUESTOS.md) | F4.1 – F4.2 | Upsert de budgets con `spentAmount` + pantalla con barras |
| 08 | [`08-DASHBOARD-Y-REPORTES.md`](08-DASHBOARD-Y-REPORTES.md) | F5.1 – F5.3 | 4 endpoints de reports + dashboard + gráficas + CSV |
| 09 | [`09-CALIDAD.md`](09-CALIDAD.md) | F6.1 – F6.3 | Testcontainers, tests unitarios, widget tests, linters |
| 10 | [`10-PORTAFOLIO.md`](10-PORTAFOLIO.md) | F7.1 – F7.3 | Dockerfile multistage, compose de un comando, README, `.http` |

**Orden:** 01 → 02 → 03 → 04 → 05 → 06 → 07 → 08. Los archivos 09 y 10 pueden intercalarse
(recomendado: correr la parte de 09 que aplique al cierre de cada fase, en vez de dejar todo al final).

**Dependencias duras:**
```
01 ──► 02 ──► 03
        └────► 04 ──► 05 ──► 06
                        └──► 07 ──► 08
```

---

## 2. Cómo usar estos archivos

Cada sub-plan tiene la misma estructura:

- **Objetivo** — qué existe al terminar.
- **Prerrequisitos** — qué debe estar hecho antes.
- **Reparto de modelos** — qué tareas van con Haiku y cuáles con Sonnet (criterio en §5).
- **Tareas `Fx.y`** — cada una pensada como **un prompt independiente al IDE**, con su etiqueta de modelo.
- **Archivos a crear** — árbol esperado.
- **Criterios de aceptación** — checklist verificable, no opiniones.
- **Prompt sugerido** — texto listo para pegar en el IDE.

Regla de trabajo: **una tarea = un commit**. No se avanza a la siguiente tarea si la anterior
no cumple su checklist.

---

## 3. Convenciones que aplican a todo (§2.4 del maestro)

### Idioma
- **Comentarios de código (Java, Dart, SQL, YAML) siempre en inglés** — Javadoc/dartdoc,
  comentarios de línea y de bloque. El resto (spec, UI, mensajes de commit, nombres de rutas/
  branches) se mantiene en español.

### Backend
- Paquete raíz `com.fintrack`. Un paquete por módulo de dominio (§2.2).
- Capas: `Controller → Service → Repository → Entity`. El controller **nunca** toca el repositorio.
- El controller recibe/devuelve **DTOs**, nunca entidades JPA.
- API versionada bajo `/api/v1`.
- IDs `UUID` v4 generados en la aplicación (`@GeneratedValue(strategy = UUID)` o asignados en el servicio).
- Dinero: `DECIMAL(14,2)` en BD, `BigDecimal` en Java. **Prohibido `float`/`double` para montos.**
- Fechas: `LocalDate` (`yyyy-MM-dd`) para fechas de negocio, `Instant`/`TIMESTAMPTZ` en UTC para auditoría.
- Errores: RFC 7807 Problem Details (§4.7). Ninguna excepción llega cruda al cliente.
- **RB-05 sin excepciones:** toda query filtra por el `user_id` del token. Nunca se confía en un
  `userId` que venga en el body o en la query string.

### Frontend
- Estructura por feature: `data/ (api + models) → providers/ (Riverpod) → presentation/`.
- Estado con Riverpod 2.x. Nada de `setState` para estado de negocio.
- Dinero en Dart con el paquete `decimal` (`Decimal.parse(json['amount'] as String)`).
  El backend serializa montos como **string** para no perder precisión.
- Formato de moneda y fecha siempre vía helpers de `shared/formatters/`, nunca inline.
- Todo texto visible sale de un archivo de strings (preparado para i18n), no hardcodeado en widgets.

### JSON
- `camelCase` en todas las propiedades.
- Ejemplo canónico de transacción:
  ```json
  {
    "id": "3f2b...",
    "type": "EXPENSE",
    "amount": "1234.50",
    "date": "2026-07-25",
    "accountId": "...",
    "categoryId": "...",
    "transferAccountId": null,
    "note": "Súper"
  }
  ```

### Git
- Ramas: `feat/f3-1-transactions-crud`, `fix/...`, `chore/...`.
- Commits: `feat(transactions): POST /transactions con validación RB-03`.

---

## 4. Definition of Done (aplica a **cada** tarea)

- [ ] Compila sin warnings nuevos (`./gradlew build` / `flutter analyze`).
- [ ] Tests de la tarea pasan; no se rompió ningún test existente.
- [ ] Endpoint nuevo visible y probado en Swagger UI (`/swagger-ui.html`).
- [ ] Si cambió algo del contrato o del modelo → **se actualizó primero** `PLAN_MAESTRO_FINTRACK.md`
      y su tabla de control de cambios (§10).
- [ ] Sin secretos hardcodeados; todo por variables de entorno.

---

## 5. Reparto de modelos (Haiku vs. Sonnet)

Cada tarea `Fx.y` lleva una etiqueta que indica con qué modelo conviene ejecutarla:

| Etiqueta | Significado |
|---|---|
| 🟢 **Haiku** | Spec cerrada, patrón ya establecido en el repo, verificación mecánica. Barato y rápido. |
| 🔵 **Sonnet** | Decisiones de diseño, seguridad, concurrencia, SQL de agregación, estado con condiciones de carrera, o la **primera vez** que se introduce un patrón. |
| 🟡 **Mixto** | Sonnet resuelve la parte crítica indicada; Haiku produce el resto (DTOs, widgets, casos repetidos). |

### Criterio de decisión

Manda **Sonnet** si la tarea cumple **alguna** de estas:
- Toca seguridad (tokens, hashing, filtros de autenticación, aislamiento por `user_id`).
- Requiere SQL no trivial: agregaciones, `GROUP BY`, evitar N+1, paginación estable.
- Tiene concurrencia o condiciones de carrera (refresh simultáneo, `loadMore` reentrante).
- Codifica una regla de negocio con ramas (RB-03/RB-04 y su matriz de validaciones).
- **Establece un patrón** que las tareas siguientes van a copiar.
- Un error solo se detecta en producción o es caro de revertir (migraciones).

Manda **Haiku** si:
- Ya existe en el repo un ejemplo casi idéntico que copiar (el segundo CRUD, el tercer formulario).
- El sub-plan ya trae el código, el SQL o la lista literal a escribir.
- Es estructura, boilerplate o configuración declarativa.
- La aceptación se comprueba con un comando (`flutter analyze`, `docker compose up`, un `curl`).

> **Regla de escalado:** si la salida de Haiku falla los criterios de aceptación **dos veces
> seguidas**, no insistas — rehaz la tarea con Sonnet. El tiempo perdido en el tercer intento ya
> cuesta más que la diferencia de precio.
>
> **Regla de orden:** dentro de una fase, ejecuta primero las tareas 🔵 Sonnet. Fijan el patrón que
> luego Haiku replica barato. Al revés, Haiku improvisa un patrón y Sonnet acaba reescribiéndolo.

### Tabla maestra

| Tarea | Modelo | Por qué |
|---|---|---|
| F0.1 Monorepo y README | 🟢 Haiku | Estructura de carpetas y `.gitignore` |
| F0.2 docker-compose + `.env` | 🟢 Haiku | YAML declarativo ya especificado |
| F0.3 Scaffold Spring Boot | 🟡 Mixto | Sonnet: `SecurityConfig`/CORS/OpenAPI. Haiku: deps, `application.yml`, paquetes |
| F0.4 `V1__init.sql` | 🔵 Sonnet | Constraints, FKs e índices; una migración mal hecha es cara de revertir |
| F0.5 Scaffold Flutter | 🟢 Haiku | Árbol de carpetas, tema, router con placeholders |
| F1.1 User + registro + seed | 🟡 Mixto | Sonnet: transaccionalidad, normalización de email, 409. Haiku: entity, repo, DTOs, las 12 categorías |
| F1.2 JWT + refresh + logout | 🔵 Sonnet | Seguridad y rotación de tokens |
| F1.3 Problem Details | 🟡 Mixto | Sonnet: handler + entrypoints de seguridad. Haiku: excepciones tipadas y resto del mapeo |
| F1.4.a Interceptor Dio | 🔵 Sonnet | Refresh concurrente con un solo `Future` compartido |
| F1.4.b Data + providers auth | 🟡 Mixto | Sonnet: `AuthController`/`AuthState`. Haiku: modelos freezed y `auth_api` |
| F1.4.c Pantallas login/registro | 🟢 Haiku | Formularios estándar (excepción: `redirect` del router → Sonnet) |
| F2.1 CRUD accounts + saldo | 🔵 Sonnet | Query de RB-01 en una sola pasada |
| F2.2 CRUD categories | 🟢 Haiku | Calca F2.1 sin la parte de cálculo |
| F2.3 Ajustes en Flutter | 🟢 Haiku | Dos CRUD sobre el patrón ya montado |
| F3.1 CRUD transactions | 🔵 Sonnet | Matriz de validaciones RB-03/RB-04 + revalidación en PUT |
| F3.2 Listado paginado | 🔵 Sonnet | Specifications, orden estable, N+1 |
| F3.3 Formulario de transacción | 🟡 Mixto | Sonnet: controller del form y teclado `Decimal`. Haiku: widgets presentacionales |
| F3.4 Lista con filtros | 🔵 Sonnet | Scroll infinito + debounce + reset de filtros |
| F4.1 Budgets backend | 🔵 Sonnet | Agregación de `spentAmount` y redondeo `BigDecimal` |
| F4.2 Pantalla presupuestos | 🟢 Haiku | Lista + barra; el semáforo viene del backend |
| F5.1 Endpoints de reports | 🔵 Sonnet | 4 agregaciones, serie de meses completa, escapado CSV |
| F5.2 Dashboard | 🟢 Haiku | Compone widgets existentes (excepción: fallo parcial por sección → Sonnet) |
| F5.3 Gráficas + export | 🟡 Mixto | Sonnet: config de `fl_chart` y agrupación "Otros". Haiku: leyenda, botón de export |
| F6.1 Testcontainers | 🟡 Mixto | Sonnet: clase base y aislamiento. Haiku: los casos ya enumerados |
| F6.2 Tests unitarios | 🟢 Haiku | Casos listados uno por uno en el sub-plan |
| F6.3 Widget tests | 🟢 Haiku | Casos listados (excepción: `mock_providers` la primera vez → Sonnet) |
| Linters | 🟢 Haiku | Configuración declarativa |
| F7.1 Dockerfile + compose | 🟢 Haiku | El Dockerfile viene escrito (escala a Sonnet si el build falla) |
| F7.2 README | 🟡 Mixto | Sonnet: "Decisiones de diseño". Haiku: el resto de la estructura |
| F7.3 Colección `.http` | 🟢 Haiku | Repetición mecánica sobre el contrato de §4 |

**Resumen:** 30 tareas — 13 🟢 Haiku · 9 🔵 Sonnet · 8 🟡 Mixto.

El peso de Sonnet se concentra en las fases 1 y 3 (seguridad y núcleo del dominio) y en las queries
de agregación. A partir de la fase 4, con los patrones ya establecidos, la mayoría del trabajo pasa a
ser replicación y el reparto se inclina hacia Haiku.

> Esto es una heurística de coste, no una garantía de calidad. **Los criterios de aceptación de cada
> tarea se verifican igual, sin importar el modelo que la haya escrito.** Si dudas de una asignación
> concreta, sube de modelo: equivocarse hacia arriba solo cuesta dinero, hacia abajo cuesta tiempo.

---

## 6. Reglas de negocio de referencia rápida

| ID | Regla |
|---|---|
| RB-01 | Saldo = `initial_balance + Σ ingresos − Σ gastos ± transferencias`. **No se persiste**, se calcula. |
| RB-02 | Cuenta/categoría con transacciones no se elimina → se archiva (`archived = true`). |
| RB-03 | Una transferencia es **una sola fila** con `transfer_account_id`; se excluye de ingresos/gastos en reportes. |
| RB-04 | Los presupuestos solo aplican a categorías `kind = EXPENSE`. |
| RB-05 | Toda query filtra por el `user_id` del token. |

---

## 7. Glosario

- **Transacción:** movimiento de dinero (ingreso, gasto o transferencia entre cuentas propias).
- **Presupuesto:** límite de gasto para una categoría en un mes específico.
- **Archivar:** soft delete; el registro deja de mostrarse pero conserva historial.
- **yearMonth:** cadena `YYYY-MM` usada como clave de periodo.
