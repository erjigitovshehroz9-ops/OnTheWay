-- Flutter [SupabaseOrderService.createOrderRemote] payload bilan public.orders mosligi.
-- Remote’da "cold_storage column not found" va boshqa schema mismatch — migratsiya apply qilinmagan
-- yoki eski jadval: barcha kerakli ustunlar idempotent qo‘shiladi.
--
-- PostgREST: DDL dan keyin cache yangilanishi uchun NOTIFY (ixtiyoriy lekin foydali).

-- ============================================================================
-- Manzil / geocoder maydonlari (createOrderRemote: pickup_*, dropoff_*)
-- ============================================================================
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS pickup_region text;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS pickup_district text;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS dropoff_region text;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS dropoff_district text;

ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS pickup_lat double precision;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS pickup_lng double precision;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS dropoff_lat double precision;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS dropoff_lng double precision;

-- ============================================================================
-- Rasm (HTTP URL upload keyin)
-- ============================================================================
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS image_url text;

-- ============================================================================
-- Narx va auksion holati (create + sync)
-- ============================================================================
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS price bigint;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS start_price_cents bigint;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS floor_price_cents bigint;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS final_price_cents bigint;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS auction_step integer NOT NULL DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS auction_ends_at timestamptz;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS leading_courier_id text;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS winner_courier_id text;

-- ============================================================================
-- Buyurtma tarkibi / yetkazish (20260403120000 bilan bir xil — takroriy apply xavfsiz)
-- ============================================================================
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

COMMENT ON COLUMN public.orders.cold_storage IS 'Flutter JobEntity.cold_chain → Supabase cold_storage';

-- ============================================================================
-- Server auksion RPC (finalize/start_or_step bilan mos)
-- ============================================================================
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS current_price_cents bigint;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS minimum_price_cents bigint;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS auction_started_at timestamptz;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS auction_expires_at timestamptz;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS auction_step_percent numeric(5,2) NOT NULL DEFAULT 5;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS auction_last_courier_id text;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS auction_bid_count integer NOT NULL DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS winner_selected_at timestamptz;

-- ============================================================================
-- Kuryer tracking (realtime / patch)
-- ============================================================================
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS courier_lat double precision;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS courier_lng double precision;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS courier_heading double precision;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS courier_speed double precision;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS courier_accuracy double precision;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS courier_location_updated_at timestamptz;

-- ============================================================================
-- Indekslar (20260403120000 bilan mos)
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_orders_sender_id ON public.orders (sender_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders (status);
CREATE INDEX IF NOT EXISTS idx_orders_region_code ON public.orders (region_code);
CREATE INDEX IF NOT EXISTS idx_orders_district_code ON public.orders (district_code);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_sender_status ON public.orders (sender_id, status);
CREATE INDEX IF NOT EXISTS idx_orders_region_district ON public.orders (region_code, district_code);

NOTIFY pgrst, 'reload schema';
