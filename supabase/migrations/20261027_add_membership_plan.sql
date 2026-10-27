ALTER TABLE public.membership
  ADD COLUMN IF NOT EXISTS plan_name text,
  ADD COLUMN IF NOT EXISTS duration_days integer,
  ADD COLUMN IF NOT EXISTS price_idr integer,
  ADD COLUMN IF NOT EXISTS original_price_idr integer;

UPDATE public.membership
SET plan_name = COALESCE(plan_name, '1 Bulan'),
    duration_days = COALESCE(duration_days, 30),
    price_idr = COALESCE(price_idr, 29000),
    original_price_idr = COALESCE(original_price_idr, 29000);

ALTER TABLE public.membership
  ALTER COLUMN plan_name SET NOT NULL,
  ALTER COLUMN duration_days SET NOT NULL,
  ALTER COLUMN price_idr SET NOT NULL,
  ALTER COLUMN original_price_idr SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'membership_plan_name_check') THEN
    ALTER TABLE public.membership ADD CONSTRAINT membership_plan_name_check
      CHECK (plan_name IN ('1 Bulan', '1 Tahun'));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'membership_duration_days_check') THEN
    ALTER TABLE public.membership ADD CONSTRAINT membership_duration_days_check
      CHECK (duration_days IN (30, 365));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'membership_price_idr_check') THEN
    ALTER TABLE public.membership ADD CONSTRAINT membership_price_idr_check
      CHECK (price_idr > 0);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'membership_original_price_check') THEN
    ALTER TABLE public.membership ADD CONSTRAINT membership_original_price_check
      CHECK (original_price_idr >= price_idr);
  END IF;
END
$$;

NOTIFY pgrst, 'reload schema';
