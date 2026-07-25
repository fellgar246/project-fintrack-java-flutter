# 10 — Portafolio: empaquetado y documentación (Fase 7)

> Cubre **F7.1 – F7.3** del [plan maestro](../PLAN_MAESTRO_FINTRACK.md) (§6.1, §8).
> Convenciones: [`00-INDICE-Y-CONVENCIONES.md`](00-INDICE-Y-CONVENCIONES.md).

## Objetivo

Que cualquiera —un reclutador, un colega, tú mismo en seis meses— clone el repo y tenga el sistema
completo corriendo con **un comando**, y entienda qué hace sin ejecutarlo.

Esta fase no agrega funcionalidad. Agrega la diferencia entre "un proyecto" y "un proyecto de portafolio".

## Prerrequisitos

- Fases 0–5 completas y funcionando. [`09-CALIDAD.md`](09-CALIDAD.md) idealmente también.

## Reparto de modelos

Criterio completo en [§5 del índice](00-INDICE-Y-CONVENCIONES.md#5-reparto-de-modelos-haiku-vs-sonnet).

| Tarea | Modelo |
|---|---|
| F7.1 Dockerfile + compose | 🟢 Haiku |
| F7.2 README | 🟡 Mixto |
| F7.3 Colección `.http` | 🟢 Haiku |

Fase casi entera de Haiku: es empaquetado y documentación sobre un sistema que ya funciona, con el
Dockerfile literalmente escrito abajo. La única parte que no se puede delegar es la sección de
decisiones de diseño del README —**y no por dificultad técnica, sino porque es donde el proyecto
argumenta por qué está hecho así**, que es exactamente lo que un lector de portafolio evalúa.

---

## F7.1 — Dockerfile multistage + compose completo

> **Modelo: 🟢 Haiku.** El Dockerfile viene dado abajo y el compose es una extensión del de F0.2.
> La verificación es objetiva: la imagen construye, arranca, responde `UP` y pesa lo que debe.
> **Escala a 🔵 Sonnet** si el build falla por algo no obvio (rutas de Gradle, capas que no cachean,
> permisos del usuario no-root). Depurar un build de Docker que falla en la etapa 2 es otro tipo de
> tarea que copiar un Dockerfile.

**Archivos**

```
backend/Dockerfile
backend/.dockerignore
docker/docker-compose.yml     # actualizado: servicio api ya activo
```

**Dockerfile multistage**

```dockerfile
# --- build ---
FROM gradle:8-jdk21 AS build
WORKDIR /home/app
COPY build.gradle.kts settings.gradle.kts gradle.properties ./
COPY gradle ./gradle
RUN gradle dependencies --no-daemon      # capa cacheable de dependencias
COPY src ./src
RUN gradle bootJar --no-daemon -x test

# --- runtime ---
FROM eclipse-temurin:21-jre-alpine
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=build /home/app/build/libs/*.jar app.jar
USER app
EXPOSE 8080
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "-jar", "app.jar"]
```

Puntos que importan:
- **Dos etapas**: la imagen final lleva JRE, no JDK ni Gradle. Objetivo < 250 MB.
- Dependencias en una capa aparte del código: cambiar una clase no reinstala todo.
- **Usuario no-root**.
- `-XX:MaxRAMPercentage` para que la JVM respete el límite del contenedor.
- `.dockerignore` con `build/`, `.gradle/`, `.git/`, `*.md` — sin esto el contexto de build se infla.

**docker-compose final (§6.1)**

- `db`: como en F0.2, con healthcheck.
- `api`: `build: ../backend`, `ports: 8080:8080`, `depends_on: db (condition: service_healthy)`,
  variables desde `.env`, `restart: unless-stopped`, healthcheck propio contra `/actuator/health`.
- `DB_URL` apunta a `jdbc:postgresql://db:5432/...` (nombre del servicio, no `localhost`).
- **Perfiles:**
  - default (solo `db`) → desarrollo con Spring desde el IDE.
  - `--profile full` (`db` + `api`) → demo de un comando.
- Documenta ambos modos en el README.

**Aceptación**
- [ ] `docker compose --profile full up --build` levanta todo desde cero en una máquina limpia.
- [ ] `curl localhost:8080/api/v1/actuator/health` → `UP` sin tocar nada más.
- [ ] La imagen final pesa menos de ~250 MB (`docker images`).
- [ ] Cambiar una línea de código y reconstruir **no** vuelve a descargar dependencias.
- [ ] `docker compose down && up` conserva los datos (volumen nombrado).
- [ ] El contenedor corre como usuario no-root (`docker exec ... whoami`).
- [ ] Ningún secreto está en la imagen: todo llega por variables de entorno.

---

## F7.2 — README con demo visual

> **Modelo: 🟡 Mixto.**
> - 🟢 **Haiku:** secciones 1–10 y 12–13 (badges, tablas, comandos, estructura, enlaces). Es formato.
> - 🔵 **Sonnet:** la sección **11, "Decisiones de diseño"**. Explicar por qué los saldos se calculan
>   y no se persisten, qué se sacrifica a cambio, o por qué Testcontainers en vez de H2, exige haber
>   entendido las consecuencias de cada elección. Un modelo rápido produce ahí viñetas genéricas
>   ("usamos BigDecimal por precisión") que no dicen nada; el valor está en el *trade-off*.
>
> Las capturas y el GIF los haces tú: ningún modelo puede grabarlos.

**Archivo:** `README.md` en la raíz (+ `docs/images/`).

**Estructura recomendada**

1. **Título + una línea** — "FinTrack — gestor de finanzas personales full-stack (Spring Boot + Flutter,
   100% local)".
