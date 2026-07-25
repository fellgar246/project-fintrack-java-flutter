# 05 — Transacciones: backend (Fase 3, parte backend)

> Cubre **F3.1 – F3.2** del [plan maestro](../PLAN_MAESTRO_FINTRACK.md) (§4.4, RB-03, RB-04, RB-05).
> Convenciones: [`00-INDICE-Y-CONVENCIONES.md`](00-INDICE-Y-CONVENCIONES.md).

## Objetivo

El núcleo de la aplicación: crear, editar, borrar y listar transacciones (ingreso, gasto,
transferencia) con validación estricta y un listado paginado con filtros que la app pueda explotar
sin traerse toda la tabla.

## Prerrequisitos

- [`04-CUENTAS-Y-CATEGORIAS.md`](04-CUENTAS-Y-CATEGORIAS.md) — F2.1 y F2.2 completos (necesitas
  cuentas y categorías para validar referencias).

## Reparto de modelos

Criterio completo en [§5 del índice](00-INDICE-Y-CONVENCIONES.md#5-reparto-de-modelos-haiku-vs-sonnet).
**Fase enteramente Sonnet.** Es el núcleo del dominio: aquí viven las reglas que hacen que los
saldos, los presupuestos y los reportes cuadren. Un error en F3.1 o F3.2 no se manifiesta como un
crash, sino como números incorrectos tres fases más adelante, y para entonces cuesta mucho más
localizarlo. Es el peor sitio del proyecto para ahorrar.

| Tarea | Modelo |
|---|---|
| F3.1 POST/PUT/DELETE | 🔵 Sonnet |
| F3.2 GET paginado con filtros | 🔵 Sonnet |

Las únicas piezas delegables a 🟢 Haiku, **una vez que Sonnet cerró el servicio**: los DTOs, el
`TransactionMapper` y los ejemplos de Swagger.

---

## F3.1 — POST / PUT / DELETE de transacciones

> **Modelo: 🔵 Sonnet.** Ocho validaciones encadenadas cuyo orden importa, con dos ramas
> incompatibles (TRANSFER vs. INCOME/EXPENSE) y una revalidación completa cuando el PUT cambia de
> tipo. La regla de coherencia `type` ↔ `category.kind` es la que sostiene todos los reportes por
> categoría: si se cuela un gasto con categoría de ingreso, los porcentajes de F5.1 dejan de sumar
> 100 y el síntoma aparece muy lejos de la causa.

**Archivos**

```
com.fintrack.transaction/
├── Transaction.java          # @Entity, enum TransactionType {INCOME, EXPENSE, TRANSFER}
├── TransactionRepository.java
├── TransactionService.java
├── TransactionController.java
├── TransactionMapper.java
└── dto/{TransactionRequest, TransactionResponse}.java
```

**Contrato**

| Método | Ruta | Respuesta |
|---|---|---|
| POST | `/transactions` | 201 + `TransactionResponse` |
| GET | `/transactions/{id}` | 200 / 404 |
| PUT | `/transactions/{id}` | 200 |
| DELETE | `/transactions/{id}` | 204 — **hard delete** (§4.4) |

**`TransactionRequest`**
```json
{
  "type": "EXPENSE",
  "amount": "1234.50",
  "date": "2026-07-25",
  "accountId": "uuid",
  "categoryId": "uuid",
  "transferAccountId": null,
  "note": "Súper"
}
```

**`TransactionResponse`** — lo anterior + `id`, `createdAt`, `updatedAt` y objetos anidados ligeros
para que la lista no tenga que hacer joins en el cliente:
```json
{
  "account":  { "id": "...", "name": "Efectivo" },
  "category": { "id": "...", "name": "Comida", "color": "#FF7043", "icon": "restaurant" },
  "transferAccount": null
}
```

**Validaciones (en este orden)**

1. `amount` > 0 siempre (el signo lo da `type`, nunca el número) → 400.
2. `amount` con máximo 2 decimales y ≤ `99999999999.99` (cabe en `DECIMAL(14,2)`) → 400.
3. `date` obligatoria. Fecha futura: **permitida** (movimientos programados), pero limita a
   +1 año para atrapar errores de tecleo → 400.
4. `accountId` debe existir, ser del usuario y **no estar archivada** → 404 / 422.
5. **RB-03 (TRANSFER):**
   - `categoryId` debe ser `null` → 422 si viene.
   - `transferAccountId` obligatorio, existente, del usuario, no archivada → 422.
   - `transferAccountId != accountId` → 422 ("No se puede transferir a la misma cuenta").
6. **INCOME / EXPENSE:**
   - `categoryId` obligatorio, existente, del usuario, no archivada → 422.
   - `transferAccountId` debe ser `null` → 422.
   - **Coherencia de tipo:** `type=EXPENSE` exige `category.kind = EXPENSE`; `type=INCOME` exige
     `category.kind = INCOME` → 422. (Esto es lo que hace que los reportes por categoría cuadren.)
7. `note` ≤ 255 caracteres.
8. RB-05: `user_id` siempre del token; una transacción de otro usuario → 404.

> Las validaciones 5 y 6 duplican el `CHECK` de BD de F0.4 a propósito: la BD es la red de seguridad,
> el servicio es el que da mensajes útiles.

**PUT**
- Permite cambiar de tipo (p. ej. EXPENSE → TRANSFER); revalida **todo** el conjunto de reglas.
- Actualiza `updated_at`.

**DELETE**
- Hard delete, sin confirmación en backend (la confirmación es de UI).

**Aceptación**
- [ ] EXPENSE válido → 201, y el saldo de la cuenta (F2.1) baja exactamente ese monto.
- [ ] `amount: "-50"` o `"0"` → 400.
- [ ] `amount: "10.999"` → 400.
- [ ] TRANSFER con `categoryId` → 422; sin `transferAccountId` → 422; a la misma cuenta → 422.
- [ ] EXPENSE con una categoría `kind = INCOME` → 422 con mensaje claro.
- [ ] EXPENSE con `transferAccountId` → 422.
- [ ] Cuenta o categoría archivada → 422.
- [ ] PUT de EXPENSE a TRANSFER limpia `category_id` y exige `transfer_account_id`.
- [ ] DELETE → 204 y la fila desaparece; el saldo de la cuenta se recalcula solo.
- [ ] Id de otro usuario en GET/PUT/DELETE → 404.

---

## F3.2 — GET paginado con filtros

> **Modelo: 🔵 Sonnet.** Tres trampas que un modelo rápido pasa por alto porque el resultado *parece*
> correcto: (1) el desempate por `id` en el `sort` — sin él, dos transacciones del mismo día se
> duplican o desaparecen al paginar; (2) el `EntityGraph` para evitar N+1 al mapear tres relaciones;
> (3) validar `sort` contra una lista blanca en vez de pasárselo a Hibernate. Todas dan 200 OK
> mientras están mal.

**Contrato (§4.4)**

```
GET /transactions?page=0&size=20&sort=date,desc
    &from=2026-07-01&to=2026-07-31
    &accountId=...&categoryId=...&type=EXPENSE&search=super
```

**Parámetros**

| Param | Tipo | Default | Notas |
|---|---|---|---|
| `page` | int | 0 | |
| `size` | int | 20 | máximo 100 (recorta, no falles) |
| `sort` | string | `date,desc` | permitidos: `date`, `amount`, `createdAt` |
| `from` / `to` | `yyyy-MM-dd` | — | inclusivos; `from > to` → 400 |
| `accountId` | UUID | — | coincide con origen **o** destino de transferencia |
| `categoryId` | UUID | — | |
| `type` | enum | — | INCOME / EXPENSE / TRANSFER |
| `search` | string | — | `ILIKE %texto%` sobre `note` |

**Respuesta**
```json
{
  "content": [ /* TransactionResponse[] */ ],
  "page": 0, "size": 20, "totalElements": 143, "totalPages": 8, "last": false
}
```

Usa un envelope propio y estable, **no** el serializado por defecto de `Page` de Spring (cambia entre
versiones y expone campos internos).

**Implementación**
- Filtros dinámicos con **JPA Specifications** o Criteria API. Nada de concatenar SQL.
- `EntityGraph`/`join fetch` de `account`, `category` y `transferAccount` para evitar N+1 al mapear.
- **Desempate obligatorio:** el `sort` siempre añade `id` como último criterio. Sin esto, dos
  transacciones del mismo día pueden aparecer duplicadas o desaparecer al paginar.
- Índice `(user_id, date)` de F0.4 debe usarse: verifica con `EXPLAIN ANALYZE`.
- `userId` del token siempre en el `where`, antes que cualquier filtro opcional (RB-05).

**Aceptación**
- [ ] Sin filtros devuelve la primera página ordenada por fecha descendente.
- [ ] `from`/`to` acotan correctamente, incluyendo los días límite.
- [ ] `accountId` de una cuenta destino de transferencia **sí** devuelve esa transferencia.
- [ ] `search=super` encuentra "Súper" y "SUPERMERCADO" (case-insensitive).
- [ ] Filtros combinados (`type` + `categoryId` + rango) funcionan a la vez.
- [ ] `size=500` se recorta a 100.
- [ ] `sort=malicious` → 400, no una excepción de Hibernate.
- [ ] Con 200 transacciones sembradas, paginar de la 0 a la última no repite ni pierde registros.
- [ ] `show-sql` confirma 1 query de datos + 1 de count, sin N+1.

---

## Prompt sugerido

Ambas tareas con Sonnet. Delega a Haiku solo los DTOs, el mapper y los ejemplos de Swagger, después.

> Lee `plans/05-TRANSACCIONES-BACKEND.md` y `plans/00-INDICE-Y-CONVENCIONES.md`. Implementa **solo F3.X**.
> Aplica RB-03/RB-04/RB-05 tal como están escritas y usa Specifications para los filtros. Al terminar,
> ejecuta todos los criterios de aceptación con peticiones reales y muéstrame el SQL del listado más el
> resultado de un `EXPLAIN ANALYZE`.

## Cierre de fase (backend)

- [ ] Ambos checklists completos.
- [ ] Los saldos de `/accounts` reaccionan correctamente a altas, ediciones y bajas.
- [ ] Todos los endpoints documentados en Swagger con ejemplos de request/response.
- [ ] Commit/tag `fase-3-transactions-backend`.

**Siguiente:** [`06-TRANSACCIONES-FLUTTER.md`](06-TRANSACCIONES-FLUTTER.md).
