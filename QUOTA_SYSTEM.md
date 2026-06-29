# Sistema de Cupos de Productores

## Contexto y motivación

La certificadora orgánica exige que cada productor no exceda una cuota máxima de **kg de panela certificada** por año calendario. El incumplimiento pone en riesgo la certificación de la cooperativa.

El cupo es por **productor × certificación × año**. Un productor puede estar en múltiples módulos, y cada combinación productor-módulo tiene su propio cupo independiente (un productor puede agotar su cupo en el Módulo A y aún tener disponible en el Módulo B).

Este sistema implementa una **alerta visible** en el formulario de registro de producción cuando un productor está próximo a agotar o ya superó su cupo. No bloquea el registro (arquitectura preparada para bloqueo futuro), pero obliga al técnico a confirmar.

---

## Arquitectura general

```
Supabase (BD)
  ├── producer_quotas                  ← cupos por productor/cert/año
  ├── production_modification_requests ← solicitudes de modificación de lotes
  └── get_producer_quota_statuses()    ← RPC que calcula el acumulado

Flutter (app móvil)
  ├── models/producer_quota_status.dart    ← modelo + QuotaCheckResult
  ├── services/producer_quota_service.dart ← llama al RPC
  └── widgets/production/producer_selection_step.dart ← banner + dialog
```

La lógica de cálculo **vive exclusivamente en el RPC de Supabase**, no en el cliente.

---

## Base de datos

### Tabla: `producer_quotas`

```sql
producer_quotas
├── id               uuid PK
├── producer_id      FK → producers (CASCADE delete)
├── batch_cert_id    FK → batch_certs (RESTRICT delete)
├── cooperative_id   FK → cooperatives (CASCADE delete)
├── coop_module_id   FK → coop_modules (RESTRICT delete)  ← snapshot del módulo
├── year             integer NOT NULL                       ← año calendario (ene-dic)
├── cupo_kg          numeric(10,2) NOT NULL  CHECK > 0
├── notes            text
├── created_by       varchar(8)              (DNI — auditoría)
├── created_at       timestamptz
└── updated_at       timestamptz (auto via trigger)

UNIQUE (producer_id, batch_cert_id, year)
```

**Decisiones de diseño:**

| Decisión | Motivo |
|---|---|
| Tabla independiente, no columna en `producers` | Un productor tiene múltiples cupos: distintas certificaciones y/o módulos |
| `year` integer (no `period_start/period_end`) | El cupo es siempre enero–diciembre según requerimiento |
| `batch_cert_id` como FK | El cupo aplica por certificación específica |
| `coop_module_id` como snapshot | Preserva el módulo del productor al momento del cupo — si cambia de módulo el histórico no se altera (trazabilidad BRC/HACCP) |
| `producer_id` implica módulo | Cada registro de productor pertenece a un módulo; "Guadalupe en Módulo A" y "Guadalupe en Módulo B" son `producer_id` distintos |
| `UNIQUE (producer_id, batch_cert_id, year)` | Un cupo por productor × certificación × año |

### Tabla: `production_modification_requests`

```sql
production_modification_requests
├── id                    uuid PK
├── production_batch_id   FK → production_batches (RESTRICT)
├── cooperative_id        FK → cooperatives (CASCADE)
├── requested_by          varchar(8)    ← DNI del técnico de campo
├── requested_at          timestamptz
├── field_changes         jsonb         ← [{field, old_value, new_value}]
├── motivo                text NOT NULL
├── status                varchar(12)   CHECK IN ('pendiente','aprobado','rechazado')
├── reviewed_by           varchar(8)    ← DNI del usuario de planta aprobador
├── reviewed_at           timestamptz
├── review_notes          text
├── created_at, updated_at

EXCLUDE USING btree (production_batch_id WITH =) WHERE (status = 'pendiente')
```

**Flujo:**
1. Técnico detecta error → crea solicitud desde app móvil (status = `pendiente`)
2. Usuario de planta (rol aprobador, ej. Lenin Román) revisa desde app web
3. Si aprueba: se aplican los cambios al lote original, status → `aprobado`
4. Si rechaza: el lote queda intacto, status → `rechazado`

El `EXCLUDE` garantiza que no haya dos solicitudes pendientes para el mismo lote.

### RLS

Mismo patrón del proyecto: `cooperative_id = auth_cooperative_id() OR is_service_role()`.

