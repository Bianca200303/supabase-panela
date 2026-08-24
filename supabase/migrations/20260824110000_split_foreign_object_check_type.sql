-- =============================================================================
-- Control de Objetos Extraños -- separa cada inspección en dos tipos
-- excluyentes en vez de pedir siempre las mismas 4 cosas juntas:
--
--   'prueba'  -- calibración del detector con una pieza de prueba (no es
--               producto real). Pide: hora, test (F/NF/AI), conformidad.
--               bags_separated queda en 0 -- no hay producción real de por medio.
--   'rechazo' -- el detector separó una bolsa real de la línea. Pide: hora,
--               cantidad de bolsas separadas. test_type/conforme quedan en
--               NULL -- no se está calibrando nada, es un rechazo real.
--
-- "Cantidad de rechazos indicado en el equipo" NO es una columna nueva --
-- sigue siendo inspection_number (el correlativo que ya asigna el trigger
-- set_foreign_object_check_number()), confirmado con el usuario: el equipo
-- físico también cuenta bolsa por bolsa, así que un correlativo del sistema
-- ya es equivalente a leer el contador del equipo a mano.
--
-- T1/T2/T3 del documento (ver formatoUtils.js) cambian de significado:
--   T1 = bolsas rechazadas de verdad (checks 'rechazo', igual que antes)
--   T2 = T1 + cantidad de pruebas hechas (antes era "cuántas filas hay",
--        daba lo mismo porque antes cada fila era rechazo+prueba a la vez)
--   T3 ("según contador del equipo") se elimina -- ya no aparece ni en el
--   formulario ni en el documento final, decisión ya conversada con el
--   usuario fuera de este sistema.
-- =============================================================================

ALTER TABLE public.plant_batch_foreign_object_checks
  ADD COLUMN check_type text NOT NULL DEFAULT 'rechazo';

-- Backfill de filas ya cargadas (antes del modelo nuevo, TODAS traían
-- bags_separated + test_type + conforme juntos, sin importar el tipo):
-- si hubo un rechazo real (bags_separated > 0), se clasifica como
-- 'rechazo' -- el dato de producción real es el más importante y se
-- conserva; el test/conformidad que venía pegado ya no aplica al modelo
-- nuevo y se limpia (el papel físico original sigue siendo la fuente de
-- verdad para auditorías históricas de calibración). Si no hubo rechazo
-- (bags_separated = 0), era en la práctica solo una prueba de rutina --
-- se clasifica como 'prueba' y conserva test/conformidad.
UPDATE public.plant_batch_foreign_object_checks
SET check_type = 'rechazo'
WHERE bags_separated > 0;

UPDATE public.plant_batch_foreign_object_checks
SET check_type = 'prueba'
WHERE bags_separated = 0;

-- Hay que sacar el NOT NULL de test_type/conforme ANTES de poder limpiarlos
-- a NULL en las filas 'rechazo' -- si no, la propia UPDATE de abajo choca
-- contra la restricción vieja que todavía no se quitó.
ALTER TABLE public.plant_batch_foreign_object_checks
  ALTER COLUMN check_type DROP DEFAULT,
  ALTER COLUMN test_type DROP NOT NULL,
  ALTER COLUMN conforme DROP NOT NULL;

UPDATE public.plant_batch_foreign_object_checks
SET test_type = NULL, conforme = NULL
WHERE check_type = 'rechazo';

ALTER TABLE public.plant_batch_foreign_object_checks
  ADD CONSTRAINT pbfoc_check_type_check CHECK (check_type IN ('prueba', 'rechazo'));

ALTER TABLE public.plant_batch_foreign_object_checks
  ADD CONSTRAINT pbfoc_type_fields_check CHECK (
    (check_type = 'prueba'  AND test_type IS NOT NULL AND conforme IS NOT NULL AND bags_separated = 0)
    OR
    (check_type = 'rechazo' AND test_type IS NULL     AND conforme IS NULL)
  );
