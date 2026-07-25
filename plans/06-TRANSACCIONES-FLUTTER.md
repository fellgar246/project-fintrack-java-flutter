# 06 — Transacciones: Flutter (Fase 3, parte frontend)

> Cubre **F3.3 – F3.4** del [plan maestro](../PLAN_MAESTRO_FINTRACK.md) (§5.2.3, §5.2.4, §5.3).
> Convenciones: [`00-INDICE-Y-CONVENCIONES.md`](00-INDICE-Y-CONVENCIONES.md).

## Objetivo

Las dos pantallas que el usuario más va a usar: registrar un movimiento en pocos toques y encontrar
cualquier movimiento pasado.

## Prerrequisitos

- [`05-TRANSACCIONES-BACKEND.md`](05-TRANSACCIONES-BACKEND.md) completo.
- Providers de cuentas y categorías de F2.3 disponibles (los selectores los reutilizan).

## Reparto de modelos

Criterio completo en [§5 del índice](00-INDICE-Y-CONVENCIONES.md#5-reparto-de-modelos-haiku-vs-sonnet).

| Tarea | Modelo |
|---|---|
| F3.3 Alta/edición de transacción | 🟡 Mixto |
| F3.4 Lista con filtros y scroll infinito | 🔵 Sonnet |

Dentro de F3.3, el corte es limpio: los widgets presentacionales
(`category_picker_grid`, `day_group_header`, `transaction_tile`) reciben datos y no deciden nada
→ 🟢 Haiku. El controller del formulario y el `amount_keypad` sí → 🔵 Sonnet.

---

## Estructura de la feature

```
app/lib/features/transactions/
├── data/
│   ├── models/{transaction_model.dart, transaction_request.dart, page_response.dart}
│   └── transactions_api.dart
├── providers/
│   ├── transactions_list_provider.dart   # paginación + filtros
│   ├── transaction_filters_provider.dart # estado de filtros
│   └── transaction_form_provider.dart    # alta/edición
└── presentation/
    ├── transactions_screen.dart
    ├── transaction_form_screen.dart
    └── widgets/
        ├── transaction_tile.dart
        ├── day_group_header.dart
        ├── filter_chips_bar.dart
        ├── amount_keypad.dart
        └── category_picker_grid.dart
```

---

## F3.3 — Alta y edición de transacción (§5.2.4)

> **Modelo: 🟡 Mixto.**
> - 🔵 **Sonnet:** `transaction_form_provider` y `amount_keypad`. El formulario **cambia de forma**
>   según el tipo seleccionado (categoría aparece/desaparece, cuenta destino aparece/desaparece) sin
>   perder los valores ya capturados, y el teclado debe construir el monto como cadena para no pasar
>   nunca por `double` — el motivo entero de usar `Decimal`. Además hay que mapear los 422 del
>   backend al campo correcto.
> - 🟢 **Haiku:** `category_picker_grid` y los selectores de cuenta, fecha y nota. Widgets que
>   reciben datos y emiten callbacks.

**Rutas:** `/transactions/new` y `/transactions/:id` (la misma pantalla en dos modos).

**Layout de arriba a abajo**

1. **Selector de tipo** — `SegmentedButton` con Gasto / Ingreso / Transferencia.
   Cambiar de tipo reconfigura el formulario en vivo:
   - Gasto/Ingreso → muestra categoría (filtrada por `kind` correspondiente), oculta cuenta destino.
   - Transferencia → oculta categoría, muestra "Cuenta destino".
2. **Monto** — display grande con el valor formateado y un teclado numérico propio
   (`amount_keypad.dart`): dígitos, punto decimal, borrar. Máximo 2 decimales, se impide un segundo punto.
   El color del monto sigue al tipo (rojo gasto, verde ingreso, azul transferencia).
3. **Categoría** — grid de 4 columnas con círculo de color + icono + nombre; el seleccionado con borde.
   Solo categorías no archivadas del `kind` correcto.
4. **Cuenta** (y **Cuenta destino** si es transferencia) — dropdown con nombre y saldo actual.
   Validación en cliente: origen ≠ destino.
5. **Fecha** — chips rápidos "Hoy" / "Ayer" + `showDatePicker`. Default: hoy.
6. **Nota** — `TextField` opcional, máx. 255, con contador.
7. **Guardar** — botón ancho fijo abajo; deshabilitado si el form es inválido; spinner al enviar.

**Modo edición**
- Precarga los valores de la transacción.
- Botón de eliminar en el `AppBar` con diálogo de confirmación.

**Manejo de errores**
- Un 422 del backend se mapea al campo correspondiente usando `fieldErrors` del Problem Details;
  si no hay campo, snackbar con el `detail`.
- Al guardar con éxito: invalida `transactionsListProvider`, `accountsProvider` y (si existe ya)
  `budgetsProvider` y `dashboardProvider`; luego `pop()`.

**Detalle de dinero:** el monto se maneja como `Decimal` y se envía como **string**. Nunca
`double.parse`. El teclado construye la cadena carácter a carácter, así que no hay conversión binaria
intermedia.

**Aceptación**
- [ ] Registrar un gasto de `$1,234.50` guarda exactamente `1234.50` en BD.
- [ ] Cambiar de Gasto a Transferencia oculta categoría y exige cuenta destino.
- [ ] Origen = destino muestra error de cliente sin llegar al servidor.
- [ ] No se puede teclear un tercer decimal ni dos puntos.
- [ ] Editar una transacción existente conserva todos los valores y guarda solo lo que cambió.
- [ ] Tras guardar, el saldo de la cuenta en Ajustes ya está actualizado.
- [ ] Con el backend caído, el botón deja de girar y aparece un error accionable.

---

## F3.4 — Lista con filtros, búsqueda y paginación infinita (§5.2.3)

> **Modelo: 🔵 Sonnet.** Es el estado más complicado del frontend: `loadMore()` debe ser reentrante
> sin duplicar páginas, cambiar un filtro tiene que **descartar** las respuestas en vuelo de la
> consulta anterior (si no, llegan tarde y contaminan la lista nueva), y el debounce de búsqueda
> interactúa con ambos. Los bugs resultantes —ítems repetidos, resultados de un filtro que ya no está
> activo— son intermitentes y difíciles de reproducir a mano.
> 🟢 **Haiku** puede hacer después `transaction_tile`, `day_group_header` y `filter_chips_bar`.

**Ruta:** `/transactions`.

**Layout**
- `AppBar` con campo de búsqueda (aparece al tocar la lupa), **debounce de 400 ms**.
- Barra de chips de filtro horizontal: rango de fechas (mes actual por default), tipo, cuenta, categoría.
  Chip activo en color primario y con "×" para limpiarlo. Botón "Limpiar todo" cuando hay ≥1 filtro.
- Lista **agrupada por día**: encabezado sticky con la fecha (`Hoy`, `Ayer`, `martes 22 de julio`) y a la
  derecha el neto del día.
- `transaction_tile`: círculo con icono/color de categoría, nombre de categoría (o "A → B" para
  transferencias), nota como subtítulo, monto a la derecha con signo y color.
- **Scroll infinito:** carga la siguiente página al llegar al ~80% del scroll; loader al pie;
  "No hay más movimientos" al final.
- **Swipe para eliminar** (`Dismissible`) con diálogo de confirmación; si el usuario cancela, el
  ítem vuelve a su sitio.
- Pull-to-refresh reinicia a la página 0.
- FAB "+" → `/transactions/new`.

**Provider de lista**
- `AsyncNotifier` que guarda `List<Transaction>`, `page`, `hasMore`, `isLoadingMore`.
- `loadMore()` protegido contra llamadas concurrentes (ignora si ya está cargando o si `!hasMore`).
- Cambiar cualquier filtro → resetea a página 0 y limpia la lista acumulada.
- Los filtros viven en su propio provider para que la pantalla de reportes pueda reutilizarlos después.

**Estados**
- Loading inicial: skeletons de 6 filas.
- Vacío sin filtros: "Aún no registras movimientos" + CTA.
- Vacío **con** filtros: "No hay resultados para estos filtros" + "Limpiar filtros" (mensaje distinto,
  es un caso distinto).
- Error: mensaje + "Reintentar".

**Aceptación**
- [ ] 100+ transacciones se recorren sin duplicados ni saltos al hacer scroll.
- [ ] Buscar dispara **una** petición tras dejar de escribir, no una por tecla.
- [ ] Combinar filtros (tipo + cuenta + rango) devuelve lo mismo que el endpoint probado en F3.2.
- [ ] Eliminar por swipe pide confirmación, quita el ítem y actualiza el neto del día.
- [ ] Pull-to-refresh trae los cambios hechos desde otro cliente (Swagger).
- [ ] Los dos estados vacíos muestran mensajes distintos.
- [ ] `flutter analyze` limpio.

---

## Prompt sugerido

Empieza por los providers con Sonnet; los widgets presentacionales van después con Haiku.

> Lee `plans/06-TRANSACCIONES-FLUTTER.md` y `plans/00-INDICE-Y-CONVENCIONES.md`. Implementa **solo F3.X**.
> Usa Riverpod para todo el estado (nada de `setState` para datos), `Decimal` para montos y el
> `MoneyFormatter` compartido. Después corre `flutter analyze` y valida los criterios de aceptación
> con el backend levantado y datos de prueba.

## Cierre de fase 3

- [ ] Flujo completo: crear cuenta → crear categoría → registrar gasto → verlo en la lista → editarlo →
      borrarlo → el saldo cuadra en todo momento.
- [ ] Commit/tag `fase-3-transacciones`.

**Siguiente:** [`07-PRESUPUESTOS.md`](07-PRESUPUESTOS.md).