- `producer_quotas`: SELECT para todos los autenticados de la cooperativa; INSERT/UPDATE/DELETE misma política (escritura desde web cuando esté lista).
- `production_modification_requests`: SELECT/INSERT/UPDATE para autenticados; DELETE solo service_role (historial inmutable).

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
  year, notes
)
```

El año se extrae server-side: `EXTRACT(YEAR FROM p_process_date)`. Flutter no necesita calcular el año.

**Cómo calcula el acumulado:**

```
production_batches (del productor, process_date en el mismo año)
  JOIN production_batch_certs (filtrado por batch_cert_id del cupo)
  SUM(panela_kg)  ← solo panela, NO confitillo
```

Si un lote tiene 2 certificaciones, su `panela_kg` suma al cupo de **cada una por separado**.

**Seguridad:** `SECURITY INVOKER` — las políticas RLS de todas las tablas siguen aplicando.

**Retorna vacío** si el productor no tiene cupos para ese año → la app interpreta como "sin restricción".

---

## Flutter

### Modelo: `ProducerQuotaStatus` + `QuotaCheckResult`

- `ProducerQuotaStatus` — mapea una fila del RPC (incluye `year int`).
- `QuotaStatusLevel` (enum) — `ok / warning / exceeded`. Calculado como propiedad derivada.
  - `ok`: < 80% consumido
  - `warning`: 80–99% consumido
  - `exceeded`: superado = true
- `QuotaCheckResult` — lista de cupos + flag `isOffline`. Propiedades: `hasQuotas`, `hasWarning`, `hasExceeded`, `allOk`.

### UI del formulario

**Dónde:** Step 0 — `ProducerSelectionStep`, al seleccionar productor + parcela.

| Estado | UI |
|---|---|
| Cargando | Spinner + "Verificando cupo..." |
| Sin conexión | Chip gris informativo |
| Sin cupos configurados | Nada |
| OK (< 80%) | Banner verde con kg disponibles |
| Warning (80–99%) | Banner amarillo con barra de progreso |
| Excedido | Banner rojo + dialog modal (técnico puede continuar) |

**Alert vs block:** hoy es alerta. Cambiar a bloqueo = agregar `if (quotaResult.hasExceeded) return;` en `_handleContinue()` del screen. Sin cambios en schema.

---

## Migraciones

| Archivo | Contenido |
|---|---|
| `20260626100000_create_producer_quotas.sql` | Tabla, RLS, índices, trigger |
| `20260626110000_create_producer_quota_rpc.sql` | Grants + RPC original |
| `20260629100000_restructure_producer_quotas.sql` | Agrega `coop_module_id` y `year`; elimina `period_start/period_end`; actualiza UNIQUE |
| `20260629110000_update_producer_quota_rpc.sql` | RPC actualizado para usar `year` |
| `20260629120000_create_production_modification_requests.sql` | Tabla de solicitudes de modificación |

---

## Queries operacionales — Carga masiva de cupos

> Ejecutar desde el SQL Editor de Supabase. Reemplaza los valores entre `< >`.

### 0. Inspección previa

```sql
SELECT
  c.name                             AS cooperativa,
  cm.name                            AS modulo,
  p.id                               AS producer_id,
  p.first_name || ' ' || p.last_name AS productor,
  p.dni,
  bc.id                              AS batch_cert_id,
  bc.name                            AS certificacion
FROM producers p
JOIN cooperatives c  ON c.id  = p.cooperative_id
JOIN coop_modules cm ON cm.id = p.coop_module_id
JOIN batch_certs  bc ON bc.cooperative_id = p.cooperative_id
WHERE p.is_active = true AND bc.is_active = true
ORDER BY c.name, cm.name, p.last_name, bc.name;
```

### 1. Cupo único para todos los productores de un módulo

```sql
INSERT INTO producer_quotas
  (producer_id, batch_cert_id, cooperative_id, coop_module_id, cupo_kg, year, notes)
SELECT
  p.id,
  '<batch_cert_id>',
  p.cooperative_id,
  p.coop_module_id,
  <cupo_kg>,           -- ej: 5000.00
  <year>,              -- ej: 2026
  '<notas>'            -- ej: 'Orgánica 2026 - Módulo X'
FROM producers p
WHERE p.coop_module_id = '<module_id>'
  AND p.is_active = true
ON CONFLICT (producer_id, batch_cert_id, year) DO NOTHING;
```

### 2. Cupo para toda la cooperativa — todas sus certificaciones

```sql
INSERT INTO producer_quotas
  (producer_id, batch_cert_id, cooperative_id, coop_module_id, cupo_kg, year, notes)
SELECT
  p.id,
  bc.id,
  p.cooperative_id,
  p.coop_module_id,
  <cupo_kg>,
  <year>,
  '<notas>'
