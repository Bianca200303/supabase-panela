-- =============================================================================
-- Se elimina por completo "Control de Almacén" (luego renombrado "Control de
-- Agua" en la UI, pages/ControlAlmacenPage.jsx) -- resultó ser 100%
-- redundante con controles reales ya existentes:
--   - temperatura_c/humedad_pct duplicaban Control de Temperatura y Humedad
--     de Ambientes (CAESP-PP-BPM-RE-RMP-003, plant_temp_humidity_control_caes),
--     que mide la misma ubicación "Almacén de Producto Terminado" con
--     T1/T2/T3 + promedio (más preciso que el valor único de acá).
--   - Los 4 puntos de agua (plant_warehouse_water_checks) duplicaban el
--     Monitoreo de Cloro Residual de CAES (plant_chlorine_monitoring_events_caes,
--     CAESP-PP-HYS-RE-CDA-001) -- mismo dato real (CLR en ppm por punto de
--     muestreo y fecha), solo que ahí el punto es texto libre en vez de un
--     catálogo cerrado de 4 códigos.
-- Además, Control de Almacén nunca tuvo código de papel documentado (no es
-- de los 15 registros BPM/HYS relevados de los PDFs reales de CAES, ver
-- ControlesPage.jsx) -- todo indica que se armó sin un formato físico propio
-- detrás. El Resumen de Trazabilidad pasa a leer su sección "Control de
-- Agua" directo del bloque de Cloro Residual CAES más reciente en el rango
-- de la orden (ver lib/formatos/resumenTrazabilidad.js), sin fetch nuevo.
--
-- Sin usuarios en producción todavía -- se confirma con el usuario que no
-- hay datos reales cargados en estas 2 tablas que haga falta conservar.
-- =============================================================================

DROP FUNCTION IF EXISTS public.generate_warehouse_control_code(uuid, text);
DROP TABLE IF EXISTS public.plant_warehouse_water_checks;
DROP TABLE IF EXISTS public.plant_warehouse_controls;
