# 02 — Autenticación: backend (Fase 1, parte backend)

> Cubre **F1.1 – F1.3** del [plan maestro](../PLAN_MAESTRO_FINTRACK.md) (§4.1, §4.7, §3.2).
> Convenciones: [`00-INDICE-Y-CONVENCIONES.md`](00-INDICE-Y-CONVENCIONES.md).

## Objetivo

Un usuario puede registrarse, iniciar sesión, refrescar su sesión y cerrarla. A partir de aquí,
**todo endpoint de negocio exige un access token válido** y el `userId` sale del token (RB-05).
Además, todos los errores de la API salen ya en formato Problem Details.

## Prerrequisitos

- [`01-CIMIENTOS.md`](01-CIMIENTOS.md) completo: `V1__init.sql` aplicado (tablas `users`, `categories`,
  `refresh_tokens`), Spring arranca, Swagger accesible.

## Reparto de modelos

Criterio completo en [§5 del índice](00-INDICE-Y-CONVENCIONES.md#5-reparto-de-modelos-haiku-vs-sonnet).
**Esta es la fase con más peso de Sonnet de todo el proyecto:** es la única que toca seguridad, y un
fallo aquí no lo detecta ningún test funcional, solo un atacante.

| Tarea | Modelo |
|---|---|
| F1.1 User + registro + seed | 🟡 Mixto |
| F1.2 JWT, refresh y logout | 🔵 Sonnet |
| F1.3 Problem Details | 🟡 Mixto |

---

## F1.1 — Entidad User, registro y seed de categorías

> **Modelo: 🟡 Mixto.**
> - 🟢 **Haiku:** `User`, `UserRepository`, los DTOs, `PasswordConfig` y la tabla literal de 12
>   categorías en `CategorySeedService`. Todo está dictado abajo.
> - 🔵 **Sonnet:** `AuthService`. Necesita decidir la frontera transaccional (usuario + seed en una
>   sola transacción), la normalización del email antes de comprobar unicidad, y traducir la
>   violación de `UNIQUE` a un 409 en vez de dejar escapar un 500.

**Archivos**

```
com.fintrack.user/
├── User.java                 # @Entity, tabla users
├── UserRepository.java       # findByEmail, existsByEmail
└── dto/UserResponse.java     # id, email, name, baseCurrency, createdAt
com.fintrack.auth/
├── AuthController.java       # POST /auth/register (por ahora)
├── AuthService.java
└── dto/{RegisterRequest, AuthResponse, TokensResponse}.java
com.fintrack.category/
└── CategorySeedService.java  # siembra categorías default
com.fintrack.config/
└── PasswordConfig.java       # bean BCryptPasswordEncoder
```

**Reglas**

- `POST /auth/register` body `{email, password, name}`:
  - `email`: `@Email`, obligatorio, se normaliza a **minúsculas + trim** antes de validar unicidad.
  - `password`: mínimo 8 caracteres. Se guarda **solo** el hash BCrypt (strength 10+).
  - Email duplicado → **409 Conflict** con Problem Details (no 500 por violación de unique).
  - `baseCurrency` = `MXN` por defecto.
  - Respuesta **201** `{user, tokens}` (los tokens los emite F1.2; hasta entonces devuelve el user
    y deja el emisor de tokens detrás de una interfaz `TokenService`).
- **El hash nunca sale en ninguna respuesta.** `UserResponse` no tiene ese campo, punto.
- Seed de categorías (§3.2): en la **misma transacción** del registro se insertan las default del usuario.

**Categorías default a sembrar**

| kind | name | icon (Material) | color |
|---|---|---|---|
| EXPENSE | Comida | `restaurant` | `#FF7043` |
| EXPENSE | Transporte | `directions_bus` | `#42A5F5` |
| EXPENSE | Renta | `home` | `#8D6E63` |
| EXPENSE | Servicios | `bolt` | `#FFCA28` |
| EXPENSE | Salud | `local_hospital` | `#EF5350` |
| EXPENSE | Entretenimiento | `movie` | `#AB47BC` |
| EXPENSE | Compras | `shopping_bag` | `#26A69A` |
| EXPENSE | Educación | `school` | `#5C6BC0` |
| INCOME | Salario | `payments` | `#4CAF50` |
| INCOME | Freelance | `work` | `#66BB6A` |
| INCOME | Inversiones | `trending_up` | `#9CCC65` |
| INCOME | Otros ingresos | `add_circle` | `#26C6DA` |

Impleméntalo en Java (`CategorySeedService`), **no** en SQL: la lista es lógica de aplicación y
necesita el `user_id` recién creado. La migración `V2__seed_categories.sql` mencionada en §6.3 queda
sin efecto práctico; si prefieres SQL, hazlo con una función y déjalo documentado en el maestro.

**Aceptación**
- [ ] `POST /auth/register` con datos válidos → 201, y en BD el usuario tiene 12 categorías.
- [ ] Mismo email otra vez (incluso con distinta capitalización) → 409.
- [ ] Password de 7 caracteres → 400 con el campo `password` en `errors[]`.
- [ ] `password_hash` empieza con `$2a$`/`$2b$` y no aparece en ninguna respuesta JSON.
- [ ] Si el seed falla, el usuario **no** queda creado (rollback verificable).

---

## F1.2 — Login, JWT, filtro de seguridad, refresh y logout

> **Modelo: 🔵 Sonnet. Sin excepciones, ni siquiera para los DTOs.** Es criptografía aplicada más
> gestión de estado de sesión: firma y validación HS256, hash del refresh token, rotación con
> revocación del anterior, respuestas que no filtren si un email existe, y un filtro que se integra
> con el `SecurityFilterChain` de F0.3. Los errores de esta tarea son silenciosos —el sistema
> "funciona" igual con un JWT mal validado— y es lo primero que mira cualquiera que revise el
> proyecto como pieza de portafolio.

**Archivos**

```
com.fintrack.auth/
├── jwt/JwtService.java           # firma/valida access tokens (HS256)
├── jwt/JwtAuthFilter.java        # OncePerRequestFilter
├── RefreshToken.java             # @Entity tabla refresh_tokens
├── RefreshTokenRepository.java
├── RefreshTokenService.java      # emitir, validar, rotar, revocar
└── dto/{LoginRequest, RefreshRequest, LogoutRequest}.java
com.fintrack.config/
├── SecurityConfig.java           # actualizada
└── CurrentUser.java + CurrentUserArgumentResolver.java  (o usar @AuthenticationPrincipal)
```

**Contrato (§4.1)**

| Método | Ruta | Body | Respuesta |
|---|---|---|---|
| POST | `/auth/login` | `{email, password}` | 200 `{user, tokens}` |
| POST | `/auth/refresh` | `{refreshToken}` | 200 `{tokens}` |
| POST | `/auth/logout` | `{refreshToken}` | 204 |

`tokens = {accessToken, refreshToken}`. Access **15 min**, refresh **7 días** (TTLs por `.env`).

**Reglas**

- Access token JWT HS256. Claims: `sub` = userId (UUID como string), `email`, `iat`, `exp`.
  Secreto desde `app.jwt.secret`; si mide menos de 256 bits, **falla al arrancar** (no lo toleres en silencio).
- Refresh token: cadena aleatoria de 256 bits (`SecureRandom` + Base64 URL). En BD se guarda **solo su
  hash** (SHA-256); el valor plano existe únicamente en la respuesta.
- `/auth/refresh` **rota**: valida (existe, no revocado, no expirado), marca el viejo como `revoked = true`
  y emite uno nuevo. Reusar un refresh ya rotado → 401.
- `/auth/logout` marca el token como revocado. Idempotente: token inexistente también responde 204.
- Login fallido → **401** con mensaje genérico `"Credenciales inválidas"`. No reveles si el email existe.
- `JwtAuthFilter`: lee `Authorization: Bearer <token>`, valida, y pone en el `SecurityContext` un
  principal que expone el `userId`. Token inválido/expirado → 401 en Problem Details (no un HTML de error).
- `SecurityConfig`: `STATELESS`, CSRF off, `permitAll` en `/auth/**`, `/actuator/health`,
  `/swagger-ui/**`, `/v3/api-docs/**`; **todo lo demás autenticado**.
- Los servicios de negocio reciben el `userId` como parámetro; **ningún** controller acepta `userId`
  desde el cliente (RB-05).
- OpenAPI: declara el esquema `bearerAuth` para poder probar desde Swagger con el botón *Authorize*.

**Aceptación**
- [ ] Login correcto → 200 con ambos tokens; login con password mala → 401 genérico.
- [ ] Llamar a un endpoint protegido sin token → 401; con token válido → 200.
- [ ] Token manipulado (un carácter cambiado en la firma) → 401.
- [ ] Refresh devuelve tokens nuevos y **el anterior deja de funcionar**.
- [ ] Logout revoca; el refresh revocado da 401; segundo logout → 204.
- [ ] Arrancar con `JWT_SECRET` corto aborta el arranque con mensaje claro.
- [ ] Con *Authorize* en Swagger se pueden probar endpoints protegidos.

---

## F1.3 — Manejo global de errores (Problem Details)

> **Modelo: 🟡 Mixto.**
> - 🔵 **Sonnet:** el `GlobalExceptionHandler` y, sobre todo, el `AuthenticationEntryPoint` y el
>   `AccessDeniedHandler`. Los 401/403 nacen **dentro del filtro de seguridad**, antes de que exista
>   un controller, así que `@RestControllerAdvice` no los captura. Ese detalle es el que hace que
>   este handler se implemente mal la primera vez.
> - 🟢 **Haiku:** las excepciones tipadas (`NotFoundException`, `ConflictException`,
>   `BusinessRuleException`), el `ErrorResponse` y el resto de la tabla de mapeo, que es mecánica.

**Archivos**

```
com.fintrack.common/
├── error/GlobalExceptionHandler.java   # @RestControllerAdvice
├── error/ApiException.java             # base con status + title
├── error/NotFoundException.java        # 404
├── error/ConflictException.java        # 409
├── error/BusinessRuleException.java    # 422 (violación de RB-xx)
└── error/ErrorResponse.java            # o ProblemDetail de Spring 6
```

**Formato obligatorio (§4.7)**

```json
{
  "type": "about:blank",
  "title": "Validation failed",
  "status": 400,
  "detail": "amount must be greater than 0",
  "instance": "/api/v1/transactions",
  "errors": [{ "field": "amount", "message": "must be greater than 0" }]
}
```

**Mapeo de excepciones**

| Excepción | Status | title |
|---|---|---|
| `MethodArgumentNotValidException`, `ConstraintViolationException` | 400 | Validation failed |
| `HttpMessageNotReadableException` (JSON malformado) | 400 | Malformed request |
| `MethodArgumentTypeMismatchException` | 400 | Invalid parameter |
| `AuthenticationException` / JWT inválido | 401 | Unauthorized |
| `AccessDeniedException` | 403 | Forbidden |
| `NotFoundException` | 404 | Resource not found |
| `ConflictException`, `DataIntegrityViolationException` | 409 | Conflict |
| `BusinessRuleException` | 422 | Business rule violation |
| Cualquier otra | 500 | Internal error |

**Reglas**

- `errors[]` solo aparece cuando hay errores de campo.
- El 500 **nunca** filtra stacktrace, SQL ni nombres de tabla al cliente; se registra en el log con un
  `traceId` que sí se incluye en `detail` (`"Referencia: 7f3a..."`) para poder correlacionar.
- Los 401/403 que produce el filtro de seguridad también salen en este formato: registra
  `AuthenticationEntryPoint` y `AccessDeniedHandler` que serialicen el mismo cuerpo.
- Content-Type de los errores: `application/problem+json`.

**Aceptación**
- [ ] Registro con email inválido y password corto → 400 con **dos** entradas en `errors[]`.
- [ ] `GET /accounts/{uuid-inexistente}` (cuando exista, F2.1) → 404 con este formato.
- [ ] Body con JSON roto → 400, no 500.
- [ ] Petición sin token → 401 en `application/problem+json`.
- [ ] Excepción no controlada → 500 sin stacktrace en la respuesta y con traza completa en el log.

---

## Prompt sugerido por tarea

Antes de lanzarlo, cambia al modelo que indica la anotación de esa tarea. En las tareas 🟡 Mixto,
lanza **primero** la parte de Sonnet y solo después la de Haiku sobre el código ya existente.

> Lee `plans/02-AUTH-BACKEND.md` y `plans/00-INDICE-Y-CONVENCIONES.md`. Implementa **solo F1.X**.
> Respeta el contrato de §4.1 del plan maestro tal cual (rutas, códigos, forma del body). No inventes
> endpoints ni campos extra. Al terminar, ejecuta los criterios de aceptación con peticiones reales
> (curl o Swagger) y pégame las respuestas.

## Cierre de fase

- [ ] Flujo completo probado en Swagger: register → login → endpoint protegido → refresh → logout.
- [ ] Ningún endpoint acepta `userId` del cliente.
- [ ] Todos los errores salen en Problem Details.
- [ ] Commit/tag `fase-1-auth-backend`.

**Siguiente:** [`03-AUTH-FLUTTER.md`](03-AUTH-FLUTTER.md).
