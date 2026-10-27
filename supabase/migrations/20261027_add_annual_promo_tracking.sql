ALTER TABLE public.membership
  ADD COLUMN IF NOT EXISTS annual_promo_used boolean NOT NULL DEFAULT false;

UPDATE public.membership
SET annual_promo_used = true
WHERE plan_name = '1 Tahun';

NOTIFY pgrst, 'reload schema';
