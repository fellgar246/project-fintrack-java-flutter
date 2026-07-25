# 09 — Calidad: tests y linters (Fase 6)

> Cubre **F6.1 – F6.3** del [plan maestro](../PLAN_MAESTRO_FINTRACK.md) (§7).
> Convenciones: [`00-INDICE-Y-CONVENCIONES.md`](00-INDICE-Y-CONVENCIONES.md).

## Objetivo

Cobertura de servicios ≥ 80%, tests de integración con Postgres real (Testcontainers) y widget tests
de los formularios críticos. Además, linters que fallen el build.

## Cuándo hacerlo

**Recomendación fuerte: no dejes este archivo para el final.** Ejecuta la porción que corresponde al
cerrar cada fase:

| Al terminar | Corre de aquí |
|---|---|
| Fase 1 (auth) | F6.1 — tests de integración de auth |
| Fase 2–3 | F6.1 — tests de integración de transactions; F6.3 — widget test del formulario |
| Fase 4–5 | F6.2 — tests unitarios de budgets y reports |
| Cierre | Linters + cobertura |

Si prefieres hacerlo todo de una vez al final, este archivo funciona igual — pero habrás perdido la
señal temprana.

## Reparto de modelos

Criterio completo en [§5 del índice](00-INDICE-Y-CONVENCIONES.md#5-reparto-de-modelos-haiku-vs-sonnet).

| Tarea | Modelo |
|---|---|
| F6.1 Testcontainers | 🟡 Mixto |
| F6.2 Tests unitarios | 🟢 Haiku |
| F6.3 Widget tests | 🟢 Haiku |
| Linters | 🟢 Haiku |

**Esta es la fase donde más se ahorra con Haiku.** Los casos de prueba están enumerados uno por uno
en este documento, así que escribirlos es traducción, no diseño. Lo único que necesita criterio es el
*andamiaje* — la clase base de Testcontainers y los `mock_providers` —, y se hace una sola vez.

> Advertencia: **un test que pasa no prueba que el test sea bueno.** Revisa que los tests de Haiku
> realmente fallen si rompes a propósito la regla que dicen verificar. Es la comprobación del último
> criterio de aceptación de F6.1 y conviene aplicarla a algunos tests de F6.2 también.

---

## F6.1 — Tests de integración con Testcontainers

> **Modelo: 🟡 Mixto.**
> - 🔵 **Sonnet:** `IntegrationTest.java` y `TestDataFactory`. El contenedor singleton con
>   `@DynamicPropertySource` y la estrategia de aislamiento entre tests son la diferencia entre una
>   suite de 90 segundos y una de 15 minutos, y entre tests deterministas y tests que fallan según el
>   orden en que corren.
> - 🟢 **Haiku:** los casos de `AuthControllerIT` y `TransactionControllerIT`, una vez que la clase
>   base existe. Están listados abajo con su status esperado.

**Archivos**

```
backend/src/test/java/com/fintrack/
├── support/
│   ├── IntegrationTest.java        # @SpringBootTest + @Testcontainers, clase base
│   ├── TestDataFactory.java        # builders: aUser(), anAccount(), aTransaction()
│   └── AuthTestHelper.java         # registra usuario y devuelve headers con Bearer
├── auth/AuthControllerIT.java
└── transaction/TransactionControllerIT.java
```

**Setup**

- Contenedor **singleton** de `postgres:16` reutilizado por toda la suite (static `@Container` en la
  clase base + `@DynamicPropertySource`). Levantar un contenedor por clase hace la suite inusablemente lenta.
- Flyway corre sobre el contenedor: los tests validan **las migraciones reales**, no un esquema
  generado por Hibernate. Este es el punto de usar Testcontainers.
- Aislamiento entre tests: `@Transactional` con rollback, o truncar tablas en `@BeforeEach`. Elige uno
  y sé consistente.
- `MockMvc` o `TestRestTemplate` para pegarle a los endpoints de verdad.

**`AuthControllerIT` — casos**
- Registro exitoso → 201, tokens presentes, 12 categorías default creadas en BD.
- Email duplicado (incluida distinta capitalización) → 409 con Problem Details.
- Password < 8 → 400 con `errors[]`.
- Login correcto → 200; password incorrecta → 401 genérico.
- Endpoint protegido sin token → 401; con token válido → 200.
- Refresh rota el token: el viejo deja de servir → 401.
- Logout revoca; segundo logout → 204 (idempotente).
- **Aislamiento (RB-05):** el usuario A no puede leer recursos del usuario B → 404.

**`TransactionControllerIT` — casos**
- POST de EXPENSE válido → 201 y el saldo de la cuenta refleja el cambio.
- Las validaciones de F3.1: monto ≤ 0, 3 decimales, TRANSFER con categoría, TRANSFER a la misma
  cuenta, EXPENSE con categoría INCOME, cuenta archivada → cada una con su status esperado.
- GET paginado: filtros `from/to`, `accountId` (incluye destino de transferencia), `type`, `search`,
  y combinaciones.
- Paginación estable: recorrer 3 páginas de datos sembrados no repite ni pierde filas.
- DELETE → 204 y el saldo se recalcula.
- Transacción de otro usuario → 404 en GET, PUT y DELETE.

**Aceptación**
- [ ] `./gradlew test` levanta el contenedor, aplica Flyway y pasa en verde desde cero.
- [ ] La suite completa corre en < 2 minutos.
- [ ] Un test que corre dos veces seguidas da el mismo resultado (sin estado filtrado).
- [ ] Romper a propósito una validación de F3.1 hace fallar un test concreto y nombrado.

---

## F6.2 — Tests unitarios de servicios

> **Modelo: 🟢 Haiku.** Volumen alto, criterio bajo: repositorios mockeados con Mockito y una lista
> de casos ya cerrada abajo, un test por regla. Es el mejor candidato de todo el proyecto para el
> modelo barato.
> Dos cosas a vigilar: que **no** se cuele un `@SpringBootTest` (si la suite tarda más de 10 s, pasó
> justo eso) y que los valores esperados de redondeo sean los del sub-plan, no los que el modelo
> calcule por su cuenta.

**Archivos**

```
backend/src/test/java/com/fintrack/
├── account/AccountServiceTest.java
├── budget/BudgetServiceTest.java
├── report/ReportServiceTest.java
└── transaction/TransactionServiceTest.java
```

Unitarios puros: repositorios **mockeados** con Mockito, sin Spring context, sin BD. Rápidos.

**Qué probar — una regla de negocio por test**

`AccountServiceTest` (RB-01, RB-02)
- Saldo = inicial + ingresos − gastos − transferencias salientes + transferencias entrantes.
- Cuenta sin movimientos → saldo = inicial.
- Saldo negativo permitido.
- DELETE con transacciones → archiva; sin transacciones → borra.

`BudgetServiceTest` (RB-04)
- Categoría INCOME → lanza `BusinessRuleException`.
- `percentUsed` con 3250.75 / 5000 → 65.02 (verifica el redondeo HALF_UP).
- Límite cubierto exacto → 100.00 y `EXCEEDED`.
- Gasto > límite → `remainingAmount` negativo.
- Límite 0 o negativo → excepción de validación.
- Upsert: existente → actualiza; nuevo → crea.

`ReportServiceTest` (RB-03)
- Transferencias excluidas de ingresos y gastos.
- Porcentajes por categoría suman 100 (±0.01).
- Total 0 → sin división entre cero, lista vacía.
- `trend` rellena los meses sin datos con ceros.
- `net` = ingresos − gastos.

`TransactionServiceTest`
- La matriz completa de validaciones de F3.1, cada rama con su test.
- Cambio de tipo en PUT revalida todo.

**Cobertura**
- JaCoCo configurado. Objetivo **≥ 80% en la capa de servicios** (§7).
- Regla en el build: `jacocoTestCoverageVerification` sobre `com.fintrack.*.*Service` falla si baja del 80%.
- No persigas cobertura en DTOs, entidades ni mappers: excluidos del cálculo.

**Aceptación**
- [ ] `./gradlew test jacocoTestReport` genera el reporte HTML.
- [ ] Servicios ≥ 80% de líneas.
- [ ] Los tests unitarios corren en < 10 segundos (si tardan más, se te coló un contexto de Spring).
- [ ] Cada RB-01..RB-05 tiene al menos un test que la nombra explícitamente.

---

## F6.3 — Widget tests en Flutter

> **Modelo: 🟢 Haiku.** Los tres archivos de test tienen sus casos enumerados y esperados explícitos.
> **Excepción 🔵 Sonnet:** `helpers/mock_providers.dart` y `test_app.dart` la primera vez. Sobrescribir
> providers de Riverpod en un `ProviderScope` de test tiene suficiente ceremonia como para que
> convenga hacerlo bien una vez; después, los tests que lo usan son mecánicos.
> El golden test opcional del dashboard, si lo haces, también es Sonnet.

**Archivos**

```
app/test/
├── helpers/{test_app.dart, mock_providers.dart}
├── shared/money_formatter_test.dart
├── features/transactions/transaction_form_test.dart
└── features/budgets/budget_progress_bar_test.dart
```

**`money_formatter_test.dart`** (test puro, sin widgets)
- `1234.5` → `$1,234.50`
- `0` → `$0.00`
- `-500` → `-$500.00`
- `1000000` → `$1,000,000.00`
- `0.1 + 0.2` con `Decimal` → `$0.30` exacto (la razón de usar `decimal` y no `double`).

**`transaction_form_test.dart`**
- Se renderiza con providers mockeados (cuentas y categorías falsas), sin red real.
- Monto vacío o `0` → el botón guardar queda deshabilitado.
- No se pueden teclear 3 decimales ni dos puntos.
- Seleccionar "Transferencia" oculta el selector de categoría y muestra el de cuenta destino.
- Origen = destino → muestra el mensaje de error.
- Guardar con datos válidos llama al método esperado del repositorio mock **una sola vez**.

**`budget_progress_bar_test.dart`**
- 50% → verde; 85% → ámbar; 100% y 120% → rojo.
- El porcentaje aparece como texto (accesibilidad, no solo color).

**Extra opcional (§7):** golden test del dashboard con datos fijos. Útil, pero frágil entre versiones
de Flutter — si lo agregas, documenta cómo regenerar los goldens.

**Aceptación**
- [ ] `flutter test` pasa en verde.
- [ ] Ningún test hace peticiones HTTP reales.
- [ ] Los tests corren en < 30 segundos.

---

## Linters (§7)

> **Modelo: 🟢 Haiku.** Configuración declarativa: bloques de Gradle, un `checkstyle.xml`, reglas en
> `analysis_options.yaml` y un script que encadena comandos. La aceptación es binaria —el build pasa
> o no—, así que no hay margen de interpretación.

**Backend**
- **Spotless** con `googleJavaFormat` o `palantir-java-format`; `./gradlew spotlessApply` formatea,
  `spotlessCheck` va en el build.
- **Checkstyle** con un ruleset acotado (imports sin usar, naming, longitud de línea 120).
- Ambos ligados a `check` para que el build falle si no cumplen.

**Frontend**
- `flutter_lints` en `analysis_options.yaml` + reglas extra: `prefer_const_constructors`,
  `avoid_print`, `always_declare_return_types`.
- `flutter analyze` debe salir sin issues.

**Opcional pero recomendable:** un `Makefile` o script `./scripts/check.sh` que corra todo
(`spotlessCheck`, `test`, `flutter analyze`, `flutter test`) con un solo comando. Es también lo que
pondrías en CI si algún día lo agregas.

**Aceptación**
- [ ] `./gradlew check` corre Spotless, Checkstyle y tests.
- [ ] `flutter analyze && flutter test` limpio.
- [ ] Un script único ejecuta todas las validaciones.

---

## Prompt sugerido

Monta el andamiaje (F6.1 base, `mock_providers`) con Sonnet y escribe todos los casos con Haiku.

> Lee `plans/09-CALIDAD.md` y `plans/00-INDICE-Y-CONVENCIONES.md`. Implementa **solo F6.X**.
> Usa un contenedor Testcontainers singleton para toda la suite y deja que Flyway aplique las
> migraciones reales. Los tests unitarios van con repositorios mockeados, sin contexto de Spring.
> Cada test debe nombrar la regla de negocio que verifica. Al final, muéstrame el reporte de cobertura
> y la salida real de la suite completa.

## Cierre de fase

- [ ] Los tres checklists completos + linters.
- [ ] Cobertura de servicios ≥ 80% verificada, no estimada.
- [ ] Commit/tag `fase-6-calidad`.

**Siguiente:** [`10-PORTAFOLIO.md`](10-PORTAFOLIO.md).
