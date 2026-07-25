# Plan Maestro — FinTrack: Gestor de Finanzas Personales

> **Metodología:** Spec-Driven Development. Este documento es la fuente única de verdad (SSOT).
> Cada sección numerada está diseñada para segmentarse en prompts pequeños e independientes para el IDE.
> **Regla de oro:** ningún código contradice este spec; si el spec cambia, se actualiza primero aquí.

---

## 1. Visión y alcance

### 1.1 Objetivo
Aplicación local de finanzas personales para registrar ingresos/gastos, administrar presupuestos mensuales y visualizar reportes. Propósito: aprendizaje full-stack y pieza de portafolio.

### 1.2 Stack tecnológico (fijo)
| Capa | Tecnología | Versión objetivo |
|---|---|---|
| Frontend | Flutter (Dart) | 3.x estable |
| Estado (Flutter) | Riverpod | 2.x |
| Backend | Java + Spring Boot | Java 21, Spring Boot 3.3+ |
| ORM | Spring Data JPA (Hibernate) | — |
| Base de datos | PostgreSQL en Docker | 16 |
| Migraciones | Flyway | — |
| Auth | JWT (access + refresh) | — |
| Docs API | springdoc-openapi (Swagger UI) | — |
| Orquestación local | docker-compose | — |
| Tests backend | JUnit 5 + Testcontainers | — |
| Tests frontend | flutter_test (widget tests) | — |

### 1.3 Restricciones
- **100% local.** Sin servicios cloud. La BD corre en Docker.
- Un solo usuario "real" por instalación, pero el modelo soporta multiusuario (login) para fines de aprendizaje.
- Moneda base configurable (default: MXN). Sin conversión de divisas en v1.
- Idioma UI: español (estructura preparada para i18n).

### 1.4 Fuera de alcance (v1)
- Sincronización multi-dispositivo, modo offline-first.
- Conexión a bancos / scraping.
- Notificaciones push.
- Multi-moneda con tipos de cambio.

---

## 2. Arquitectura

### 2.1 Diagrama lógico
```
┌─────────────────┐     HTTP/JSON      ┌──────────────────────┐      JDBC      ┌────────────┐
│  Flutter App     │ ◄───────────────► │  Spring Boot API      │ ◄────────────► │ PostgreSQL │
│  (mobile/desktop)│   localhost:8080  │  (REST, JWT, Flyway)  │                │  (Docker)  │
└─────────────────┘                    └──────────────────────┘                └────────────┘
```

### 2.2 Backend — arquitectura por capas
```
com.fintrack
├── config/          # Seguridad, CORS, OpenAPI, beans
├── auth/            # Login, registro, refresh, JWT
├── user/            # Perfil de usuario
├── account/         # Cuentas (efectivo, débito, crédito)
├── category/        # Categorías de ingreso/gasto
├── transaction/     # Transacciones (núcleo)
├── budget/          # Presupuestos mensuales
├── report/          # Agregaciones y reportes
└── common/          # DTOs base, excepciones, paginación
```
Cada módulo: `Controller → Service → Repository → Entity` + DTOs con MapStruct (o mapeo manual).

### 2.3 Frontend — estructura Flutter
```
lib/
├── core/            # tema, constantes, http client (dio), interceptores JWT, router (go_router)
├── features/
│   ├── auth/        # login, registro
│   ├── dashboard/   # resumen del mes
│   ├── transactions/# lista, alta, edición, filtros
│   ├── accounts/    # CRUD cuentas
│   ├── categories/  # CRUD categorías
│   ├── budgets/     # presupuestos y alertas
│   └── reports/     # gráficas (fl_chart)
└── shared/          # widgets reutilizables, formatters (moneda, fecha)
```
Cada feature: `data/ (api + models) → providers/ (Riverpod) → presentation/ (screens + widgets)`.

### 2.4 Convenciones transversales
- API versionada: prefijo `/api/v1`.
- JSON en `camelCase`; fechas en ISO-8601 (`yyyy-MM-dd` para fechas, UTC para timestamps).
- Montos como `DECIMAL(14,2)` en BD, `BigDecimal` en Java, `String`→`Decimal` en Dart (paquete `decimal`). **Nunca float/double para dinero.**
- Errores API con formato uniforme (RFC 7807 Problem Details).
- IDs: `UUID` v4.

---

## 3. Modelo de datos

