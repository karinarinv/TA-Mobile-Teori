CREATE TABLE IF NOT EXISTS public.membership (
  username text PRIMARY KEY
    REFERENCES public.users(username)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  plan_name text NOT NULL CHECK (plan_name IN ('1 Bulan', '1 Tahun')),
  duration_days integer NOT NULL CHECK (duration_days IN (30, 365)),
  price_idr integer NOT NULL CHECK (price_idr > 0),
  original_price_idr integer NOT NULL CHECK (original_price_idr >= price_idr),
  annual_promo_used boolean NOT NULL DEFAULT false,
  started_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT membership_expiry_after_start CHECK (expires_at > started_at)
);

NOTIFY pgrst, 'reload schema';