2. **Badges** — Java 21, Spring Boot 3.3, Flutter 3.x, PostgreSQL 16, licencia.
3. **Demo** — un GIF de 15–30 s arriba del todo: registrar un gasto → verlo en la lista → verlo en el
   dashboard → verlo en presupuestos. Es lo único que mucha gente va a mirar.
4. **Screenshots** — 4–6 imágenes en una tabla de 2–3 columnas: dashboard, transacciones, alta de
   transacción, presupuestos, reportes. En modo claro y oscuro si puedes.
5. **Características** — lista corta con lo que realmente hace, no lo que planeas hacer.
6. **Stack** — la tabla de §1.2 del maestro.
7. **Arquitectura** — el diagrama de §2.1 + el árbol de módulos backend y features Flutter.
8. **Cómo ejecutar** — dos rutas claras:
   ```bash
   # Opción A — todo en Docker (demo)
   cp docker/.env.example docker/.env      # genera JWT_SECRET: openssl rand -base64 48
   docker compose -f docker/docker-compose.yml --profile full up --build

   # Opción B — desarrollo
   docker compose -f docker/docker-compose.yml up -d db
   cd backend && ./gradlew bootRun
   cd app && flutter run
   ```
   Incluye la nota de `10.0.2.2` para el emulador Android.
9. **API** — enlace a Swagger UI (`http://localhost:8080/api/v1/swagger-ui.html`) + captura.
10. **Modelo de datos** — el ERD de §3.1 (mejor si lo dibujas como Mermaid, que GitHub renderiza).
11. **Decisiones de diseño** — la sección que más distingue el proyecto. 4–6 viñetas con el *porqué*:
    - `BigDecimal`/`Decimal` y nunca `double` para dinero;
    - saldos calculados y no persistidos (RB-01) y qué se sacrifica a cambio;
    - la transferencia como fila única (RB-03);
    - refresh tokens rotativos con hash en BD;
    - Flyway con `ddl-auto: validate`;
    - Testcontainers contra Postgres real en vez de H2.
12. **Tests** — cómo correrlos y qué cubren.
13. **Roadmap / fuera de alcance** — §1.4, para dejar claro que las ausencias son decisiones.

**Cómo capturar**
- GIF: graba con QuickTime/`ffmpeg` y convierte (`ffmpeg -i in.mov -vf "fps=12,scale=400:-1" out.gif`).
  Mantenlo por debajo de ~5 MB o GitHub lo cargará lento.