### 3.1 Diagrama entidad-relación (texto)
```
users 1───N accounts 1───N transactions N───1 categories
users 1───N categories
users 1───N budgets N───1 categories
transactions (transfer) ──► referencia opcional a cuenta destino
```

### 3.2 Tablas

**users**
| columna | tipo | notas |
|---|---|---|
| id | UUID PK | |
| email | VARCHAR(255) UNIQUE NOT NULL | |
| password_hash | VARCHAR(255) NOT NULL | BCrypt |
| name | VARCHAR(100) NOT NULL | |
| base_currency | CHAR(3) NOT NULL DEFAULT 'MXN' | |
| created_at | TIMESTAMPTZ NOT NULL | |

**accounts**
| columna | tipo | notas |
|---|---|---|
| id | UUID PK | |
| user_id | UUID FK→users NOT NULL | |
| name | VARCHAR(100) NOT NULL | único por usuario |
| type | VARCHAR(20) NOT NULL | ENUM: CASH, DEBIT, CREDIT, SAVINGS |
| initial_balance | DECIMAL(14,2) NOT NULL DEFAULT 0 | |
| archived | BOOLEAN NOT NULL DEFAULT false | soft delete |
| created_at | TIMESTAMPTZ NOT NULL | |

**categories**
| columna | tipo | notas |
|---|---|---|
| id | UUID PK | |
| user_id | UUID FK→users NOT NULL | |
| name | VARCHAR(60) NOT NULL | único por usuario+tipo |
| kind | VARCHAR(10) NOT NULL | ENUM: INCOME, EXPENSE |
| color | CHAR(7) NOT NULL | hex, ej. `#4CAF50` |
| icon | VARCHAR(40) NOT NULL | nombre de icono Material |
| archived | BOOLEAN NOT NULL DEFAULT false | |

Al registrar un usuario se siembran categorías default (Comida, Transporte, Renta, Salario, etc.).

**transactions**
| columna | tipo | notas |
|---|---|---|
| id | UUID PK | |
| user_id | UUID FK→users NOT NULL | |
| account_id | UUID FK→accounts NOT NULL | |
| category_id | UUID FK→categories NULL | NULL solo si type=TRANSFER |
| type | VARCHAR(10) NOT NULL | ENUM: INCOME, EXPENSE, TRANSFER |
| amount | DECIMAL(14,2) NOT NULL CHECK (amount > 0) | signo lo define `type` |
| transfer_account_id | UUID FK→accounts NULL | solo TRANSFER |
| date | DATE NOT NULL | |
| note | VARCHAR(255) NULL | |
| created_at / updated_at | TIMESTAMPTZ | |

Índices: `(user_id, date)`, `(account_id)`, `(category_id)`.

**budgets**
| columna | tipo | notas |
|---|---|---|
| id | UUID PK | |
| user_id | UUID FK→users NOT NULL | |
| category_id | UUID FK→categories NOT NULL | solo kind=EXPENSE |
| year_month | CHAR(7) NOT NULL | formato `2026-07` |
| limit_amount | DECIMAL(14,2) NOT NULL CHECK (> 0) | |
| UNIQUE(user_id, category_id, year_month) | | |

**refresh_tokens**
| columna | tipo | notas |
|---|---|---|
| id | UUID PK | |
| user_id | UUID FK→users NOT NULL | |
| token_hash | VARCHAR(255) NOT NULL | |
| expires_at | TIMESTAMPTZ NOT NULL | |
| revoked | BOOLEAN NOT NULL DEFAULT false | |

### 3.3 Reglas de negocio del modelo
- RB-01: El saldo de una cuenta = `initial_balance + Σ ingresos − Σ gastos ± transferencias`. **No se persiste**; se calcula en query/servicio.
- RB-02: No se puede eliminar una cuenta/categoría con transacciones → se archiva (`archived=true`).
- RB-03: Una transferencia genera **una sola fila** con `transfer_account_id`; el reporte la excluye de ingresos/gastos.
- RB-04: Presupuestos solo aplican a categorías `EXPENSE`.
- RB-05: Todas las queries filtran por `user_id` del token (aislamiento de datos).

---

## 4. Contrato de API (REST, `/api/v1`)

### 4.1 Auth
| Método | Ruta | Body | Respuesta | Notas |
|---|---|---|---|---|
| POST | `/auth/register` | `{email, password, name}` | 201 `{user, tokens}` | valida email único, password ≥8 |
| POST | `/auth/login` | `{email, password}` | 200 `{user, tokens}` | |
| POST | `/auth/refresh` | `{refreshToken}` | 200 `{tokens}` | rota el refresh token |
| POST | `/auth/logout` | `{refreshToken}` | 204 | revoca token |

