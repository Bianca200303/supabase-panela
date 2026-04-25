
  ALTER TABLE public.stowage_transport_inspections
    ADD COLUMN IF NOT EXISTS registered_by_user_id character varying(8);

  CREATE OR REPLACE TRIGGER set_stowage_registered_by_before_insert
    BEFORE INSERT ON public.stowage_transport_inspections
    FOR EACH ROW EXECUTE FUNCTION public.set_registered_by_from_auth();

  ALTER TABLE ONLY public.stowage_transport_inspections
    DROP CONSTRAINT IF EXISTS stowage_inspections_registered_by_fkey;
  ALTER TABLE ONLY public.stowage_transport_inspections
    ADD CONSTRAINT stowage_inspections_registered_by_fkey
    FOREIGN KEY (registered_by_user_id, cooperative_id)
    REFERENCES public.users(user_id, cooperative_id) ON DELETE RESTRICT;