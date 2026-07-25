# 03 — Autenticación: Flutter (Fase 1, parte frontend)

> Cubre **F1.4** del [plan maestro](../PLAN_MAESTRO_FINTRACK.md) (§5.2.1, §4.1).
> Convenciones: [`00-INDICE-Y-CONVENCIONES.md`](00-INDICE-Y-CONVENCIONES.md).

## Objetivo

La app tiene login y registro funcionales contra el backend real; los tokens se guardan en
`flutter_secure_storage`; el cliente HTTP inyecta el access token en cada petición y **refresca solo**
cuando recibe un 401; el router redirige según el estado de sesión.

Esta es la pieza que hace que todas las features siguientes solo tengan que preocuparse por su
propio endpoint.

## Prerrequisitos

- [`02-AUTH-BACKEND.md`](02-AUTH-BACKEND.md) completo y corriendo en `localhost:8080`.
- Scaffold Flutter de [`01-CIMIENTOS.md`](01-CIMIENTOS.md) (F0.5).

## Reparto de modelos

Criterio completo en [§5 del índice](00-INDICE-Y-CONVENCIONES.md#5-reparto-de-modelos-haiku-vs-sonnet).
**Orden obligatorio: a → b → c.** F1.4.a establece el patrón de capa de red que copiarán las siete
features siguientes; si sale mal, se arrastra a todo el frontend.

| Tarea | Modelo |
|---|---|
| F1.4.a Red y storage de tokens | 🔵 Sonnet |
| F1.4.b Data + providers de auth | 🟡 Mixto |
| F1.4.c Pantallas login/registro | 🟢 Haiku |

---

## F1.4.a — Capa de red y almacenamiento de tokens

> **Modelo: 🔵 Sonnet.** El interceptor tiene el problema de concurrencia más difícil del frontend:
> N peticiones que reciben 401 a la vez deben compartir **un solo** `Future` de refresh. Escrito de
> la forma ingenua, el código funciona en desarrollo con una petición y falla en cuanto el dashboard
> lanza tres en paralelo (F5.2) — con síntomas de "a veces me cierra la sesión" imposibles de
> reproducir. Además fija el patrón que copian todas las features.

**Archivos**

```
app/lib/core/
├── network/
│   ├── dio_client.dart          # instancia Dio + baseUrl + timeouts
│   ├── auth_interceptor.dart    # inyecta Bearer, refresca en 401
│   └── api_exception.dart       # parsea Problem Details → excepción tipada
└── storage/
    └── token_storage.dart       # wrapper de flutter_secure_storage
```

**`token_storage.dart`**
- Claves: `access_token`, `refresh_token`.
- Métodos: `saveTokens`, `readAccess`, `readRefresh`, `clear`.
- En web `flutter_secure_storage` usa otro backend; si vas a soportar web, documenta la limitación.

**`api_exception.dart`**
- Convierte el cuerpo Problem Details (§4.7) en `ApiException {status, title, detail, fieldErrors}`.
- `fieldErrors: Map<String, String>` para pintar errores directamente bajo cada `TextFormField`.
- Si el body no es Problem Details (p. ej. el servidor está caído), produce un mensaje genérico
  "No se pudo conectar con el servidor".

**`auth_interceptor.dart`** — el punto delicado:
- `onRequest`: si hay access token y la ruta **no** es `/auth/login`, `/auth/register` ni `/auth/refresh`,
  añade `Authorization: Bearer <token>`.
- `onError` con status 401 y la petición no era de `/auth/*`:
  1. Llama a `POST /auth/refresh` con el refresh guardado.
  2. Si funciona: guarda los tokens nuevos y **reintenta la petición original una sola vez**.
  3. Si falla: limpia el storage y emite un evento de "sesión expirada" que el router escucha.
- **Un solo refresh concurrente:** si llegan varios 401 a la vez, todos esperan al mismo `Future`
  (un `Completer`/`Future` compartido). Sin esto, N peticiones paralelas disparan N rotaciones y el
  backend invalida los tokens entre sí.
- Nunca reintentar más de una vez la misma petición (marca la request con un flag).

**Aceptación**
- [ ] Con token válido, una petición protegida funciona sin código extra en la feature.
- [ ] Forzando un access token expirado (baja `JWT_ACCESS_TTL_MIN=1` y espera), la app se recupera
      sola y el usuario no ve nada raro.
- [ ] Con refresh también inválido, la app cierra sesión y va a `/login`.
- [ ] 3 peticiones simultáneas con token expirado disparan **un solo** `/auth/refresh`.

---

## F1.4.b — Feature auth: data + providers

> **Modelo: 🟡 Mixto.**
> - 🟢 **Haiku:** los modelos `freezed`/`json_serializable` y `auth_api.dart` (cuatro llamadas Dio
>   contra un contrato ya cerrado en §4.1).
> - 🔵 **Sonnet:** `AuthState` y `AuthController`. El estado `unknown` inicial y el bootstrap desde
>   el storage son los que evitan el parpadeo login→dashboard, y este `AsyncNotifier` es la plantilla
>   de todos los providers posteriores.

**Archivos**

```
app/lib/features/auth/
├── data/
│   ├── models/{user_model.dart, tokens_model.dart, auth_response.dart}
│   └── auth_api.dart          # register, login, refresh, logout
└── providers/
    ├── auth_repository.dart   # orquesta auth_api + token_storage
    └── auth_controller.dart   # AsyncNotifier<AuthState>
```

- Modelos con `freezed` + `json_serializable`. `UserModel {id, email, name, baseCurrency}`.
- `AuthState`: `unknown | unauthenticated | authenticated(User)`.
  Arranca en `unknown`, y en el bootstrap de la app lee el storage para decidir.
- `AuthController` expone `login()`, `register()`, `logout()`. Errores se propagan como
  `ApiException` para que la UI los mapee a campos.
- `logout()` llama al endpoint (best-effort) y **siempre** limpia el storage local, aunque la
  petición falle.

**Aceptación**
- [ ] `flutter analyze` limpio y código generado por `build_runner` al día.
- [ ] Reiniciar la app con tokens válidos guardados entra directo al dashboard sin pedir login.

---

## F1.4.c — Pantallas de login y registro

> **Modelo: 🟢 Haiku.** Dos formularios con validación de cliente y mapeo de `fieldErrors` a campos:
> patrón estándar, todo enumerado abajo.
> **Excepción 🔵 Sonnet:** el `redirect` de `go_router`. Los guards de navegación con estado
> asíncrono son una fuente clásica de bucles de redirección (`unknown` → `/login` → `authenticated`
> → `/dashboard` → …). Si el `redirect` no trata `unknown` como caso propio, la app parpadea o se
> cuelga en el arranque.

**Archivos**

```
app/lib/features/auth/presentation/
├── login_screen.dart
├── register_screen.dart
└── widgets/auth_text_field.dart
```

**Login (`/login`)**
- Campos: email, password (con toggle de visibilidad).
- Validación cliente: email con formato, password ≥ 8. Botón deshabilitado mientras el form es inválido.
- Botón con spinner y deshabilitado durante el envío (evita doble submit).
- Error 401 del backend → snackbar "Credenciales inválidas"; errores de campo (`fieldErrors`) →
  se pintan bajo el campo correspondiente.
- Link "¿No tienes cuenta? Regístrate" → `/register`.

**Registro (`/register`)**
- Campos: nombre, email, password, confirmar password (validación de coincidencia en cliente).
- 409 del backend → error bajo el campo email: "Ese correo ya está registrado".
- Al éxito: guarda tokens y navega al dashboard (el registro ya devuelve tokens, §4.1).

**Router (`core/router/app_router.dart`)**
- `redirect` basado en `AuthState`:
  - `unknown` → pantalla de splash/loader (evita el parpadeo login→dashboard).
  - `unauthenticated` y ruta protegida → `/login`.
  - `authenticated` y ruta `/login`/`/register` → `/dashboard`.
- El router escucha el provider de auth con `refreshListenable` para reaccionar al logout.

**Aceptación**
- [ ] Registro end-to-end crea el usuario y entra al dashboard.
- [ ] Login con credenciales buenas entra; con malas muestra el error sin cerrar la pantalla.
- [ ] Cerrar sesión desde ajustes (placeholder por ahora) vuelve a `/login` y borra el storage.
- [ ] Escribir `/dashboard` a mano sin sesión redirige a `/login`.
- [ ] Con el backend apagado, el login muestra "No se pudo conectar con el servidor", no un crash.

---

## Prompt sugerido

Antes de lanzarlo, cambia al modelo que indica la anotación de esa tarea.

> Lee `plans/03-AUTH-FLUTTER.md` y `plans/00-INDICE-Y-CONVENCIONES.md`. Implementa **solo F1.4.X**.
> Usa Riverpod 2 (`AsyncNotifier`), `freezed` para modelos y `go_router` con `redirect`. No pongas
> lógica de red dentro de widgets. Al terminar corre `flutter analyze` y prueba los criterios de
> aceptación contra el backend levantado.

## Cierre de fase 1

- [ ] Register → dashboard → hot restart → sigue logueado → logout → login.
- [ ] Ninguna pantalla llama a Dio directamente; todo pasa por la capa `data/`.
- [ ] Commit/tag `fase-1-auth-completa`.

**Siguiente:** [`04-CUENTAS-Y-CATEGORIAS.md`](04-CUENTAS-Y-CATEGORIAS.md).
