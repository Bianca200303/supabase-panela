# Sistema de Cupos de Productores

## Contexto y motivación

La certificadora orgánica exige que cada productor no exceda una cuota máxima de **kg de panela certificada** por campaña productiva. El incumplimiento pone en riesgo la certificación de la cooperativa.

Este sistema implementa una **alerta visible** en el formulario de registro de producción cuando un productor está próximo a agotar o ya superó su cupo. No bloquea el registro (el técnico puede continuar de todas formas), pero deja evidencia clara de la situación.

---

## Arquitectura general

```
Supabase (BD)
  ├── producer_quotas         ← tabla nueva (cupos por productor/cert/campaña)
  └── get_producer_quota_statuses()  ← RPC que calcula el acumulado

Flutter (app móvil)
  ├── models/producer_quota_status.dart   ← modelo + QuotaCheckResult
  ├── services/producer_quota_service.dart ← llama al RPC
  └── widgets/production/producer_selection_step.dart ← banner + dialog
```

La lógica de cálculo **vive exclusivamente en el RPC de Supabase**, no en el cliente. Tanto la app móvil como la futura app web consumen el mismo contrato.

---

## Base de datos

### Tabla: `producer_quotas`

```sql
producer_quotas
├── id               uuid PK
├── producer_id      FK → producers (CASCADE delete)
├── batch_cert_id    FK → batch_certs (RESTRICT delete)
├── cooperative_id   FK → cooperatives (CASCADE delete)
├── cupo_kg          numeric(10,2) NOT NULL  CHECK > 0
├── period_start     date NOT NULL
├── period_end       date NOT NULL            CHECK > period_start
├── notes            text                     (ej. "Campaña 1 - 2026")
├── created_by       varchar(8)               (DNI — auditoría)
├── created_at       timestamptz
└── updated_at       timestamptz (auto via trigger)

UNIQUE (producer_id, batch_cert_id, period_start)
```

**Decisiones de diseño importantes:**

| Decisión | Motivo |
|---|---|
| Tabla independiente, no columna en `producers` | Un productor puede tener múltiples cupos: distintas certificaciones y/o 1-2 campañas por año |
| `period_start / period_end` en lugar de año | Las campañas tienen fechas irregulares, no siempre ene-dic |
| `batch_cert_id` como FK | El cupo aplica por certificación específica, no a toda la panela |
| `ON DELETE RESTRICT` en `batch_certs` | No se puede eliminar una certificación que tiene cupos activos |
| `UNIQUE (producer_id, batch_cert_id, period_start)` | Evita duplicar el mismo cupo; permite períodos consecutivos |

### RLS

Mismo patrón del proyecto: `cooperative_id = auth_cooperative_id() OR is_service_role()`.

- **SELECT**: cualquier usuario autenticado de la cooperativa (la app móvil necesita leer).
- **INSERT/UPDATE/DELETE**: misma política base por ahora. Se puede estrechar a roles web cuando la autenticación de la app web esté implementada.

### Índices

```sql
idx_producer_quotas_producer_period  → (producer_id, period_start, period_end)
idx_producer_quotas_batch_cert       → (batch_cert_id)
idx_producer_quotas_cooperative      → (cooperative_id)
```

---

## RPC: `get_producer_quota_statuses`

```sql
get_producer_quota_statuses(
  p_producer_id  uuid,
  p_process_date date  DEFAULT CURRENT_DATE
)
RETURNS TABLE (
  quota_id, cert_name, cupo_kg, acumulado_kg,
  disponible_kg, porcentaje_usado, superado,
  period_start, period_end, notes
)
```

**Cómo calcula el acumulado:**

```
production_batches (del productor, process_date en el período)
  JOIN production_batch_certs (filtrado por batch_cert_id del cupo)
  SUM(panela_kg)           ← solo panela, NO confitillo
```

Si un lote tiene 2 certificaciones, su `panela_kg` suma al cupo de **cada una por separado**.

