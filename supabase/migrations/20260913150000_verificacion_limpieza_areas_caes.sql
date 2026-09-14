-- =============================================================================
-- Verificación de Limpieza para CAES: catálogo de áreas/ítems propio.
--
-- La Verificación del Programa de Limpieza y Sanitización (SIG-GIA-RG-009
-- en Norandino) reusa el mismo motor para CAES (misma tabla
-- plant_cleaning_verification_controls, mismo VerificacionLimpiezaPage.jsx
-- -- por fecha, condición C/NC + acción correctiva) pero con un catálogo de
-- áreas/ítems propio, calcado del papel real de CAES "Inspección de
-- Ambientes, Equipos y Personal" (CAESP-PP-HYS-RE-HYS-002). Aprovecha la
-- herencia ya existente de form_configurations (cooperativa-específica >
-- global > default en código, ver lib/formConfig.js loadVerificacionLimpiezaAreas())
-- -- no hace falta ningún flag nuevo en COOPERATIVE.features ni cambios de
-- código: el DEFAULT en formConfig.js sigue siendo el de Norandino, y esta
-- fila cooperativa-específica lo reemplaza SOLO para CAES.
--
-- "OTROS (ESPECIFICAR)" del papel (filas en blanco para agregar libremente)
-- no se modela acá -- el campo "Observaciones" general del control cumple
-- ese rol; si hace falta más trazabilidad ahí, se puede sumar después.
-- =============================================================================

INSERT INTO public.form_configurations (cooperative_id, step_key, fields, is_active)
VALUES (
  '550e8400-e29b-41d4-a716-446655440002',
  'verificacion_limpieza_areas',
  '[
    {
      "key": "areas",
      "label": "Áreas",
      "type": "grouped-list",
      "required": true,
      "order": 1,
      "options": [
        { "area": "Recepción", "items": [
          { "code": "paredes_techo", "label": "Paredes y Techo" },
          { "code": "pisos_ventanas", "label": "Pisos y ventanas" },
          { "code": "porton_puertas", "label": "Portón - puertas" },
          { "code": "parihuelas_tachos", "label": "Parihuelas y tachos de basura" },
          { "code": "personal", "label": "Personal *" },
          { "code": "presencia_plagas", "label": "Presencia o signos de plagas" }
        ] },
        { "area": "Almacén de Materia Prima", "items": [
          { "code": "paredes", "label": "Paredes" },
          { "code": "puertas_ventanas_mallas", "label": "Puertas, ventanas y mallas" },
          { "code": "pisos_techo", "label": "Pisos y techo" },
          { "code": "balanza_plataforma", "label": "Balanza plataforma" },
          { "code": "parihuelas", "label": "Parihuelas" },
          { "code": "personal", "label": "Personal *" },
          { "code": "presencia_plagas", "label": "Presencia o signos de plagas" }
        ] },
        { "area": "Tamizado, Homogenizado y Envasado", "items": [
          { "code": "paredes_pisos_canaletas", "label": "Paredes, pisos y canaletas" },
          { "code": "techo", "label": "Techo" },
          { "code": "zarandas_bunques", "label": "Zarandas y bunques" },
          { "code": "parihuelas", "label": "Parihuelas" },
          { "code": "utensilios", "label": "Utensilios" },
          { "code": "balanza_plataforma", "label": "Balanza plataforma" },
          { "code": "personal", "label": "Personal *" },
          { "code": "presencia_plagas", "label": "Presencia o signos de plagas" }
        ] },
        { "area": "Almacén de Producto Terminado", "items": [
          { "code": "paredes_pisos_techo", "label": "Paredes, pisos y techo" },
          { "code": "puertas_ventanas", "label": "Puertas y ventanas" },
          { "code": "parihuelas", "label": "Parihuelas" },
          { "code": "personal", "label": "Personal *" },
          { "code": "presencia_plagas", "label": "Presencia o signos de plagas" }
        ] },
        { "area": "Almacén de Materiales e Insumos", "items": [
          { "code": "paredes_pisos_techo", "label": "Paredes, pisos, techo" },
          { "code": "puertas_ventanas", "label": "Puertas y ventanas" },
          { "code": "parihuelas", "label": "Parihuelas" },
          { "code": "anaqueles_estantes", "label": "Anaqueles o estantes" },
          { "code": "presencia_plagas", "label": "Presencia o signos de plagas" }
        ] },
        { "area": "Laboratorio", "items": [
          { "code": "paredes_pisos_techo", "label": "Paredes, pisos, techo" },
          { "code": "puertas_ventanas", "label": "Puertas y ventanas" },
          { "code": "utensilios", "label": "Utensilios" },
          { "code": "material_vidrio", "label": "Material de vidrio" },
          { "code": "equipos", "label": "Equipos" },
          { "code": "estantes_mesas", "label": "Estantes y mesas" },
          { "code": "personal", "label": "Personal *" },
          { "code": "presencia_plagas", "label": "Presencia o signos de plagas" }
        ] },
        { "area": "Vestuarios", "items": [
          { "code": "paredes_pisos_techo", "label": "Paredes, pisos, techo" },
          { "code": "puertas_ventanas", "label": "Puertas y ventanas" },
          { "code": "armario_lockers", "label": "Armario/lockers" },
          { "code": "personal", "label": "Personal *" },
          { "code": "presencia_plagas", "label": "Presencia o signos de plagas" }
        ] },
        { "area": "Oficina", "items": [
          { "code": "paredes_pisos_techo", "label": "Paredes, pisos, techo" },
          { "code": "puertas_ventanas", "label": "Puertas y ventanas" },
          { "code": "estantes_escritorios_sillas", "label": "Estantes, escritorios, sillas, etc." },
          { "code": "equipos", "label": "Equipos" },
          { "code": "presencia_plagas", "label": "Presencia o signos de plagas" }
        ] },
        { "area": "Servicios Higiénicos", "items": [
          { "code": "paredes", "label": "Paredes" },
          { "code": "puertas_ventanas", "label": "Puertas y ventanas" },
          { "code": "pisos", "label": "Pisos" },
          { "code": "banos_lavatorios_duchas", "label": "Baños, lavatorios y duchas" }
        ] },
        { "area": "Utensilios de Limpieza", "items": [
          { "code": "cartilla_colores", "label": "Según cartilla colores" },
          { "code": "tachos_recipientes", "label": "Tachos y recipientes de basura" },
          { "code": "limpieza_orden", "label": "Limpieza y orden" }
        ] },
        { "area": "Reservorio", "items": [
          { "code": "tanque_1", "label": "Tanque N°01" },
          { "code": "tanque_2", "label": "Tanque N°02" },
          { "code": "tanque_3", "label": "Tanque N°03" }
        ] }
      ]
    }
  ]'::jsonb,
  true
)
ON CONFLICT (cooperative_id, step_key) DO UPDATE SET fields = EXCLUDED.fields, updated_at = now();
