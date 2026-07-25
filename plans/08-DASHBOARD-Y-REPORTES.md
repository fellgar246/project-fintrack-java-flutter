# 08 — Dashboard y reportes (Fase 5)

> Cubre **F5.1 – F5.3** del [plan maestro](../PLAN_MAESTRO_FINTRACK.md) (§4.6, §5.2.2, §5.2.6).
> Convenciones: [`00-INDICE-Y-CONVENCIONES.md`](00-INDICE-Y-CONVENCIONES.md).

## Objetivo

Cerrar el producto: agregaciones en backend, dashboard como pantalla de entrada, gráficas y export
CSV. Es lo que hace que el proyecto se vea como una app terminada en el portafolio.

## Prerrequisitos

- [`07-PRESUPUESTOS.md`](07-PRESUPUESTOS.md) completo (el dashboard muestra top presupuestos).
- Datos de prueba: al menos 6 meses de transacciones para que las gráficas digan algo. Crea un script
  o endpoint de seed **solo para perfil `dev`**.

## Reparto de modelos

Criterio completo en [§5 del índice](00-INDICE-Y-CONVENCIONES.md#5-reparto-de-modelos-haiku-vs-sonnet).

| Tarea | Modelo |
|---|---|
| F5.1 Endpoints de reports | 🔵 Sonnet |
| F5.2 Dashboard | 🟢 Haiku |
| F5.3 Gráficas + export CSV | 🟡 Mixto |

F5.2 es Haiku precisamente porque llega tarde: a estas alturas ya existen `transaction_tile`,
`budget_progress_bar`, `MoneyFormatter` y el patrón de providers. El dashboard **compone**, no
inventa. Si Haiku empieza a duplicar widgets en vez de reutilizarlos, córtalo y recuérdaselo en el
prompt — no es un caso para escalar de modelo.

---

## F5.1 — Backend: endpoints de reports (§4.6)

> **Modelo: 🔵 Sonnet.** Cuatro endpoints, cuatro problemas distintos: excluir transferencias sin
> romper `byAccount` (RB-03); porcentajes que sumen 100 con `HALF_UP` y sin dividir entre cero;
> rellenar con ceros los meses vacíos de `trend` —si faltan, la gráfica de F5.3 miente sobre el eje
> temporal y nadie lo nota—; y un CSV con escapado correcto de comillas y BOM UTF-8. Además debe
> **reutilizar** el cálculo de saldo de F2.1 en lugar de duplicar el SQL.


**Archivos**

```
com.fintrack.report/
├── ReportController.java
├── ReportService.java
├── ReportRepository.java        # queries nativas de agregación
├── CsvExportService.java
└── dto/{SummaryResponse, ByCategoryResponse, TrendResponse}.java
```

### `GET /reports/summary?yearMonth=2026-07`

```json
{
  "yearMonth": "2026-07",
  "totalIncome": "18500.00",
  "totalExpense": "12340.50",
  "net": "6159.50",
  "byAccount": [
    { "accountId": "...", "name": "Efectivo", "income": "2000.00",
      "expense": "1500.00", "currentBalance": "3200.00" }
  ]
}
```

- **RB-03:** las transferencias se excluyen de `totalIncome` y `totalExpense`. Son movimientos
  internos, no dinero que entra o sale del patrimonio.
- `currentBalance` por cuenta usa la misma lógica de RB-01 de F2.1 — **extrae ese cálculo a un método
  compartido** en vez de duplicar el SQL.

### `GET /reports/by-category?yearMonth=2026-07&kind=EXPENSE`

```json
[
  { "categoryId": "...", "name": "Comida", "color": "#FF7043",
    "icon": "restaurant", "total": "4200.00", "percent": 34.03 }
]
```

- `kind` obligatorio (`INCOME` o `EXPENSE`).
- Ordenado por `total` descendente.
- `percent` sobre el total del `kind` en ese mes, 2 decimales; si el total es 0 → lista vacía
  (jamás dividas entre cero).
- Categorías archivadas **sí** aparecen si tuvieron movimiento en el periodo.

### `GET /reports/trend?months=6`

```json
[ { "yearMonth": "2026-02", "income": "17000.00", "expense": "11200.00", "net": "5800.00" } ]
```

- `months` entre 1 y 24 (default 6), terminando en el mes actual, orden cronológico ascendente.
- **Incluye los meses sin movimiento con ceros.** Si el frontend recibe huecos, la gráfica de barras
  miente sobre el eje temporal. Genera la serie de meses en Java o con `generate_series` en SQL.

### `GET /reports/export?from=2026-01-01&to=2026-07-31`

- `Content-Type: text/csv; charset=UTF-8`
- `Content-Disposition: attachment; filename="fintrack_2026-01-01_2026-07-31.csv"`
- **BOM UTF-8 al inicio** para que Excel en Windows no destroce los acentos.
- Encabezados: `fecha,tipo,categoria,cuenta,cuenta_destino,monto,nota`
- Separador `,`; campos con comas o comillas entrecomillados y con `"` escapado como `""`.
- Montos con punto decimal y sin símbolo de moneda (`1234.50`).
- Rango obligatorio; máximo 2 años → 400 si se excede.
- Streaming (`StreamingResponseBody`) si el rango puede traer muchas filas; no cargues todo en memoria.

**Reglas comunes**
- Todo filtrado por `user_id` del token (RB-05).
- Todas las agregaciones en **una query SQL** por endpoint; no traigas filas a Java para sumarlas.
- `BigDecimal` con `HALF_UP` para porcentajes.
- Usa el rango de fechas (`date >= :from AND date < :to`) en vez de `to_char` para aprovechar el índice.

**Aceptación**
- [ ] `summary` de un mes con 1 ingreso (1000), 1 gasto (400) y 1 transferencia (500):
      `totalIncome = 1000`, `totalExpense = 400`, `net = 600`.
- [ ] La suma de `byAccount[].income` es igual a `totalIncome`.
- [ ] `by-category` con totales que suman 100.00% (±0.01 por redondeo).
- [ ] Mes sin movimientos → `by-category` devuelve `[]`, no error.
- [ ] `trend?months=6` devuelve **6** elementos incluso si hay meses vacíos.
- [ ] `months=100` → 400.
- [ ] El CSV se abre en Excel y en Numbers con acentos correctos y una nota con coma bien encapsulada.
- [ ] Cada endpoint ejecuta 1 sola query de agregación (`show-sql`).

---

## F5.2 — Flutter: dashboard (§5.2.2)

> **Modelo: 🟢 Haiku.** Composición de widgets que ya existen, con datos de endpoints ya probados.
> El grueso del trabajo es layout.
> **Excepción 🔵 Sonnet:** el patrón de carga en paralelo con **fallo parcial** — tres peticiones con
> `Future.wait`, y si una falla, esa sección muestra su error mientras las otras dos se pintan
> normalmente. Es el punto donde el interceptor de F1.4.a recibe varios 401 simultáneos, así que
> aquí se comprueba de verdad si aquel refresh compartido quedó bien.

**Archivos**

```
app/lib/features/dashboard/
├── data/{models/summary_model.dart, dashboard_api.dart}
├── providers/dashboard_provider.dart
└── presentation/
    ├── dashboard_screen.dart
    └── widgets/{balance_card.dart, month_summary_row.dart,
                 top_budgets_section.dart, recent_transactions_section.dart}
```

**Ruta:** `/dashboard` (tab inicial del shell).

**Composición, de arriba a abajo**
1. Saludo ("Hola, {nombre}") + mes actual.
2. **Tarjeta de balance total** — suma de `currentBalance` de todas las cuentas activas, en grande.
3. **Resumen del mes** — tres columnas: Ingresos (verde ↑), Gastos (rojo ↓), Neto.
4. **Top 3 presupuestos más consumidos** — reutiliza `budget_progress_bar` de F4.2. "Ver todos" → `/budgets`.
5. **Últimas 5 transacciones** — reutiliza `transaction_tile` de F3.4. "Ver todas" → `/transactions`.
6. **FAB "+"** → `/transactions/new`.

**Reglas**
- El dashboard hace **peticiones en paralelo** (`Future.wait`) a summary, budgets y transactions
  (`size=5`); no encadenadas.
- Cada sección tiene su propio skeleton; si una falla, las demás se muestran igual (fallo parcial,
  no pantalla de error completa).
- Pull-to-refresh invalida los tres providers.
- Al volver de crear una transacción, el dashboard ya está actualizado (invalidación desde F3.3).
- Reutiliza widgets existentes; **no** dupliques `transaction_tile` ni la barra de progreso.

**Aceptación**
- [ ] Los números del dashboard coinciden con `/reports/summary` y con la pantalla de presupuestos.
- [ ] Crear un gasto y volver actualiza balance, resumen y últimas transacciones sin reiniciar la app.
- [ ] Si `/budgets` falla, el resto del dashboard sigue funcionando.
- [ ] Usuario nuevo sin datos ve un onboarding ("Crea tu primera cuenta"), no ceros y secciones vacías.
- [ ] Se ve bien en claro y en oscuro.

---

## F5.3 — Flutter: reportes con fl_chart y export CSV (§5.2.6)

> **Modelo: 🟡 Mixto.**
> - 🔵 **Sonnet:** `category_donut_chart` y `trend_bar_chart`. La API de `fl_chart` es densa
>   (`sections`, `titlesData`, `barTouchData`) y encima hay que agrupar en "Otros" a partir de 8
>   categorías y mantener la legibilidad en tema oscuro.
> - 🟢 **Haiku:** `category_legend`, el selector de rango y `export_button` (descarga con
>   `ResponseType.bytes` + `path_provider` + `share_plus`, que es una secuencia mecánica).

**Archivos**

```
app/lib/features/reports/
├── data/{models/{by_category_model.dart, trend_model.dart}, reports_api.dart}
├── providers/reports_provider.dart
└── presentation/
    ├── reports_screen.dart
    └── widgets/{category_donut_chart.dart, trend_bar_chart.dart,
                 category_legend.dart, export_button.dart}
```

**Ruta:** `/reports` (tab del shell).

**Contenido**
1. Selector de mes (reutiliza `month_selector` de F4.2) + toggle Gastos/Ingresos.
2. **Dona por categoría** (`PieChart` de `fl_chart` con `centerSpaceRadius`):
   - Colores tomados del `color` de cada categoría del backend.
   - En el centro: total del periodo.
   - Tocar un sector lo resalta y muestra nombre + monto + porcentaje.
   - Si hay más de 8 categorías, agrupa el resto en "Otros" (una dona con 20 sectores es ilegible).
3. **Leyenda** debajo: lista con punto de color, nombre, monto y porcentaje.
4. **Barras de tendencia 6 meses** (`BarChart`): ingresos y gastos agrupados por mes, eje X con
   `ene`, `feb`…; tooltip al tocar. Selector 3/6/12 meses.
5. **Botón "Exportar CSV"**: abre un selector de rango (default: año en curso), descarga vía Dio con
   `ResponseType.bytes`, guarda con `path_provider` y ofrece compartir con `share_plus`.
   Muestra progreso y confirma con la ruta del archivo.

**Reglas de gráficas**
- Nada de valores hardcodeados: todo viene del backend.
- Sin datos → mensaje "No hay movimientos en este periodo", no una gráfica vacía.
- Etiquetas de montos abreviadas en los ejes (`$12.3k`) pero completas en los tooltips.
- Respeta el tema: en modo oscuro, ejes y etiquetas legibles.
- Las gráficas son widgets tontos: reciben datos ya calculados, no llaman a la API.

**Aceptación**
- [ ] La dona muestra los mismos porcentajes que `/reports/by-category`.
- [ ] Cambiar de mes o de `kind` recarga ambas gráficas.
- [ ] La tendencia muestra los 6 meses, incluidos los vacíos.
- [ ] El CSV descargado se abre correctamente y su contenido coincide con la lista de transacciones
      del mismo rango.
- [ ] Un periodo sin datos muestra el estado vacío en lugar de una gráfica en blanco.
- [ ] Legible en claro y oscuro; `flutter analyze` limpio.

---

## Prompt sugerido

Antes de lanzarlo, cambia al modelo que indica la anotación de esa tarea. En F5.2, pásale a Haiku la
lista literal de widgets que debe reutilizar.

> Lee `plans/08-DASHBOARD-Y-REPORTES.md` y `plans/00-INDICE-Y-CONVENCIONES.md`. Implementa **solo F5.X**.
> En backend, cada endpoint de reportes debe resolverse con una sola query de agregación y excluir
> transferencias (RB-03). En Flutter, reutiliza los widgets ya creados en fases anteriores. Verifica
> los criterios de aceptación con al menos 6 meses de datos sembrados.

## Cierre de fase

- [ ] Los tres checklists completos.
- [ ] Los mismos números aparecen consistentes en dashboard, presupuestos, reportes y lista de
      transacciones. **Cualquier discrepancia es un bug, no un redondeo.**
- [ ] Commit/tag `fase-5-reportes`.

**Siguiente:** [`09-CALIDAD.md`](09-CALIDAD.md).