`tokens = {accessToken (15 min), refreshToken (7 días)}`. Access token en header `Authorization: Bearer`.

### 4.2 Accounts
| Método | Ruta | Notas |
|---|---|---|
| GET | `/accounts` | incluye `currentBalance` calculado; query `?includeArchived=` |
| POST | `/accounts` | |
| GET/PUT | `/accounts/{id}` | |
| DELETE | `/accounts/{id}` | archiva (RB-02) |

### 4.3 Categories
| Método | Ruta | Notas |
|---|---|---|
| GET | `/categories?kind=INCOME\|EXPENSE` | |
| POST / PUT / DELETE | `/categories[/{id}]` | DELETE archiva |

### 4.4 Transactions
| Método | Ruta | Notas |
|---|---|---|
| GET | `/transactions` | paginado (`page,size,sort`), filtros: `from,to,accountId,categoryId,type,search` |
| POST | `/transactions` | valida RB-03/RB-04 |
| GET/PUT/DELETE | `/transactions/{id}` | DELETE es hard delete |

### 4.5 Budgets
| Método | Ruta | Notas |
|---|---|---|
| GET | `/budgets?yearMonth=2026-07` | incluye `spentAmount` y `percentUsed` calculados |
| PUT | `/budgets` | upsert por `(categoryId, yearMonth)` |
| DELETE | `/budgets/{id}` | |

### 4.6 Reports
| Método | Ruta | Respuesta |
|---|---|---|
| GET | `/reports/summary?yearMonth=` | `{totalIncome, totalExpense, net, byAccount[]}` |
| GET | `/reports/by-category?yearMonth=&kind=` | `[{categoryId, name, color, total, percent}]` |
| GET | `/reports/trend?months=6` | `[{yearMonth, income, expense}]` |
| GET | `/reports/export?from=&to=` | CSV descargable de transacciones |

### 4.7 Formato de error (todas las rutas)
```json
{ "type": "about:blank", "title": "Validation failed", "status": 400,
  "detail": "amount must be greater than 0", "instance": "/api/v1/transactions",
  "errors": [{"field": "amount", "message": "must be greater than 0"}] }
```

---

## 5. Especificación de UI (Flutter)

### 5.1 Navegación (go_router)
```
/login  /register
/  (shell con bottom nav)
├── /dashboard
├── /transactions  → /transactions/new  → /transactions/:id
├── /budgets
├── /reports
└── /settings  → /settings/accounts  → /settings/categories
```

### 5.2 Pantallas
1. **Login / Registro** — formularios con validación; guarda tokens en `flutter_secure_storage`.
2. **Dashboard** — tarjeta de balance total, resumen del mes (ingreso/gasto/neto), top 3 presupuestos más consumidos con barra de progreso, últimas 5 transacciones, FAB "+".
3. **Transacciones** — lista agrupada por día, buscador y filtros (chips), scroll infinito (paginación), swipe para eliminar con confirmación.
4. **Alta/edición de transacción** — selector tipo (gasto/ingreso/transferencia), teclado numérico de monto, selector de categoría en grid con iconos/colores, cuenta, fecha, nota.
5. **Presupuestos** — selector de mes, lista de categorías con `gastado / límite` y barra de progreso; colores: <70% verde, 70–99% ámbar, ≥100% rojo.
6. **Reportes** — dona por categoría (fl_chart), barras de tendencia 6 meses, botón exportar CSV.
7. **Ajustes** — perfil, CRUD de cuentas y categorías, cerrar sesión.

### 5.3 Reglas UX
- Montos siempre formateados con `intl` (es_MX): `$1,234.50`.
- Estados de carga con skeletons; errores con snackbar + retry.
- Tema claro/oscuro con Material 3.

---

## 6. Infraestructura local

### 6.1 docker-compose.yml (spec)
- Servicio `db`: postgres:16, puerto 5432, volumen nombrado, healthcheck.
- Servicio `api`: build del Dockerfile del backend, puerto 8080, depende de `db` (condition: service_healthy), variables por `.env`.
- Perfil alternativo de desarrollo: solo levantar `db` y correr Spring desde el IDE.

### 6.2 Variables de entorno (`.env.example`)
```
POSTGRES_DB=fintrack
POSTGRES_USER=fintrack
POSTGRES_PASSWORD=changeme
JWT_SECRET=<generar-256-bits>
JWT_ACCESS_TTL_MIN=15
JWT_REFRESH_TTL_DAYS=7
```

