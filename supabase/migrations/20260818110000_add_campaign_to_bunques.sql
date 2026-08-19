-- =============================================================================
-- Vincula plant_batch_bunques a campaigns.
--
-- Objetivo: la sugerencia automática de N° de bunque (HomogenizadoBunquesModal)
-- debe acotarse a la campaña vigente, no al histórico completo de la
-- cooperativa -- si no, un año nuevo seguiría sugiriendo números que
-- continúan la numeración de la campaña anterior.
--
-- campaign_id queda NULLABLE a propósito: si una cooperativa todavía no
-- creó/abrió ninguna campaña, la creación de bunques no debe bloquearse por
-- eso -- mismo principio de "no restringir" ya aplicado al bunque_number
-- (ver 20260715120000_create_plant_batch_bunques.sql).
-- =============================================================================

ALTER TABLE public.plant_batch_bunques
  ADD COLUMN campaign_id uuid;

ALTER TABLE public.plant_batch_bunques
  ADD CONSTRAINT pbb_campaign_fkey
    FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON DELETE SET NULL;

CREATE INDEX idx_pbb_campaign
  ON public.plant_batch_bunques (campaign_id);

-- Backfill: los bunques ya creados quedan asociados a la campaña activa de
-- su propia cooperativa (si existe una). Los que no tengan campaña activa
-- disponible quedan en NULL -- no hay forma confiable de inferir a cuál
-- pertenecían, y no es necesario para que el sistema siga funcionando.
UPDATE public.plant_batch_bunques b
SET campaign_id = c.id
FROM public.campaigns c
WHERE c.cooperative_id = b.cooperative_id
  AND c.is_active = true
  AND b.campaign_id IS NULL;
