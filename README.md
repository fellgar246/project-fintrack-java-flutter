# FinTrack

Aplicación local de finanzas personales: registro de ingresos/gastos, presupuestos mensuales y
reportes. Proyecto de aprendizaje full-stack y pieza de portafolio.

> Spec completo: [`PLAN_MAESTRO_FINTRACK.md`](PLAN_MAESTRO_FINTRACK.md).
> Plan de implementación por fases: [`plans/`](plans/).

## Stack

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

## Estructura del repo

```
fintrack-java-flutter/
├── backend/   # API Spring Boot (Gradle, Java 21)
├── app/       # Cliente Flutter
├── docker/    # docker-compose.yml y .env.example
└── plans/     # Sub-planes de implementación por fase
```

## Cómo levantar (desarrollo)

> Instrucciones completas de arranque con un solo comando llegan en la Fase 7 (F7.2).

1. **Base de datos:**
   ```bash
   cp docker/.env.example docker/.env
   # genera un secreto real para JWT_SECRET:
   openssl rand -base64 48
   # edita docker/.env y pega el secreto generado
   docker compose -f docker/docker-compose.yml up -d db
   ```
2. **Backend:** abre `/backend` en tu IDE y corre `FintrackApiApplication` (usa las mismas
   variables de `docker/.env`), o `./gradlew bootRun` desde `/backend`.
   Health check: `GET http://localhost:8080/api/v1/actuator/health` → `{"status":"UP"}`.

   > **Nota de puerto:** el contenedor de Postgres publica en `localhost:5435` (no `5432`) porque
   > en esta máquina el 5432 ya lo usa un Postgres nativo instalado fuera de Docker (y 5433/5434
   > los usan otros proyectos en Docker). Si tu máquina no tiene ese conflicto, puedes volver a
   > mapear `5432:5432` en `docker/docker-compose.yml` y ajustar `DB_URL` en `application.yml`.
3. **App Flutter:** desde `/app`, `flutter run`.

## Estado actual

Fase 0 (Cimientos): monorepo, Postgres en Docker, backend arranca con Flyway, app Flutter con
placeholders. Aún sin auth ni endpoints de negocio.
