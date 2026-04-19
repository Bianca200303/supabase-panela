# Mejoras al Flujo de Planta - Trazabilidad Campo a Exportacion

## Fecha: 2026-04-16

## Resumen de Cambios

Cambios **100% aditivos** al esquema. No se modificaron ni eliminaron tablas/columnas existentes.
La app web y movil existentes siguen funcionando sin cambios.

---

## Flujo Actualizado

```
CAMPO (Movil)                         PLANTA (Web)
------                                ------
production_batches
    |
exit_registrations + exit_items  -->  exit_receptions + exit_reception_items
                                           |
                                      quality_evaluations
                                        + approval_status (NUEVO)
                                           |
                                      v_plant_available_stock (NUEVA VISTA)
                                           |
                                      plant_orders
                                        + plant_order_checklists (NUEVO: limpieza, control_plagas)
                                           |
                                      plant_production_batches
                                        + plant_checklists (existente: manto_equipos, control_personal)
                                        + plant_homogenization_inputs
                                        + plant_batch_processing
                                           |
                                      v_plant_order_summary (NUEVA VISTA)
                                           |
                                      plant_containers (NUEVO)
                                           |
                                      plant_dispatches (NUEVO)
```

---

## Nuevas Tablas

### 1. `plant_containers`

Metadata del contenedor de exportacion. Relacion 1:1 con `plant_orders`.

| Columna | Tipo | Descripcion |
|---------|------|-------------|
| id | uuid (PK) | ID unico |
| order_id | uuid (FK, UNIQUE) | Orden de produccion asociada |
| container_number | varchar(20) | Numero del contenedor (ej: BLU-1234567) |
| seal_number | varchar(30) | Sello de seguridad |
| container_size | varchar(10) | Tamano: '20' o '40' (pies) |
| max_capacity_kg | numeric(10,3) | Capacidad maxima en kg |
| booking_number | varchar(50) | Reserva con la naviera |
| bill_of_lading | varchar(50) | Conocimiento de embarque (BL) |
| shipping_line | varchar(100) | Naviera |
| destination_port | varchar(100) | Puerto destino |
| departure_date | date | Fecha de salida |
| estimated_arrival | date | Fecha estimada de llegada |
| status | text | preparando / cargado / despachado / en_transito / entregado |
| notes | text | Observaciones |
| cooperative_id | uuid | Cooperativa |
| created_by | uuid | Usuario creador |

### 2. `plant_order_checklists`

Checklists a nivel de orden/jornada. Para `limpieza` y `control_plagas` que aplican a toda la planta, no a cada lote individual.

| Columna | Tipo | Descripcion |
|---------|------|-------------|
| id | uuid (PK) | ID unico |
| order_id | uuid (FK) | Orden asociada |
| type | text | 'limpieza' o 'control_plagas' |
| items | jsonb | Array de items [{key, label, complies, observation}] |
| general_notes | text | Notas generales |
| filled_by | uuid | Usuario que lleno el checklist |
| filled_at | timestamptz | Fecha/hora de llenado |
| cooperative_id | uuid | Cooperativa |

**UNIQUE:** (order_id, type) - maximo un checklist por tipo por orden.

**Nota:** Los `plant_checklists` existentes (por lote) siguen activos para `mantenimiento_equipos` y `control_personal`.

### 3. `plant_dispatches`

Registro de despacho/embarque vinculado a un contenedor.

| Columna | Tipo | Descripcion |
|---------|------|-------------|
| id | uuid (PK) | ID unico |
| container_id | uuid (FK) | Contenedor asociado |
| dispatch_date | date | Fecha de despacho |
| dispatch_code | text (UNIQUE) | Codigo unico de despacho |
| loaded_by | uuid | Supervisor de carga |
| verified_by | uuid | Verificador (opcional) |
| total_loaded_kg | numeric(10,3) | Peso total cargado |
| seal_verified | boolean | Sello verificado al cerrar |
| temperature_at_load | numeric(5,2) | Temperatura al cargar |
| humidity_at_load | numeric(5,2) | Humedad relativa al cargar |
| notes | text | Observaciones |
| cooperative_id | uuid | Cooperativa |

