-- Production-safe: mavjud `public.orders` qatorlarini buzmasdan yangi ustunlar.
-- PostgreSQL 11+ (ADD COLUMN IF NOT EXISTS).
-- Avval mavjud ustunlarni tekshirib qo‘ying: pickup_region, pickup_district, dropoff_*, recipient_*, image_url, transport_type allaqachon bo‘lishi mumkin.

-- ---------------------------------------------------------------------------
-- Yangi yoki kengaytiriladigan ustunlar (takrorlanmasin)
-- ---------------------------------------------------------------------------
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS product_type text;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_speed text;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_window_start text;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_window_end text;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS region_code text;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS district_code text;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS volume_category text;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS product_weight_kg double precision;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS product_volume_l double precision;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS dimensions_mm text;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS payment_type text;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS comments text;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS fragile boolean NOT NULL DEFAULT false;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS cold_storage boolean NOT NULL DEFAULT false;

-- ---------------------------------------------------------------------------
-- Indekslar (filter + ro‘yxatlar)
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_orders_sender_id ON public.orders (sender_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders (status);
CREATE INDEX IF NOT EXISTS idx_orders_region_code ON public.orders (region_code);
CREATE INDEX IF NOT EXISTS idx_orders_district_code ON public.orders (district_code);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_sender_status ON public.orders (sender_id, status);
CREATE INDEX IF NOT EXISTS idx_orders_region_district ON public.orders (region_code, district_code);

COMMENT ON COLUMN public.orders.cold_storage IS 'SQLite cold_chain bilan mos; true = sovuq zanjir talabi';
