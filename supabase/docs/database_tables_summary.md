# Resumen de Tablas de Base de Datos - Proyecto Panela

## Fecha: 2026-04-17

---

## Tablas compartidas (App Movil + Web) — 28 tablas

| Tabla | Que registra |
|-------|-------------|
| `cooperatives` | Cooperativas (Norandino, CAES) |
| `coop_modules` | Modulos de trabajo dentro de cada cooperativa |
| `users` | Usuarios movil/campo (productor, tecnico, admin) |
| `user_module_assignments` | Asignacion de usuarios a modulos |
| `producers` | Productores de cana registrados |
| `plots` | Parcelas agricolas de cada productor |
| `production_batches` | Lotes de produccion (cana, jugo, panela, confitillo) |
| `batch_certs` | Certificados disponibles (Organica, SPP, FLO, etc.) |
| `certificate_exclusion_groups` | Grupos excluyentes de certificados |
| `production_batch_certs` | Certificados asignados a cada lote |
| `batch_temperatures` | Temperaturas durante proceso de produccion |
| `batch_ph_controls` | Control de pH, brix, regulador |
| `worker_controls` | Control de higiene del personal (campo) |
| `worker_control_items` | Items individuales de control de personal |
| `inventory_stock` | Stock actual/reservado por lote |
| `exit_registrations` | Salidas de inventario (guias de remision) |
| `exit_items` | Items individuales de cada salida |
| `stowage_transport_inspections` | Inspeccion de transporte |
| `cleaning_disinfections` | Registros de limpieza y desinfeccion |
| `cleaning_disinfection_items` | Items de limpieza por area |
| `chlorine_residual_controls` | Control de cloro residual en agua |
| `pest_controls` | Control de plagas (padre) |
| `pest_control_bait_records` | Registros de cebos |
| `pest_control_insect_records` | Registros de insectos |
| `environment_inspections` | Inspecciones ambientales |
| `environment_inspection_items` | Items de inspeccion ambiental |
| `equipment_maintenance_records` | Mantenimiento de equipos |
| `health_incidents` | Incidentes de salud laboral |
| `product_returns` | Devoluciones de producto |

---

## Tablas solo Web — 13 tablas

| Tabla | Que registra |
|-------|-------------|
| `web_users` | Usuarios de la web (recepcionista, operador, admin) |
| `exit_receptions` | Recepcion de mercaderia en planta |
| `exit_reception_items` | Discrepancia entre kg enviados vs recibidos |
| `quality_evaluations` | Evaluacion de calidad (humedad, impurezas, color, aprobacion) |
| `plant_orders` | Ordenes de produccion para exportacion |
| `plant_production_batches` | Lotes de planta (marca, presentacion, peso) |
| `plant_homogenization_inputs` | Insumos del homogenizado (que lotes de campo se mezclaron) |
| `plant_batch_processing` | Resultado del procesado (tamizada, descarte, merma) |
| `plant_checklists` | Checklists por lote (equipos, personal) |
| `plant_order_checklists` | Checklists por orden (limpieza, plagas) |
| `plant_containers` | Contenedores de exportacion |
| `plant_dispatches` | Despachos/embarques |
| `form_configurations` | Configuracion dinamica de formularios |

---

## Vistas (calculadas, solo lectura)

| Vista | Que muestra |
|-------|-------------|
| `v_plant_available_stock` | Stock disponible por lote: kg recibidos, usados, disponibles + calidad |
| `v_plant_order_summary` | Resumen por orden: rendimiento, lotes, contenedor |

---

## Flujo resumido

```
CAMPO (Movil)                              PLANTA (Web)
---------                                  ----------
producers + plots
    |
production_batches + certs + temps + pH
    |
exit_registrations + exit_items  ---------> exit_receptions + exit_reception_items
                                                |
                                            quality_evaluations (+ aprobacion)
                                                |
                                            plant_orders -> plant_production_batches
                                                |
                                            homogenization -> processing -> checklists
                                                |
                                            plant_containers -> plant_dispatches
```

La app movil registra **desde campo hasta la salida**. La web toma el control **desde la recepcion en planta hasta el despacho**.

