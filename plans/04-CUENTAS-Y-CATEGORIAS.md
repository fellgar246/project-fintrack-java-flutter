# 04 — Cuentas y categorías (Fase 2)

> Cubre **F2.1 – F2.3** del [plan maestro](../PLAN_MAESTRO_FINTRACK.md) (§4.2, §4.3, §5.2.7, RB-01, RB-02).
> Convenciones: [`00-INDICE-Y-CONVENCIONES.md`](00-INDICE-Y-CONVENCIONES.md).

## Objetivo

El usuario administra sus cuentas (con saldo calculado) y sus categorías desde Ajustes. Son los
catálogos que necesita el módulo de transacciones, por eso van antes.

## Prerrequisitos

- [`02-AUTH-BACKEND.md`](02-AUTH-BACKEND.md) y [`03-AUTH-FLUTTER.md`](03-AUTH-FLUTTER.md) completos.

## Reparto de modelos

Criterio completo en [§5 del índice](00-INDICE-Y-CONVENCIONES.md#5-reparto-de-modelos-haiku-vs-sonnet).
**Esta fase es el mejor ejemplo del reparto:** F2.1 con Sonnet establece el patrón de módulo CRUD
(controller → service → repository → mapper → DTOs, con filtro por `userId` y archivado RB-02), y
F2.2 lo replica con Haiku prácticamente calcándolo. Ejecutarlas al revés desperdicia el ahorro.

| Tarea | Modelo |
|---|---|
| F2.1 CRUD accounts + saldo | 🔵 Sonnet |
| F2.2 CRUD categories | 🟢 Haiku |
| F2.3 Ajustes en Flutter | 🟢 Haiku |

---

## F2.1 — Backend: CRUD de accounts con saldo calculado

> **Modelo: 🔵 Sonnet.** No por el CRUD, sino por la query de RB-01: cuatro `CASE` sobre un `LEFT JOIN`
> con doble condición (`account_id` **o** `transfer_account_id`), resuelta en **una sola pasada** para
> toda la lista. La versión ingenua —iterar cuentas y consultar el saldo de cada una— pasa todos los
> criterios funcionales y solo se nota cuando hay volumen. Este método además se reutiliza en F5.1,
> así que conviene que nazca bien.

**Archivos**

```
com.fintrack.account/
├── Account.java              # @Entity, enum AccountType {CASH, DEBIT, CREDIT, SAVINGS}
├── AccountRepository.java
├── AccountService.java
├── AccountController.java
├── AccountMapper.java
└── dto/{AccountRequest, AccountResponse}.java
```

**Contrato (§4.2)**

| Método | Ruta | Notas |
|---|---|---|
| GET | `/accounts?includeArchived=false` | devuelve `currentBalance` calculado |
| POST | `/accounts` | `{name, type, initialBalance}` → 201 |
| GET | `/accounts/{id}` | 404 si no existe **o no es del usuario** |
| PUT | `/accounts/{id}` | edita `name`, `type`, `initialBalance` |
| DELETE | `/accounts/{id}` | archiva o borra según RB-02 |

`AccountResponse`: `{id, name, type, initialBalance, currentBalance, archived, createdAt}`.
Montos serializados como **string** (`"1234.50"`).

**RB-01 — saldo calculado, nunca persistido**

```sql
SELECT a.id,
       a.initial_balance
     + COALESCE(SUM(CASE WHEN t.type = 'INCOME'   AND t.account_id = a.id THEN  t.amount END), 0)
     - COALESCE(SUM(CASE WHEN t.type = 'EXPENSE'  AND t.account_id = a.id THEN  t.amount END), 0)
     - COALESCE(SUM(CASE WHEN t.type = 'TRANSFER' AND t.account_id = a.id THEN  t.amount END), 0)
     + COALESCE(SUM(CASE WHEN t.type = 'TRANSFER' AND t.transfer_account_id = a.id THEN t.amount END), 0)
       AS current_balance
FROM accounts a
LEFT JOIN transactions t
       ON (t.account_id = a.id OR t.transfer_account_id = a.id)
      AND t.user_id = a.user_id
WHERE a.user_id = :userId
GROUP BY a.id, a.initial_balance;
```

- Una sola query para toda la lista (proyección/`@Query` nativa). **Prohibido** iterar cuentas
  y consultar el saldo de cada una (N+1).
- En transferencias: la cuenta origen (`account_id`) resta, la destino (`transfer_account_id`) suma.

**RB-02 — DELETE**
- Si la cuenta tiene transacciones (como origen o destino) → `archived = true`, respuesta **204**.
- Si no tiene ninguna → borrado físico, respuesta **204**.
- Documenta el comportamiento en Swagger para que no sorprenda.

**Otras reglas**
- Nombre único por usuario (case-insensitive). Duplicado → 409.
- Toda operación filtra por el `userId` del token. Pedir la cuenta de otro usuario → **404**
  (no 403: no reveles que existe).
- Una cuenta archivada no puede editarse ni recibir transacciones nuevas; sí aparece en el historial.
- `initialBalance` puede ser negativo (útil para tarjetas de crédito).

**Aceptación**
- [ ] Cuenta nueva con `initialBalance = 1000` → `currentBalance = 1000`.
- [ ] Tras un gasto de 250 → `currentBalance = 750`; tras un ingreso de 100 → `850`.
- [ ] Transferencia de 200 de A a B: A baja 200, B sube 200; la suma total no cambia.
- [ ] DELETE de cuenta con movimientos → `archived = true` y desaparece de `GET /accounts` (sin `includeArchived=true`).
- [ ] DELETE de cuenta vacía → ya no existe en BD.
- [ ] Con el token del usuario 1, un id del usuario 2 → 404.
- [ ] `GET /accounts` con 20 cuentas ejecuta **una** query de saldos (verifica con `spring.jpa.show-sql`).

---

## F2.2 — Backend: CRUD de categories

> **Modelo: 🟢 Haiku.** Es F2.1 sin la parte difícil: mismo patrón de capas, mismo filtro por
> `userId`, mismo archivado RB-02, pero sin ningún cálculo. Con el módulo `account` ya en el repo,
> Haiku tiene un ejemplo literal que seguir.
> Indícale explícitamente en el prompt: *"replica la estructura de `com.fintrack.account`"*.

**Archivos**

```
com.fintrack.category/
├── Category.java             # @Entity, enum CategoryKind {INCOME, EXPENSE}
├── CategoryRepository.java
├── CategoryService.java
├── CategoryController.java
├── CategoryMapper.java
├── CategorySeedService.java  # ya existe desde F1.1
└── dto/{CategoryRequest, CategoryResponse}.java
```

**Contrato (§4.3)**

| Método | Ruta | Notas |
|---|---|---|
| GET | `/categories?kind=INCOME\|EXPENSE&includeArchived=false` | `kind` opcional; sin él, todas |
| POST | `/categories` | `{name, kind, color, icon}` → 201 |
| PUT | `/categories/{id}` | `kind` **no** es editable |
| DELETE | `/categories/{id}` | archiva si tiene transacciones o presupuestos (RB-02) |

**Reglas**
- Único por `(user_id, name, kind)`, case-insensitive → duplicado 409.
- `color`: hex `#RRGGBB` validado con regex. `icon`: nombre de icono Material, `VARCHAR(40)`.
- `kind` inmutable: cambiarlo rompería transacciones y presupuestos existentes. Intentarlo → 422.
- DELETE: si tiene transacciones **o** presupuestos → archiva; si no → borrado físico.
- Ordena por `name` ascendente para que la UI no tenga que hacerlo.

**Aceptación**
- [ ] Un usuario recién registrado tiene las 12 categorías default (F1.1).
- [ ] `?kind=EXPENSE` devuelve solo las de gasto.
- [ ] Nombre repetido en el mismo `kind` → 409; el mismo nombre en el otro `kind` → 201.
- [ ] Color `rojo` → 400 con `errors[{field: "color"}]`.
- [ ] PUT intentando cambiar `kind` → 422.
- [ ] DELETE de categoría con transacciones → archivada, y sus transacciones siguen resolviendo su nombre.

---

## F2.3 — Flutter: Ajustes con CRUD de cuentas y categorías

> **Modelo: 🟢 Haiku.** Dos features que siguen el patrón `data/ → providers/ → presentation/` ya
> montado en F1.4, con listas, sheets de formulario y estados loading/vacío/error. Volumen alto,
> dificultad baja: exactamente el perfil de Haiku.
> **Escala a Sonnet** solo si la invalidación cruzada de providers (crear una cuenta debe refrescar
> también el dashboard más adelante) empieza a dar listas desactualizadas.

**Archivos**

```
app/lib/features/accounts/
├── data/{models/account_model.dart, accounts_api.dart}
├── providers/accounts_provider.dart      # AsyncNotifier<List<Account>>
└── presentation/{accounts_screen.dart, account_form_sheet.dart, widgets/account_card.dart}

app/lib/features/categories/
├── data/{models/category_model.dart, categories_api.dart}
├── providers/categories_provider.dart
└── presentation/{categories_screen.dart, category_form_sheet.dart, widgets/category_tile.dart}

app/lib/features/settings/presentation/settings_screen.dart
```

**Rutas (§5.1):** `/settings` → `/settings/accounts`, `/settings/categories`.

**Pantalla Ajustes**
- Cabecera con nombre y email del usuario.
- Filas: "Cuentas", "Categorías", selector de tema (claro/oscuro/sistema), "Cerrar sesión" (con confirmación).

**Pantalla Cuentas**
- Lista de tarjetas: nombre, tipo (chip con icono), `currentBalance` formateado (`$1,234.50`);
  saldo negativo en rojo.
- Al final, "Total" con la suma de saldos.
- FAB "+" abre un `BottomSheet` con el formulario: nombre, tipo (dropdown), saldo inicial (teclado numérico).
- Tap → editar; swipe o menú → eliminar con diálogo de confirmación que explica el archivado.
- Toggle "Mostrar archivadas" que pasa `includeArchived=true`.

**Pantalla Categorías**
- `TabBar` con Gastos / Ingresos.
- Cada tile: icono con el color de fondo de la categoría + nombre.
- Formulario: nombre, selector de color (paleta de ~12 opciones + hex), selector de icono
  (grid con un set curado de ~30 iconos Material).
- Mismo patrón de eliminar/archivar que cuentas.

**Reglas de UI**
- Estados: loading (skeletons), vacío (ilustración + CTA "Crea tu primera cuenta"), error
  (mensaje + botón "Reintentar").
- Tras crear/editar/borrar, se invalida el provider para refrescar la lista.
- Errores 409 del backend → snackbar con "Ya existe una cuenta con ese nombre".
- Todos los montos vía `MoneyFormatter`; nada de `toString()` sobre `Decimal`.

**Aceptación**
- [ ] Crear, editar y archivar una cuenta desde la app se refleja en la BD.
- [ ] El saldo mostrado coincide con el que devuelve el endpoint.
- [ ] Crear una categoría con nombre duplicado muestra el mensaje de error, no un crash.
- [ ] Lista vacía muestra el estado vacío, no un spinner infinito.
- [ ] `flutter analyze` limpio.

---

## Prompt sugerido

Antes de lanzarlo, cambia al modelo que indica la anotación de esa tarea. En F2.2 y F2.3, añade al
prompt qué módulo ya existente debe replicarse.

> Lee `plans/04-CUENTAS-Y-CATEGORIAS.md` y `plans/00-INDICE-Y-CONVENCIONES.md`. Implementa **solo F2.X**.
> Respeta RB-01 (saldo calculado en una sola query, nunca persistido) y RB-02 (archivar en vez de borrar
> cuando hay dependencias). Verifica los criterios de aceptación con peticiones reales y muéstrame el SQL
> generado para el listado de cuentas.

## Cierre de fase

- [ ] Los tres checklists completos.
- [ ] La app permite montar el catálogo completo (cuentas + categorías) antes de registrar movimientos.
- [ ] Commit/tag `fase-2-catalogos`.

**Siguiente:** [`05-TRANSACCIONES-BACKEND.md`](05-TRANSACCIONES-BACKEND.md).