**Por qué `p_process_date` y no `CURRENT_DATE` fijo:**
El cupo que aplica es el del período del lote que se va a registrar, no necesariamente hoy. Ejemplo: si el técnico registra producción con fecha de hace 3 días y ese día pertenecía a otra campaña, el cupo correcto es el de esa campaña.

**Seguridad:** `SECURITY INVOKER` — corre con los permisos del usuario que llama, así las políticas RLS de todas las tablas siguen aplicando.

**Retorna vacío** si el productor no tiene cupos configurados para esa fecha → la app interpreta esto como "sin restricción".

---

## Flutter

### Modelo: `ProducerQuotaStatus` + `QuotaCheckResult`

```
lib/models/producer_quota_status.dart
```

- `ProducerQuotaStatus` — mapea una fila del RPC.
- `QuotaStatusLevel` (enum) — `ok / warning / exceeded`. Calculado como propiedad derivada del modelo; la UI nunca compara números.
  - `ok`: < 80% consumido
  - `warning`: 80–99% consumido
  - `exceeded`: superado = true
- `QuotaCheckResult` — encapsula la lista de cupos + flag `isOffline`. La UI solo lee este objeto:
  - `hasQuotas`, `hasWarning`, `hasExceeded`, `allOk`
  - `QuotaCheckResult.offline` y `QuotaCheckResult.empty` como constantes estáticas.

### Servicio: `ProducerQuotaService`

```
lib/services/producer_quota_service.dart
```

- Llama al RPC `get_producer_quota_statuses`.
- **Sin cache local (Drift)** — el acumulado cambia con cada registro y debe ser siempre fresco.
- Sin conexión → retorna `QuotaCheckResult.offline`.
- Error inesperado → retorna `QuotaCheckResult.empty` (no bloquea al técnico).

### Flujo en el formulario de registro

**Dónde:** Step 0 — `ProducerSelectionStep`, al seleccionar productor + parcela.

**Cuándo se dispara la consulta:** en `_loadSelectedProducerAndPlot()` del screen, que ya existía para cargar % de extracción/cachaza. Se llama `_checkProducerQuota()` al final de ese método.

**Reset:** `_onPlotChanged()` resetea `_quotaResult = null` ante cualquier cambio de productor o parcela.

**Qué muestra el banner según el resultado:**

| Estado | UI |
|---|---|
| Cargando | Spinner + "Verificando cupo..." |
| Sin conexión | Chip gris informativo |
| Sin cupos configurados | Nada — sin alerta |
| OK (< 80%) | Banner verde con kg disponibles por cert |
| Warning (80–99%) | Banner amarillo con barra de progreso |
| Excedido (≥ 100%) | Banner rojo + **dialog modal** que requiere confirmación |

El banner muestra una fila por cada certificación con cupo configurado, con barra de progreso visual.

El **dialog de excedido** no bloquea — el técnico puede "Continuar de todas formas" — pero obliga a leer y confirmar. El sistema evita mostrar el mismo dialog dos veces para el mismo conjunto de cupos excedidos (tracking por `quota_id`).

---

## Gestión de cupos (quién puede crear/editar)

**Hoy:** manual vía SQL Editor de Supabase (solo el equipo técnico).

**Próximamente:** desde la app web (usuarios de planta). La tabla está diseñada para soportar CRUD estándar sin cambios en el esquema.

**No desde la app móvil:** los técnicos de campo y admins de módulo solo leen cupos, no los crean.

---

## Migraciones relacionadas

| Archivo | Contenido |
|---|---|
| `20260626100000_create_producer_quotas.sql` | Tabla, RLS, índices, trigger `updated_at` |
| `20260626110000_create_producer_quota_rpc.sql` | Grants de tabla + RPC `get_producer_quota_statuses` |

---

## Queries operacionales — Carga masiva de cupos

Estas consultas se ejecutan desde el **SQL Editor de Supabase** por el equipo técnico
al inicio de cada campaña. No requieren cambios en la app.