FROM producers p
JOIN batch_certs bc ON bc.cooperative_id = p.cooperative_id
WHERE p.cooperative_id = '<cooperative_id>'
  AND p.is_active  = true
  AND bc.is_active = true
ON CONFLICT (producer_id, batch_cert_id, year) DO NOTHING;
```

### 3. Cupos distintos por módulo

```sql
-- Módulo 1
INSERT INTO producer_quotas (producer_id, batch_cert_id, cooperative_id, coop_module_id, cupo_kg, year, notes)
SELECT p.id, '<batch_cert_id>', p.cooperative_id, p.coop_module_id, <cupo_modulo_1>, <year>, 'Orgánica <year> - Módulo 1'
FROM producers p WHERE p.coop_module_id = '<module_id_1>' AND p.is_active = true
ON CONFLICT (producer_id, batch_cert_id, year) DO NOTHING;

-- Módulo 2
INSERT INTO producer_quotas (producer_id, batch_cert_id, cooperative_id, coop_module_id, cupo_kg, year, notes)
SELECT p.id, '<batch_cert_id>', p.cooperative_id, p.coop_module_id, <cupo_modulo_2>, <year>, 'Orgánica <year> - Módulo 2'
FROM producers p WHERE p.coop_module_id = '<module_id_2>' AND p.is_active = true
ON CONFLICT (producer_id, batch_cert_id, year) DO NOTHING;
```

### 4. Ajustar cupo individual

```sql
INSERT INTO producer_quotas (producer_id, batch_cert_id, cooperative_id, coop_module_id, cupo_kg, year, notes)
SELECT p.id, '<batch_cert_id>', p.cooperative_id, p.coop_module_id, <cupo_kg>, <year>, '<motivo>'
FROM producers p WHERE p.id = '<producer_id>'
ON CONFLICT (producer_id, batch_cert_id, year)
DO UPDATE SET cupo_kg = EXCLUDED.cupo_kg, notes = EXCLUDED.notes, updated_at = now();
```

### 5. Verificación post-carga

```sql
-- Productores activos SIN cupo para el año
SELECT
  c.name AS cooperativa, cm.name AS modulo,
  p.first_name || ' ' || p.last_name AS productor, p.dni
FROM producers p
JOIN cooperatives c  ON c.id  = p.cooperative_id
JOIN coop_modules cm ON cm.id = p.coop_module_id
WHERE p.is_active = true
  AND NOT EXISTS (
    SELECT 1 FROM producer_quotas pq
    WHERE pq.producer_id = p.id AND pq.year = <year>
  )
ORDER BY c.name, cm.name, p.last_name;

-- Resumen por módulo
SELECT
  c.name AS cooperativa, cm.name AS modulo, bc.name AS certificacion,
  COUNT(pq.id) AS con_cupo,
  AVG(pq.cupo_kg)::numeric(10,2) AS cupo_promedio_kg,
  SUM(pq.cupo_kg)::numeric(10,2) AS cupo_total_kg
FROM producer_quotas pq
JOIN producers    p  ON p.id  = pq.producer_id
JOIN cooperatives c  ON c.id  = pq.cooperative_id
JOIN coop_modules cm ON cm.id = pq.coop_module_id
JOIN batch_certs  bc ON bc.id = pq.batch_cert_id
WHERE pq.year = <year>
GROUP BY c.name, cm.name, bc.name
ORDER BY c.name, cm.name, bc.name;
```

### 6. Nuevo año — copiar cupos del año anterior

```sql
INSERT INTO producer_quotas
  (producer_id, batch_cert_id, cooperative_id, coop_module_id, cupo_kg, year, notes)
SELECT
  producer_id, batch_cert_id, cooperative_id, coop_module_id,
  cupo_kg,
  <new_year>,
  'Cupo ' || <new_year> || ' — copiado de ' || year
FROM producer_quotas
WHERE year = <old_year>
  AND cooperative_id = '<cooperative_id>'
ON CONFLICT (producer_id, batch_cert_id, year) DO NOTHING;
```

---

## Escalabilidad futura

| Escenario | Cómo lo soporta este diseño |
|---|---|
| Web app gestiona cupos | CRUD estándar sobre `producer_quotas`, sin cambios en RPC |
| Nueva certificadora | Nuevo `batch_cert` + nuevas filas en `producer_quotas` |
| Bloquear en lugar de alertar | Una línea en Flutter — sin cambio en schema |
| Reportes de cumplimiento | RPC reutilizable con cualquier fecha |
| Aprobación de modificaciones web | `production_modification_requests` ya diseñada para eso |