---

## Columnas Nuevas en Tablas Existentes

### `quality_evaluations` + approval_status, rejection_reason

| Columna | Tipo | Default | Descripcion |
|---------|------|---------|-------------|
| approval_status | varchar(30) | NULL | 'aprobado', 'rechazado', 'aprobado_con_observaciones' (NULL = pendiente) |
| rejection_reason | text | NULL | Motivo del rechazo |

**Impacto:** Ninguno. Columnas nullable. Las queries existentes no las seleccionan.

---

## Nuevas Vistas

### `v_plant_available_stock`

Consolida el stock disponible en planta por `exit_item`. Reemplaza la logica JavaScript de `buildUsedMap()` y `getAvailableKg()` en OrdenesPage.jsx.

**Columnas:**
- exit_item_id, production_batch_id, field_batch_code
- producer_name, module_name
- quantity_kg_received, kg_used, **kg_available**
- humidity_pct, impurities_pct, color, sack_condition, appearance
- approval_status
- cooperative_id

**Uso sugerido:**
```javascript
const { data } = await supabase
  .from('v_plant_available_stock')
  .select('*')
  .eq('cooperative_id', COOPERATIVE.id)
  .gt('kg_available', 0);
```

### `v_plant_order_summary`

Resumen consolidado por orden de produccion con datos de rendimiento y contenedor.

**Columnas:**
- order_id, order_code, market, planned_kg, status, planned_date
- total_batches, processed_batches
- total_tamizada_kg, total_descarte_kg, total_merma_kg
- total_homogenizado_kg, **rendimiento_pct**
- container_number, container_status, bill_of_lading, destination_port
- cooperative_id

**Uso sugerido:**
```javascript
const { data } = await supabase
  .from('v_plant_order_summary')
  .select('*')
  .eq('cooperative_id', COOPERATIVE.id)
  .order('planned_date', { ascending: false });
```

---

## Seguridad (RLS)

Las 3 tablas nuevas (`plant_containers`, `plant_order_checklists`, `plant_dispatches`) fueron agregadas al array `coop_tables` en `security.sql`. Reciben automaticamente las 4 politicas estandar:
- SELECT: `cooperative_id = auth_cooperative_id() OR is_service_role()`
- INSERT: WITH CHECK mismo criterio
- UPDATE: USING + WITH CHECK mismo criterio
- DELETE: USING mismo criterio

Las vistas heredan el RLS de las tablas subyacentes.

---

## Guia de Migracion Frontend

### Fase 1: Sin cambios (actual)
La web funciona exactamente igual. Las nuevas tablas y vistas existen pero no se consultan.

### Fase 2: Adoptar vistas
- Reemplazar `buildUsedMap()` / `getAvailableKg()` en OrdenesPage por query a `v_plant_available_stock`
- Usar `v_plant_order_summary` en ReportesPage para metricas consolidadas

### Fase 3: Agregar aprobacion de calidad
- En CalidadPage: mostrar botones Aprobar/Rechazar despues de evaluar
- En OrdenesPage: filtrar stock disponible por `approval_status = 'aprobado'` o `approval_status = 'aprobado_con_observaciones'`

### Fase 4: Contenedores y despacho
- En OrdenesPage: agregar seccion para registrar datos de contenedor
- Nueva pagina o seccion DespachoPage para registro de embarque

### Fase 5: Optimizar checklists
- Mover `limpieza` y `control_plagas` a `plant_order_checklists` (por orden)
- Mantener `mantenimiento_equipos` y `control_personal` en `plant_checklists` (por lote)

---

## Archivos Modificados

| Archivo | Cambios |
|---------|---------|
| seed.sql | +3 tablas, +2 vistas, +1 ALTER TABLE, +PKs, +FKs, +GRANTs |
| security.sql | +3 tablas en array coop_tables para RLS |