> **Convención:** reemplaza los valores entre `< >` antes de ejecutar.

---

### 0. Inspección previa — ver productores y certificaciones disponibles

Antes de insertar cupos, verifica qué productores y certificaciones existen por cooperativa y módulo:

```sql
SELECT
  c.name                                    AS cooperativa,
  cm.name                                   AS modulo,
  p.id                                      AS producer_id,
  p.first_name || ' ' || p.last_name        AS productor,
  p.dni,
  bc.id                                     AS batch_cert_id,
  bc.name                                   AS certificacion,
  p.cooperative_id
FROM producers p
JOIN cooperatives  c  ON c.id  = p.cooperative_id
JOIN coop_modules  cm ON cm.id = p.coop_module_id
JOIN batch_certs   bc ON bc.cooperative_id = p.cooperative_id
WHERE p.is_active  = true
  AND bc.is_active = true
ORDER BY c.name, cm.name, p.last_name, bc.name;
```

---

### 1. Insertar cupo único para todos los productores de un módulo

Todos los productores del módulo reciben el mismo cupo para una certificación específica.

```sql
INSERT INTO producer_quotas
  (producer_id, batch_cert_id, cooperative_id, cupo_kg, period_start, period_end, notes)
SELECT
  p.id,
  '<batch_cert_id>',          -- UUID de la certificación (de la query 0)
  p.cooperative_id,
  <cupo_kg>,                  -- ej: 1200.00
  '<period_start>',           -- ej: '2026-01-01'
  '<period_end>',             -- ej: '2026-12-31'
  '<notas>'                   -- ej: 'Campaña 2026 - Orgánica'
FROM producers p
WHERE p.coop_module_id = '<module_id>'
  AND p.is_active = true
ON CONFLICT (producer_id, batch_cert_id, period_start) DO NOTHING;
```

---

### 2. Insertar cupo para todos los productores de una cooperativa — todas sus certificaciones

Inserta el mismo cupo para CADA combinación productor × certificación dentro de la cooperativa.

```sql
INSERT INTO producer_quotas
  (producer_id, batch_cert_id, cooperative_id, cupo_kg, period_start, period_end, notes)
SELECT
  p.id,
  bc.id,
  p.cooperative_id,
  <cupo_kg>,
  '<period_start>',
  '<period_end>',
  '<notas>'
FROM producers p
JOIN batch_certs bc ON bc.cooperative_id = p.cooperative_id
WHERE p.cooperative_id = '<cooperative_id>'
  AND p.is_active  = true
  AND bc.is_active = true
ON CONFLICT (producer_id, batch_cert_id, period_start) DO NOTHING;
```

> **Nota:** `ON CONFLICT DO NOTHING` protege ante doble ejecución accidental.
> Si necesitas sobreescribir usa `DO UPDATE SET cupo_kg = EXCLUDED.cupo_kg`.

---

### 3. Insertar cupos diferenciados por módulo (cupos distintos por módulo)

Cuando cada módulo tiene un cupo diferente, ejecutar por módulo:

```sql
-- Módulo 1
INSERT INTO producer_quotas (producer_id, batch_cert_id, cooperative_id, cupo_kg, period_start, period_end, notes)
SELECT p.id, '<batch_cert_id>', p.cooperative_id, <cupo_modulo_1>, '<period_start>', '<period_end>', 'Campaña 2026 - Módulo 1'
FROM producers p WHERE p.coop_module_id = '<module_id_1>' AND p.is_active = true
ON CONFLICT (producer_id, batch_cert_id, period_start) DO NOTHING;

-- Módulo 2
INSERT INTO producer_quotas (producer_id, batch_cert_id, cooperative_id, cupo_kg, period_start, period_end, notes)
SELECT p.id, '<batch_cert_id>', p.cooperative_id, <cupo_modulo_2>, '<period_start>', '<period_end>', 'Campaña 2026 - Módulo 2'
FROM producers p WHERE p.coop_module_id = '<module_id_2>' AND p.is_active = true
ON CONFLICT (producer_id, batch_cert_id, period_start) DO NOTHING;
```

