# Carga de Trabajadores Certificados

Queries para gestionar `certified_workers` desde el SQL Editor de Supabase.
Solo `first_name`, `last_name`, `cooperative_id` y `coop_module_id` son obligatorios.

---

## 0. Inspección previa — ver cooperativas y módulos disponibles

```sql
SELECT
  c.id   AS cooperative_id,
  c.name AS cooperativa,
  cm.id  AS module_id,
  cm.name AS modulo
FROM coop_modules cm
JOIN cooperatives c ON c.id = cm.cooperative_id
ORDER BY c.name, cm.name;
```

---

## 1. Insertar trabajadores de un módulo (carga mínima — solo nombre)

```sql
INSERT INTO certified_workers (first_name, last_name, cooperative_id, coop_module_id)
VALUES
  ('Juan',    'Pérez García',   '<cooperative_id>', '<module_id>'),
  ('María',   'López Sánchez',  '<cooperative_id>', '<module_id>'),
  ('Carlos',  'Ruiz Torres',    '<cooperative_id>', '<module_id>');
```

---

## 2. Insertar con campos opcionales (carga completa)

```sql
INSERT INTO certified_workers
  (first_name, last_name, dni, position, certified_since, certified_until, cooperative_id, coop_module_id, notes)
VALUES
  ('Juan', 'Pérez García', '12345678', 'Operario de planta', '2025-01-15', '2026-01-15',
   '<cooperative_id>', '<module_id>', NULL),
  ('María', 'López Sánchez', '87654321', 'Técnico de piso', '2025-03-01', NULL,
   '<cooperative_id>', '<module_id>', 'Certificación en trámite');
```

---

## 3. Carga masiva para todos los módulos de una cooperativa

Ejecutar un bloque por módulo, ajustando `module_id` y los nombres:

```sql
-- Módulo: Huancabamba
INSERT INTO certified_workers (first_name, last_name, cooperative_id, coop_module_id)
VALUES
  ('Nombre1', 'Apellido1', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000001'),
  ('Nombre2', 'Apellido2', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000001');

-- Módulo: Ayabaca
INSERT INTO certified_workers (first_name, last_name, cooperative_id, coop_module_id)
VALUES
  ('Nombre3', 'Apellido3', '550e8400-e29b-41d4-a716-446655440001', 'bb010000-0000-0000-0000-000000000002');
```

---

## 4. Verificación post-carga

```sql
SELECT
  c.name  AS cooperativa,
  cm.name AS modulo,
  cw.first_name || ' ' || cw.last_name AS trabajador,
  cw.dni,
  cw.position,
  cw.certified_since,
  cw.certified_until,
  cw.is_active
FROM certified_workers cw
JOIN cooperatives c  ON c.id  = cw.cooperative_id
JOIN coop_modules cm ON cm.id = cw.coop_module_id
ORDER BY c.name, cm.name, cw.last_name;
```

---

## 5. Dar de baja a un trabajador (sin borrar — preserva historial)

```sql
UPDATE certified_workers
SET is_active = false
WHERE id = '<worker_id>';
```

---

## 6. Corregir nombre de un trabajador

```sql
UPDATE certified_workers
SET first_name = 'NuevoNombre', last_name = 'NuevoApellido'
WHERE id = '<worker_id>';
```

---

## IDs de referencia rápida

### Norandino (`550e8400-e29b-41d4-a716-446655440001`)
| Módulo | module_id |
|---|---|
| Huancabamba | `bb010000-0000-0000-0000-000000000001` |
| Ayabaca     | `bb010000-0000-0000-0000-000000000002` |
| Morropón    | `bb010000-0000-0000-0000-000000000003` |
| Pacaipampa  | `bb010000-0000-0000-0000-000000000004` |
| Sóndor      | `bb010000-0000-0000-0000-000000000005` |
| Montero     | `bb010000-0000-0000-0000-000000000006` |
| Sapillica   | `bb010000-0000-0000-0000-000000000007` |
| Lalaquiz    | `bb010000-0000-0000-0000-000000000008` |
| El Faique   | `bb010000-0000-0000-0000-000000000009` |
| Canchaque   | `bb010000-0000-0000-0000-000000000010` |

### CAES Piura (`550e8400-e29b-41d4-a716-446655440002`)
| Módulo | module_id |
|---|---|
| Valle Quiroz | `bb020000-0000-0000-0000-000000000001` |
| Valle Piura  | `bb020000-0000-0000-0000-000000000002` |
| Chulucanas   | `bb020000-0000-0000-0000-000000000003` |
| La Matanza   | `bb020000-0000-0000-0000-000000000004` |
| Bigote       | `bb020000-0000-0000-0000-000000000005` |
| Yamango      | `bb020000-0000-0000-0000-000000000006` |
| Palo Blanco  | `bb020000-0000-0000-0000-000000000007` |
| Serrán       | `bb020000-0000-0000-0000-000000000008` |
| San Juan     | `bb020000-0000-0000-0000-000000000009` |
| Vilcayal     | `bb020000-0000-0000-0000-000000000010` |