- Siembra datos realistas antes de grabar: nombres de comercios creíbles, montos variados, 6 meses de
  historia. Un dashboard con tres transacciones de prueba no vende nada.

**Aceptación**
- [ ] Alguien que nunca vio el proyecto lo levanta siguiendo solo el README.
- [ ] El GIF se reproduce en GitHub y muestra un flujo completo.
- [ ] Todas las imágenes cargan (rutas relativas, no locales).
- [ ] Los comandos del README están copiados/pegados de una ejecución real que funcionó.
- [ ] No hay secciones "TODO" ni features prometidas que no existan.

---

## F7.3 — Colección de ejemplos de API

> **Modelo: 🟢 Haiku.** Repetición pura sobre el contrato de §4, ya implementado y probado. Pásale la
> especificación como referencia y pídele cobertura completa de endpoints; la verificación es
> ejecutar el archivo de arriba abajo.

**Archivo:** `docs/api/fintrack.http` (formato REST Client de VS Code / IntelliJ HTTP Client).

```http
@host = http://localhost:8080/api/v1
@email = demo@fintrack.local
@password = demo12345

### Registro
POST {{host}}/auth/register
Content-Type: application/json

{ "email": "{{email}}", "password": "{{password}}", "name": "Demo" }

### Login (captura el token)
# @name login
POST {{host}}/auth/login
Content-Type: application/json

{ "email": "{{email}}", "password": "{{password}}" }

@token = {{login.response.body.tokens.accessToken}}

### Crear cuenta
POST {{host}}/accounts
Authorization: Bearer {{token}}
Content-Type: application/json

{ "name": "Efectivo", "type": "CASH", "initialBalance": "5000.00" }
```

**Cubre todos los módulos**, en orden de uso real: auth → accounts → categories → transactions
(incluida una transferencia) → budgets → reports (los cuatro) → export CSV. Añade también los casos
de error interesantes (monto negativo, transferencia con categoría, email duplicado) — documentan el
contrato mejor que la ruta feliz.

**Complementos**
- Exporta el OpenAPI a `docs/api/openapi.json` (`curl localhost:8080/api/v1/v3/api-docs`) para que se
  pueda importar en Postman o Insomnia sin levantar nada.
- Opcional: `docs/api/README.md` con cómo usar el archivo `.http` en cada IDE.

**Aceptación**
- [ ] Ejecutar el archivo de arriba abajo en un entorno limpio deja datos coherentes y ningún error inesperado.
- [ ] El token se propaga automáticamente entre peticiones.
- [ ] Cada endpoint de §4 del maestro tiene al menos un ejemplo.
- [ ] `openapi.json` se importa en Postman sin errores.

---

## Prompt sugerido

Casi todo con Haiku; reserva Sonnet para "Decisiones de diseño" del README y para depurar el build
de Docker si falla.

> Lee `plans/10-PORTAFOLIO.md` y `plans/00-INDICE-Y-CONVENCIONES.md`. Implementa **solo F7.X**.
> El Dockerfile debe ser multistage con usuario no-root y el compose debe levantar todo el sistema con
> un comando. El README debe poder seguirse literalmente en una máquina limpia. Verifica cada criterio
> ejecutándolo de verdad y muéstrame las salidas.

## Cierre del proyecto

- [ ] `git clone` + un comando = sistema corriendo.
- [ ] README con GIF, screenshots y decisiones de diseño.
- [ ] Colección `.http` completa + `openapi.json`.
- [ ] `PLAN_MAESTRO_FINTRACK.md` §10 actualizado con todos los cambios de spec que hubo en el camino.
- [ ] Commit/tag `v1.0.0`.

### Antes de publicarlo

- [ ] No hay secretos reales en el historial de git (revisa `.env`, tokens, contraseñas).
- [ ] El usuario demo tiene credenciales obviamente de prueba.
- [ ] `flutter analyze`, `./gradlew check` y toda la suite de tests en verde en el commit final.

---

**Fin del plan.** Vuelve a [`00-INDICE-Y-CONVENCIONES.md`](00-INDICE-Y-CONVENCIONES.md) para el mapa completo.