---

### 4. Ajustar cupo a un productor específico (excepción individual)

Después de la carga masiva, corregir casos puntuales:

```sql
INSERT INTO producer_quotas (producer_id, batch_cert_id, cooperative_id, cupo_kg, period_start, period_end, notes)
VALUES ('<producer_id>', '<batch_cert_id>', '<cooperative_id>', <cupo_kg>, '<period_start>', '<period_end>', '<motivo>')
ON CONFLICT (producer_id, batch_cert_id, period_start)
DO UPDATE SET cupo_kg = EXCLUDED.cupo_kg, notes = EXCLUDED.notes, updated_at = now();
```

---

### 5. Verificación post-carga

Confirmar que todos los productores activos tienen cupo para la campaña:

```sql
-- Productores activos SIN cupo para un período dado
SELECT
  c.name AS cooperativa,
  cm.name AS modulo,
  p.first_name || ' ' || p.last_name AS productor,
  p.dni
FROM producers p
JOIN cooperatives c  ON c.id  = p.cooperative_id
JOIN coop_modules cm ON cm.id = p.coop_module_id
WHERE p.is_active = true
  AND NOT EXISTS (
    SELECT 1 FROM producer_quotas pq
    WHERE pq.producer_id = p.id
      AND '<fecha_campaña>'::date BETWEEN pq.period_start AND pq.period_end
  )
ORDER BY c.name, cm.name, p.last_name;

-- Resumen: cuántos productores tienen cupo por módulo
SELECT
  c.name  AS cooperativa,
  cm.name AS modulo,
  bc.name AS certificacion,
  COUNT(pq.id)              AS con_cupo,
  AVG(pq.cupo_kg)::numeric(10,2) AS cupo_promedio_kg,
  SUM(pq.cupo_kg)::numeric(10,2) AS cupo_total_kg
FROM producer_quotas pq
JOIN producers     p  ON p.id  = pq.producer_id
JOIN cooperatives  c  ON c.id  = pq.cooperative_id
JOIN coop_modules  cm ON cm.id = p.coop_module_id
JOIN batch_certs   bc ON bc.id = pq.batch_cert_id
WHERE '<fecha_campaña>'::date BETWEEN pq.period_start AND pq.period_end
GROUP BY c.name, cm.name, bc.name
ORDER BY c.name, cm.name, bc.name;
```

---

### 6. Nueva campaña — copiar cupos del período anterior

Al iniciar una nueva campaña, partir de los cupos del período anterior como base:

```sql
INSERT INTO producer_quotas
  (producer_id, batch_cert_id, cooperative_id, cupo_kg, period_start, period_end, notes)
SELECT
  producer_id,
  batch_cert_id,
  cooperative_id,
  cupo_kg,                          -- mantiene el mismo cupo; ajusta si es necesario
  '<new_period_start>',
  '<new_period_end>',
  'Campaña <año> — copiado de campaña anterior'
FROM producer_quotas
WHERE period_start = '<old_period_start>'
  AND cooperative_id = '<cooperative_id>'   -- omitir para copiar todas las cooperativas
ON CONFLICT (producer_id, batch_cert_id, period_start) DO NOTHING;
```

---

## Escalabilidad futura

| Escenario | Cómo lo soporta este diseño |
|---|---|
| Web app gestiona cupos | CRUD estándar sobre `producer_quotas`, sin cambios en RPC |
| 2 campañas al año | Agregar más filas con distintos `period_start/end` |
| Nueva certificadora | Nuevo `batch_cert` + nuevas filas en `producer_quotas` |
| Reportes de cumplimiento | El RPC reutilizable con cualquier fecha |
| Cupo grupal por módulo (futuro) | Tabla análoga `module_quotas` sin tocar esta |