### 6.3 Migraciones Flyway
`V1__init.sql` (tablas §3.2) → `V2__seed_categories.sql` (función/lógica de categorías default) → siguientes numeradas.

---

## 7. Calidad

- **Backend:** tests unitarios de servicios (reglas RB-01..RB-05), tests de integración de controllers con Testcontainers (Postgres real). Cobertura objetivo: servicios ≥80%.
- **Frontend:** widget tests de formularios (validación de monto, campos requeridos) y del formato de moneda; golden test opcional del dashboard.
- **Linters:** Spotless + Checkstyle (backend), `flutter_lints` (frontend).
- **Definition of Done por tarea:** compila, tests pasan, endpoint documentado en Swagger, spec actualizado si hubo cambios.

---

## 8. Roadmap por fases (unidad de segmentación para prompts)

Cada tarea (`Fx.y`) está pensada para ser un prompt independiente al IDE. Orden estricto dentro de cada fase; las fases 5–7 pueden intercalarse.

### Fase 0 — Cimientos
- **F0.1** Crear repo monorepo: `/backend`, `/app`, `/docker`, README raíz.
- **F0.2** `docker-compose.yml` + `.env.example` con Postgres (§6).
- **F0.3** Scaffold Spring Boot (deps: web, data-jpa, security, validation, flyway, postgres, springdoc, lombok) con healthcheck `/actuator/health`.
- **F0.4** Migración `V1__init.sql` con todas las tablas (§3.2).
- **F0.5** Scaffold Flutter (deps: riverpod, go_router, dio, flutter_secure_storage, intl, fl_chart, decimal) + tema + estructura de carpetas (§2.3).

### Fase 1 — Autenticación
- **F1.1** Backend: entidad User + registro con BCrypt + seed de categorías default.
- **F1.2** Backend: login + emisión JWT + filtro de seguridad + refresh/logout (§4.1).
- **F1.3** Backend: manejo global de errores (Problem Details §4.7).
- **F1.4** Flutter: pantallas login/registro + storage seguro de tokens + interceptor dio (refresh automático).

### Fase 2 — Cuentas y categorías
- **F2.1** Backend: CRUD accounts con saldo calculado (RB-01, RB-02).
- **F2.2** Backend: CRUD categories (RB-02).
- **F2.3** Flutter: pantallas de ajustes con CRUD de cuentas y categorías.

### Fase 3 — Transacciones (núcleo)
- **F3.1** Backend: POST/PUT/DELETE transaction con validaciones (RB-03, RB-04).
- **F3.2** Backend: GET paginado con filtros (§4.4).
- **F3.3** Flutter: pantalla de alta/edición (§5.2.4).
- **F3.4** Flutter: lista con filtros, búsqueda y paginación infinita.

### Fase 4 — Presupuestos
- **F4.1** Backend: upsert + GET con `spentAmount` calculado (§4.5).
- **F4.2** Flutter: pantalla de presupuestos con barras de progreso y colores (§5.2.5).

### Fase 5 — Dashboard y reportes
- **F5.1** Backend: endpoints de reports (§4.6) con queries de agregación.
- **F5.2** Flutter: dashboard (§5.2.2).
- **F5.3** Flutter: pantalla de reportes con fl_chart + descarga CSV.

### Fase 6 — Calidad
- **F6.1** Tests de integración backend con Testcontainers (auth + transactions).
- **F6.2** Tests unitarios de servicios (budgets/reports).
- **F6.3** Widget tests Flutter (formulario de transacción, formato moneda).

### Fase 7 — Portafolio
- **F7.1** Dockerfile multistage del backend + compose completo (un comando levanta todo).
- **F7.2** README con screenshots, diagrama, GIF de demo, instrucciones de arranque.
- **F7.3** Colección de ejemplos (archivo `.http` o export de Swagger).

---

## 9. Glosario
- **Transacción:** movimiento de dinero (ingreso, gasto o transferencia entre cuentas propias).
- **Presupuesto:** límite de gasto para una categoría en un mes específico.
- **Archivar:** soft delete; el registro deja de mostrarse pero conserva historial.
- **yearMonth:** cadena `YYYY-MM` usada como clave de periodo.

---

## 10. Control de cambios del spec
| Fecha | Versión | Cambio |
|---|---|---|
| 2026-07-25 | 1.0 | Versión inicial |
