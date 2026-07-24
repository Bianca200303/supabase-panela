-- Al editar una revisión de calidad ya rechazada, el código insertaba una
-- fila nueva en product_returns cada vez que se guardaba -- sin ningún
-- vínculo hacia la revisión que la originó, así que no había forma de
-- saber "esto ya tiene una devolución, hay que actualizarla" en vez de
-- duplicar. Y si se revertía el rechazo (se volvía a aprobar), la
-- devolución quedaba huérfana, sin ningún rastro de que ya no aplicaba.
--
-- Se agrega el vínculo (quality_evaluations.product_return_id) para saber
-- qué devolución corresponde a cada revisión, y un marcador de anulación
-- (product_returns.voided_at) para los casos en que se revierte el
-- rechazo -- nunca se borra el registro, solo se marca como anulado, así
-- se conserva la trazabilidad completa en vez de perder el historial.

alter table "public"."quality_evaluations"
  add column "product_return_id" uuid null;

alter table "public"."quality_evaluations"
  add constraint "quality_evaluations_product_return_id_fkey"
  foreign key (product_return_id) references public.product_returns(id) on delete set null;

alter table "public"."product_returns"
  add column "voided_at" timestamp with time zone null;
