-- plant_orders.order_certification era un campo de texto libre, escrito y
-- mostrado únicamente en el formulario de crear/editar orden -- ningún
-- reporte ni PDF lo leía. Además contradice una decisión ya tomada antes en
-- este mismo proyecto (ver 20260515140000_0003_plant_batch_certs.sql): las
-- certificaciones pertenecen al LOTE de planta, no a la orden, porque
-- dependen de la materia prima homogenizada en ese lote específico -- un
-- mismo pedido puede combinar lotes con certificaciones distintas. Esa
-- migración ya reemplazó plant_order_certs por plant_batch_certs por este
-- motivo; este campo suelto en plant_orders quedó vestigial, compitiendo con
-- el sistema correcto que ya existe a nivel de lote.

ALTER TABLE public.plant_orders
  DROP COLUMN IF EXISTS order_certification;
