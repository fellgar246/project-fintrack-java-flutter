# 01 — Cimientos (Fase 0)

> Cubre **F0.1 – F0.5** del [plan maestro](../PLAN_MAESTRO_FINTRACK.md) §8.
> Convenciones: [`00-INDICE-Y-CONVENCIONES.md`](00-INDICE-Y-CONVENCIONES.md).

## Objetivo

Al terminar este sub-plan:
- El monorepo existe con la estructura `/backend`, `/app`, `/docker`.
- `docker compose up db` levanta Postgres 16 sano.
- El backend arranca, se conecta a la BD, corre Flyway y responde `GET /actuator/health` → `{"status":"UP"}`.
- Todas las tablas de §3.2 existen en la BD.
- La app Flutter compila y muestra una pantalla placeholder con el tema Material 3.

**Aún NO hay:** ni auth, ni endpoints de negocio, ni pantallas reales.

## Prerrequisitos

- Java 21 (`java -version`), Docker Desktop corriendo, Flutter 3.x (`flutter doctor` sin errores rojos).

## Reparto de modelos

Criterio completo en [§5 del índice](00-INDICE-Y-CONVENCIONES.md#5-reparto-de-modelos-haiku-vs-sonnet).
**Ejecuta F0.4 antes que el resto del backend**: es la que fija el esquema del que todo lo demás depende.

| Tarea | Modelo |
|---|---|
| F0.1 Monorepo y README | 🟢 Haiku |
| F0.2 docker-compose + `.env` | 🟢 Haiku |
| F0.3 Scaffold Spring Boot | 🟡 Mixto |
| F0.4 `V1__init.sql` | 🔵 Sonnet |
| F0.5 Scaffold Flutter | 🟢 Haiku |

---

## F0.1 — Monorepo y README raíz

> **Modelo: 🟢 Haiku.** Estructura de carpetas, `.gitignore` y un README esqueleto. Nada que decidir;
> la aceptación se comprueba con `git status`.

**Qué crear**

```
fintrack-java-flutter/
├── backend/          # (vacío por ahora, lo llena F0.3)
├── app/              # (vacío por ahora, lo llena F0.5)
├── docker/           # docker-compose.yml, .env.example
├── plans/            # estos sub-planes
├── .gitignore
├── README.md
└── PLAN_MAESTRO_FINTRACK.md
```

- `git init` + primer commit.
- `.gitignore` combinado: Java/Gradle (`build/`, `.gradle/`), Flutter (`.dart_tool/`, `build/`,
  `*.iml`), IDE (`.idea/`, `.vscode/`), macOS (`.DS_Store`) y **`.env`** (nunca versionado).
- `README.md` raíz mínimo: qué es el proyecto, stack (tabla §1.2), cómo levantar (se completa en F7.2).

**Aceptación**
- [ ] `git status` limpio tras el primer commit.
- [ ] `.env` está ignorado y `.env.example` sí versionado.

---

## F0.2 — docker-compose + variables de entorno

> **Modelo: 🟢 Haiku.** YAML declarativo con la spec de §6.1 ya cerrada. Se valida solo:
> el contenedor queda `healthy` o no.

**Qué crear:** `docker/docker-compose.yml`, `docker/.env.example`.

**Spec (§6.1):**

- Servicio `db`:
  - imagen `postgres:16`
  - puerto `5432:5432`
  - volumen nombrado `fintrack_pgdata:/var/lib/postgresql/data`
  - variables desde `.env`: `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`
  - `healthcheck`: `pg_isready -U $POSTGRES_USER -d $POSTGRES_DB`, interval 5s, retries 10
- Servicio `api`: **declarado pero comentado o bajo profile `full`**, porque el Dockerfile llega hasta F7.1.
  Depende de `db` con `condition: service_healthy`, expone `8080`.
- Perfil de desarrollo (default): solo `db` levantado; Spring se corre desde el IDE.

`docker/.env.example` (§6.2):
```
POSTGRES_DB=fintrack
POSTGRES_USER=fintrack
POSTGRES_PASSWORD=changeme
JWT_SECRET=<generar-256-bits>
JWT_ACCESS_TTL_MIN=15
JWT_REFRESH_TTL_DAYS=7
```

Documenta en el README cómo generar el secreto: `openssl rand -base64 48`.

**Aceptación**
- [ ] `cp docker/.env.example docker/.env` y `docker compose -f docker/docker-compose.yml up -d db` deja el contenedor en estado `healthy`.
- [ ] `psql` o cualquier cliente conecta a `localhost:5432` con esas credenciales.
- [ ] `docker compose down` sin `-v` conserva los datos al volver a levantar.

---

## F0.3 — Scaffold Spring Boot

> **Modelo: 🟡 Mixto.**
> - 🟢 **Haiku:** lista de dependencias, `application.yml`, árbol de paquetes con `package-info.java`.
> - 🔵 **Sonnet:** `SecurityConfig`, `CorsConfig` y `OpenApiConfig`. Son la base sobre la que F1.2
>   monta el filtro JWT; si el `SecurityFilterChain` queda mal armado aquí, el problema aparece dos
>   fases más tarde disfrazado de "el token no funciona".

**Qué crear:** proyecto en `/backend`, Gradle (Kotlin DSL) o Maven — elige uno y no lo mezcles.

**Dependencias:** `spring-boot-starter-web`, `spring-boot-starter-data-jpa`,
`spring-boot-starter-security`, `spring-boot-starter-validation`, `spring-boot-starter-actuator`,
`flyway-core`, `flyway-database-postgresql`, `postgresql` (runtime), `springdoc-openapi-starter-webmvc-ui`,
`lombok`, y para test: `spring-boot-starter-test`, `testcontainers:postgresql`, `spring-boot-testcontainers`.

**Configuración esperada**

`backend/src/main/resources/application.yml`:
```yaml
spring:
  application:
    name: fintrack-api
  datasource:
    url: ${DB_URL:jdbc:postgresql://localhost:5432/fintrack}
    username: ${POSTGRES_USER:fintrack}
    password: ${POSTGRES_PASSWORD:changeme}
  jpa:
    hibernate:
      ddl-auto: validate      # Flyway manda; Hibernate solo valida
    open-in-view: false
    properties:
      hibernate.jdbc.time_zone: UTC
  flyway:
    enabled: true
    locations: classpath:db/migration

server:
  servlet:
    context-path: /api/v1

management:
  endpoints:
    web:
      exposure:
        include: health,info

app:
  jwt:
    secret: ${JWT_SECRET:dev-secret-cambiar}
    access-ttl-min: ${JWT_ACCESS_TTL_MIN:15}
    refresh-ttl-days: ${JWT_REFRESH_TTL_DAYS:7}
```

> `ddl-auto: validate` es intencional: si una entidad y su migración divergen, la app **falla al
> arrancar** en vez de corromper el esquema en silencio.

**Clases de config iniciales** (`com.fintrack.config`):
- `SecurityConfig`: por ahora `permitAll()` en `/actuator/**`, `/swagger-ui/**`, `/v3/api-docs/**`;
  el resto autenticado. CSRF deshabilitado (API stateless), sesión `STATELESS`.
- `CorsConfig`: permitir `http://localhost:*` para el cliente Flutter web/desktop en desarrollo.
- `OpenApiConfig`: título "FinTrack API", versión 1.0, esquema de seguridad `bearerAuth` declarado
  (aún sin usar).
- Crear los paquetes vacíos de §2.2 con un `package-info.java` cada uno para que la estructura quede fijada.

**Aceptación**
- [ ] `./gradlew bootRun` arranca contra el Postgres de F0.2.
- [ ] `GET http://localhost:8080/api/v1/actuator/health` → `{"status":"UP"}`.
- [ ] Swagger UI accesible y sin endpoints de negocio todavía.
- [ ] Árbol de paquetes `config, auth, user, account, category, transaction, budget, report, common` creado.

---

## F0.4 — Migración `V1__init.sql`

> **Modelo: 🔵 Sonnet.** Aunque las tablas están dictadas en §3.2, aquí se deciden los `CHECK`
> compuestos, la política de `ON DELETE` y los índices. Una migración ya aplicada **no se edita**:
> se corrige con otra migración encima. Es la tarea de la fase 0 con el error más caro.

**Qué crear:** `backend/src/main/resources/db/migration/V1__init.sql` con **todas** las tablas de §3.2.

Contenido requerido (respeta tipos y constraints exactos):

- `users` — `id UUID PK`, `email VARCHAR(255) UNIQUE NOT NULL`, `password_hash VARCHAR(255) NOT NULL`,
  `name VARCHAR(100) NOT NULL`, `base_currency CHAR(3) NOT NULL DEFAULT 'MXN'`, `created_at TIMESTAMPTZ NOT NULL`.
- `accounts` — FK a `users`, `type VARCHAR(20) NOT NULL` + `CHECK (type IN ('CASH','DEBIT','CREDIT','SAVINGS'))`,
  `initial_balance DECIMAL(14,2) NOT NULL DEFAULT 0`, `archived BOOLEAN NOT NULL DEFAULT false`,
  `UNIQUE (user_id, name)`.
- `categories` — FK a `users`, `kind VARCHAR(10) NOT NULL CHECK (kind IN ('INCOME','EXPENSE'))`,
  `color CHAR(7) NOT NULL`, `icon VARCHAR(40) NOT NULL`, `archived BOOLEAN NOT NULL DEFAULT false`,
  `UNIQUE (user_id, name, kind)`.
- `transactions` — FKs a `users`, `accounts`, `categories` (nullable), `transfer_account_id` nullable,
  `type VARCHAR(10) NOT NULL CHECK (type IN ('INCOME','EXPENSE','TRANSFER'))`,
  `amount DECIMAL(14,2) NOT NULL CHECK (amount > 0)`, `date DATE NOT NULL`, `note VARCHAR(255)`,
  `created_at`/`updated_at TIMESTAMPTZ NOT NULL`.
  - Constraint de coherencia (materializa RB-03/RB-04 en la BD):
    ```sql
    CONSTRAINT chk_tx_shape CHECK (
      (type = 'TRANSFER' AND category_id IS NULL AND transfer_account_id IS NOT NULL
                        AND transfer_account_id <> account_id)
      OR
      (type IN ('INCOME','EXPENSE') AND category_id IS NOT NULL AND transfer_account_id IS NULL)
    )
    ```
  - Índices: `idx_tx_user_date (user_id, date)`, `idx_tx_account (account_id)`, `idx_tx_category (category_id)`.
- `budgets` — FKs a `users` y `categories`, `year_month CHAR(7) NOT NULL CHECK (year_month ~ '^\d{4}-\d{2}$')`,
  `limit_amount DECIMAL(14,2) NOT NULL CHECK (limit_amount > 0)`, `UNIQUE (user_id, category_id, year_month)`.
- `refresh_tokens` — FK a `users`, `token_hash VARCHAR(255) NOT NULL`, `expires_at TIMESTAMPTZ NOT NULL`,
  `revoked BOOLEAN NOT NULL DEFAULT false`, índice por `token_hash`.

Reglas: `ON DELETE CASCADE` desde `users` hacia todo lo suyo; `ON DELETE RESTRICT` de
`transactions` hacia `accounts`/`categories` (la app archiva, no borra — RB-02).

**Aceptación**
- [ ] Al arrancar, Flyway aplica `V1` y `flyway_schema_history` muestra `success = true`.
- [ ] `\d+` en psql confirma tipos, checks e índices.
- [ ] Insertar manualmente una transacción `TRANSFER` con `category_id` no nulo **falla** por `chk_tx_shape`.
- [ ] Segundo arranque no reaplica la migración.

---

## F0.5 — Scaffold Flutter

> **Modelo: 🟢 Haiku.** Árbol de carpetas, tema Material 3, router con placeholders y un formatter.
> Todo está enumerado abajo y `flutter analyze` + `flutter run` dicen si está bien.

**Qué crear:** proyecto en `/app`.

**Dependencias:** `flutter_riverpod`, `go_router`, `dio`, `flutter_secure_storage`, `intl`,
`fl_chart`, `decimal`, `freezed_annotation`, `json_annotation`; dev: `build_runner`, `freezed`,
`json_serializable`, `flutter_lints`.

**Estructura (§2.3)** — créala completa aunque quede vacía:
```
app/lib/
├── main.dart
├── core/
│   ├── theme/app_theme.dart        # Material 3, esquema claro + oscuro
│   ├── constants/api_constants.dart # baseUrl = http://localhost:8080/api/v1
│   ├── network/dio_client.dart     # Dio configurado (interceptores llegan en F1.4)
│   └── router/app_router.dart      # go_router con rutas de §5.1, pantallas placeholder
├── features/
│   ├── auth/{data,providers,presentation}/
│   ├── dashboard/{...}
│   ├── transactions/{...}
│   ├── accounts/{...}
│   ├── categories/{...}
│   ├── budgets/{...}
│   └── reports/{...}
└── shared/
    ├── widgets/
    └── formatters/money_formatter.dart   # intl es_MX → $1,234.50
```

Detalles:
- `main.dart` envuelve la app en `ProviderScope` y usa `MaterialApp.router`.
- `app_theme.dart`: `ColorScheme.fromSeed`, `useMaterial3: true`, tema claro y oscuro, `themeMode: system`.
- `money_formatter.dart`: recibe `Decimal`, devuelve `String` con `NumberFormat.currency(locale: 'es_MX', symbol: r'$')`.
- Router: shell con bottom nav (dashboard, transactions, budgets, reports, settings) + rutas
  `/login` y `/register` fuera del shell. Cada destino es un `Scaffold` con el nombre de la pantalla.
- **Nota Android:** para emulador el backend no es `localhost` sino `10.0.2.2`. Deja `apiBaseUrl`
  configurable por `--dart-define` con default `http://localhost:8080/api/v1`.

**Aceptación**
- [ ] `flutter analyze` sin issues.
- [ ] `flutter run` levanta la app y la bottom nav navega entre los 5 placeholders.
- [ ] Cambiar el tema del sistema alterna claro/oscuro.
- [ ] `MoneyFormatter.format(Decimal.parse('1234.5'))` devuelve `$1,234.50`.

---

## Prompt sugerido por tarea

Antes de lanzarlo, cambia al modelo que indica la anotación de esa tarea.

> Lee `plans/01-CIMIENTOS.md` y `plans/00-INDICE-Y-CONVENCIONES.md`. Implementa **solo la tarea F0.X**
> tal como está especificada, sin adelantar trabajo de tareas posteriores. Al terminar, verifica uno
> por uno los criterios de aceptación de esa tarea y repórtame el resultado real de cada uno.

## Cierre de fase

- [ ] Los 5 checklists (F0.1–F0.5) completos.
- [ ] Un solo comando documentado levanta la BD; el backend arranca desde el IDE; la app corre.
- [ ] Commit/tag `fase-0-cimientos`.

**Siguiente:** [`02-AUTH-BACKEND.md`](02-AUTH-BACKEND.md).