---

## Detalle de columnas clave por seccion

### Organizacion

- **cooperatives**: id, name, code, is_active, cane_density
- **coop_modules**: id, name, cooperative_id, is_active
- **users**: user_id, first_name, last_name, cooperative_id, role, coop_module_id
- **web_users**: id, auth_user_id, cooperative_id, username, role

### Produccion de campo

- **producers**: id, first_name, last_name, dni, cooperative_id, is_member, default_extraction_percentage
- **plots**: id, code, producer_id, name, default_extraction_percentage
- **production_batches**: id, batch_code, harvest_date, process_date, cane_kg, juice_liters, panela_kg, confitillo_kg, producer_id, plot_id
- **batch_temperatures**: id, production_batch_id, temperature, sequence_number
- **batch_ph_controls**: id, production_batch_id, ph_initial, ph_final, brix, regulator_type

### Salida e inventario

- **exit_registrations**: id, exit_code, document_number, exit_date, total_kg, exit_type, destination
- **exit_items**: id, exit_registration_id, production_batch_id, quantity_kg, bags_count
- **inventory_stock**: id, production_batch_id, current_kg, reserved_kg

### Recepcion y calidad (Web)

- **exit_receptions**: id, exit_registration_id, received_by, received_at, status
- **exit_reception_items**: id, exit_item_id, quantity_kg_sent, quantity_kg_received, discrepancy_reason
- **quality_evaluations**: id, exit_item_id, humidity_pct, impurities_pct, color, sack_condition, appearance, approval_status, rejection_reason, extra_data

### Planta - ordenes y procesado (Web)

- **plant_orders**: id, order_code, market, planned_date, total_kg, status
- **plant_production_batches**: id, batch_code, order_id, brand, presentation, unit_weight_kg, planned_quantity, status
- **plant_homogenization_inputs**: id, plant_batch_id, source_exit_item_id, quantity_kg
- **plant_batch_processing**: id, plant_batch_id, tamizada_kg, descarte_kg, merma_kg

### Planta - contenedores y despacho (Web)

- **plant_containers**: id, order_id, container_number, seal_number, container_size, max_capacity_kg, booking_number, bill_of_lading, shipping_line, destination_port, departure_date, estimated_arrival, status, extra_data
- **plant_dispatches**: id, container_id, dispatch_code, dispatch_date, total_loaded_kg, seal_verified, temperature_at_load, humidity_at_load, extra_data

### Checklists de planta (Web)

- **plant_checklists**: id, plant_batch_id, type, items (JSONB), filled_by — por lote (equipos, personal)
- **plant_order_checklists**: id, order_id, type, items (JSONB), filled_by — por orden (limpieza, plagas)

### Configuracion (Web)

- **form_configurations**: id, cooperative_id (NULL=global), step_key, fields (JSONB), is_active, version
  - step_keys: calidad, contenedor, despacho, checklist_limpieza, checklist_mantenimiento_equipos, checklist_control_plagas, checklist_control_personal

### Controles operativos (compartidos)

- **cleaning_disinfections** + **cleaning_disinfection_items**: Limpieza diaria por area
- **chlorine_residual_controls**: Cloro residual en agua (2 puntos de medicion)
- **pest_controls** + **pest_control_bait_records** + **pest_control_insect_records**: Control de plagas
- **environment_inspections** + **environment_inspection_items**: Inspecciones ambientales
- **equipment_maintenance_records**: Mantenimiento preventivo/correctivo
- **health_incidents**: Incidentes de salud laboral
- **worker_controls** + **worker_control_items**: Control de higiene del personal
- **stowage_transport_inspections**: Inspeccion de vehiculos de transporte

---

## Seguridad (RLS)

Todas las tablas usan Row Level Security basada en `cooperative_id`:
- Cada usuario solo ve datos de su cooperativa
- La cooperativa se obtiene del JWT via `auth_cooperative_id()`
- Las vistas usan `security_invoker = true` para respetar el RLS
- `form_configurations` permite leer configs globales (`cooperative_id IS NULL`) a todas las cooperativas
