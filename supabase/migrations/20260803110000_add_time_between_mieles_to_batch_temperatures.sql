-- Tiempo entre mieles (minutos) -- pareado con cada temperatura registrada
-- durante el punteo en la paila. Opcional (la primera temperatura de una
-- tanda normalmente no tiene "miel anterior" contra la cual medir tiempo).

ALTER TABLE public.batch_temperatures
  ADD COLUMN time_between_mieles_minutes numeric(6,2);
