# 07 — Presupuestos (Fase 4)

> Cubre **F4.1 – F4.2** del [plan maestro](../PLAN_MAESTRO_FINTRACK.md) (§4.5, §5.2.5, RB-04).
> Convenciones: [`00-INDICE-Y-CONVENCIONES.md`](00-INDICE-Y-CONVENCIONES.md).

## Objetivo

El usuario define un límite de gasto por categoría y por mes, y ve cuánto lleva gastado con
semáforo de color. Es la primera feature que **cruza** presupuestos con transacciones reales.

## Prerrequisitos

- [`05-TRANSACCIONES-BACKEND.md`](05-TRANSACCIONES-BACKEND.md) completo (hacen falta transacciones
  reales para calcular `spentAmount`).
- [`04-CUENTAS-Y-CATEGORIAS.md`](04-CUENTAS-Y-CATEGORIAS.md) — categorías `EXPENSE`.

## Reparto de modelos

Criterio completo en [§5 del índice](00-INDICE-Y-CONVENCIONES.md#5-reparto-de-modelos-haiku-vs-sonnet).

| Tarea | Modelo |
|---|---|
| F4.1 Upsert + `spentAmount` | 🔵 Sonnet |
| F4.2 Pantalla de presupuestos | 🟢 Haiku |

El reparto sale de una decisión de diseño deliberada: **el `status` del semáforo se calcula en el
backend**, no en Dart. Eso convierte la pantalla en una lista que pinta lo que recibe, y por tanto en
trabajo de Haiku.

---

## F4.1 — Backend: upsert y GET con `spentAmount`

> **Modelo: 🔵 Sonnet.** Tres cosas que exigen criterio: la agregación con `LEFT JOIN` filtrando por
> `type = 'EXPENSE'` y por **rango de fechas** (usar `to_char` sobre la columna anula el índice
> `(user_id, date)` y la query sigue dando el resultado correcto, solo que lenta); el redondeo con
> `BigDecimal` y `HALF_UP` con sus casos límite (0%, exactamente 100%, >100%); y la semántica del
> upsert, que responde 200 tanto al crear como al actualizar.

**Archivos**

```
com.fintrack.budget/
├── Budget.java               # @Entity
├── BudgetRepository.java
├── BudgetService.java
├── BudgetController.java
└── dto/{BudgetUpsertRequest, BudgetResponse, BudgetSummaryResponse}.java
```

**Contrato (§4.5)**

| Método | Ruta | Body | Respuesta |
|---|---|---|---|
| GET | `/budgets?yearMonth=2026-07` | — | 200 lista con `spentAmount` y `percentUsed` |
| PUT | `/budgets` | `{categoryId, yearMonth, limitAmount}` | 200 (upsert) |
| DELETE | `/budgets/{id}` | — | 204 |

**`BudgetResponse`**
```json
{
  "id": "uuid",
  "category": { "id": "...", "name": "Comida", "color": "#FF7043", "icon": "restaurant" },
  "yearMonth": "2026-07",
  "limitAmount": "5000.00",
  "spentAmount": "3250.75",
  "remainingAmount": "1749.25",
  "percentUsed": 65.02,
  "status": "OK"
}
```

`status`: `OK` (<70%), `WARNING` (70–99.99%), `EXCEEDED` (≥100%). Calcularlo en backend evita que
frontend y reportes usen umbrales distintos.

**Cálculo de `spentAmount`**

```sql
SELECT b.id, COALESCE(SUM(t.amount), 0) AS spent
FROM budgets b
LEFT JOIN transactions t
       ON t.category_id = b.category_id
      AND t.user_id     = b.user_id
      AND t.type        = 'EXPENSE'          -- RB-03: transferencias excluidas
      AND to_char(t.date, 'YYYY-MM') = b.year_month
WHERE b.user_id = :userId AND b.year_month = :yearMonth
GROUP BY b.id;
```

- Una sola query para todos los presupuestos del mes. Nada de N+1.
- Si prefieres que el índice `(user_id, date)` se use, filtra por rango en vez de `to_char`:
  `t.date >= :firstDay AND t.date < :firstDayNextMonth`. **Preferible** — `to_char` sobre la columna
  impide usar el índice.
- `percentUsed` = `spent / limit * 100`, redondeado a 2 decimales. Puede pasar de 100.
- Cálculo con `BigDecimal` y `RoundingMode.HALF_UP`. Nunca `double`.

**Reglas**
- **RB-04:** solo categorías con `kind = EXPENSE`. Una categoría `INCOME` → **422**.
- `limitAmount` > 0 → 400 si no.
- `yearMonth` debe cumplir `^\d{4}-(0[1-9]|1[0-2])$` → 400 si no.
- Upsert por `(user_id, category_id, year_month)`: si existe, actualiza `limit_amount`; si no, crea.
  Responde 200 en ambos casos (documenta que no hay 201).
- Categoría archivada: no se pueden **crear** presupuestos nuevos (422), pero los existentes se
  siguen mostrando con su gasto.
- `GET` sin `yearMonth` → default al mes actual del servidor.
- Presupuesto de otro usuario → 404.
- Opcional útil: `GET /budgets?yearMonth=&includeUnbudgeted=true` añade las categorías EXPENSE sin
  presupuesto con `limitAmount = null`, para que la UI ofrezca "definir límite" en una sola pantalla.

**Aceptación**
- [ ] PUT crea el presupuesto; PUT otra vez con el mismo `(categoryId, yearMonth)` **actualiza**, no duplica.
- [ ] Con límite 5000 y gastos por 3250.75 → `spentAmount = "3250.75"`, `percentUsed = 65.02`, `status = OK`.
- [ ] Un gasto del mes anterior **no** cuenta.
- [ ] Una transferencia sobre esa categoría no puede existir (RB-03) y por tanto no afecta.
- [ ] Un ingreso en una categoría INCOME no afecta a ningún presupuesto.
- [ ] Gastado 5000 de 5000 → `percentUsed = 100.00`, `status = EXCEEDED`, `remainingAmount = "0.00"`.
- [ ] Gastado 6000 de 5000 → `percentUsed = 120.00`, `remainingAmount = "-1000.00"`.
- [ ] Categoría `INCOME` en el upsert → 422.
- [ ] `yearMonth = "2026-13"` → 400.
- [ ] 12 presupuestos en el mes → 1 sola query de gasto (verifica con `show-sql`).

---

## F4.2 — Flutter: pantalla de presupuestos (§5.2.5)

> **Modelo: 🟢 Haiku.** Lista de tarjetas con barra de progreso, selector de mes y un sheet de
> formulario, todo sobre el patrón de F2.3. El color del semáforo llega resuelto desde el backend
> (`status`), así que no hay lógica de umbrales que replicar ni riesgo de que frontend y reportes
> discrepen.
> **Excepción 🔵 Sonnet:** "Copiar del mes anterior", si decides que sea atómica (crear N
> presupuestos y no dejar el mes a medias si una llamada falla).

**Archivos**

```
app/lib/features/budgets/
├── data/{models/budget_model.dart, budgets_api.dart}
├── providers/budgets_provider.dart      # family por yearMonth
└── presentation/
    ├── budgets_screen.dart
    ├── budget_form_sheet.dart
    └── widgets/{budget_card.dart, month_selector.dart, budget_progress_bar.dart}
```

**Ruta:** `/budgets` (tab del shell).

**Layout**
- **Selector de mes** arriba: flechas ‹ › con el mes en el centro ("Julio 2026"); tocar el título abre
  un picker de mes/año. Bloquea navegar más allá del mes actual + 12.
- **Tarjeta resumen**: total presupuestado, total gastado, disponible, y una barra global.
- **Lista de tarjetas por categoría**:
  - icono + color de la categoría, nombre
  - `$3,250.75 / $5,000.00` y a la derecha `65%`
  - barra de progreso (`budget_progress_bar`) con los colores de §5.2.5:
    - `< 70%` → verde
    - `70–99.99%` → ámbar
    - `≥ 100%` → rojo (y la barra se llena al 100% con indicador de exceso)
  - texto auxiliar: "Te quedan $1,749.25" o "Te pasaste por $1,000.00"
- Sección "Sin presupuesto" al final con las categorías EXPENSE sin límite y un botón "Definir".
- FAB "+" → sheet para elegir categoría (solo EXPENSE, no archivadas) e importe.
- Tap en una tarjeta → editar límite; long press / menú → eliminar con confirmación.
- Acción "Copiar del mes anterior" cuando el mes seleccionado no tiene ningún presupuesto — evita
  reescribir 8 límites cada mes.

**Reglas de UI**
- Los colores del semáforo salen de `status` del backend, no se recalculan en Dart.
- Barra animada (`AnimatedFractionallySizedBox` o `TweenAnimationBuilder`, ~300 ms).
- Accesibilidad: el color no es la única señal; el porcentaje va siempre en texto.
- Estados loading/vacío/error como en el resto de la app.
- Al guardar un presupuesto se invalida el provider del mes visible y el del dashboard.

**Aceptación**
- [ ] Cambiar de mes recarga los datos de ese mes.
- [ ] Los tres colores aparecen correctamente en los umbrales 69% / 70% / 100%.
- [ ] Registrar un gasto nuevo en Transacciones y volver a Presupuestos refleja el gasto actualizado.
- [ ] "Copiar del mes anterior" crea los presupuestos del mes actual con los mismos límites.
- [ ] Un mes sin presupuestos muestra el estado vacío con CTA, no una lista en blanco.
- [ ] `flutter analyze` limpio.

---

## Prompt sugerido

F4.1 con Sonnet, F4.2 con Haiku indicándole que replique el patrón de `features/accounts`.

> Lee `plans/07-PRESUPUESTOS.md` y `plans/00-INDICE-Y-CONVENCIONES.md`. Implementa **solo F4.X**.
> Aplica RB-04 (solo categorías EXPENSE) y calcula `spentAmount` con una única query filtrando por
> rango de fechas para aprovechar el índice `(user_id, date)`. Usa `BigDecimal` en backend y `Decimal`
> en Flutter. Verifica los criterios de aceptación con datos reales.

## Cierre de fase

- [ ] Ambos checklists completos.
- [ ] Los números de presupuestos cuadran con los de la lista de transacciones filtrada por esa
      categoría y mes.
- [ ] Commit/tag `fase-4-presupuestos`.

**Siguiente:** [`08-DASHBOARD-Y-REPORTES.md`](08-DASHBOARD-Y-REPORTES.md).
