-- Live courier tracking: snapshot on orders + history table.
-- TODO(security): qat’iy RLS — faqat sender/winner o‘qiydi; yozish faqat RPC orqali.

ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS courier_lat double precision;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS courier_lng double precision;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS courier_heading double precision;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS courier_speed double precision;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS courier_accuracy double precision;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS courier_location_updated_at timestamptz;

CREATE TABLE IF NOT EXISTS public.order_tracking_points (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id text NOT NULL,
  courier_id text NOT NULL,
  lat double precision NOT NULL,
  lng double precision NOT NULL,
  heading double precision,
  speed double precision,
  accuracy double precision,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_order_tracking_points_order_created
  ON public.order_tracking_points (order_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_order_tracking_points_courier
  ON public.order_tracking_points (courier_id);

COMMENT ON TABLE public.order_tracking_points IS 'Kuryer yo‘l tarixlari; list uchun orders.snapshot';
COMMENT ON COLUMN public.orders.courier_location_updated_at IS 'Oxirgi jonli lokatsiya vaqti';

-- Atomik: faqat g‘olib, faqat picked_up / delivered.
CREATE OR REPLACE FUNCTION public.report_order_courier_location(
  p_order_id text,
  p_lat double precision,
  p_lng double precision,
  p_heading double precision DEFAULT NULL,
  p_speed double precision DEFAULT NULL,
  p_accuracy double precision DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row public.orders%ROWTYPE;
  v_cid text := trim(both from auth.uid()::text);
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_authenticated');
  END IF;

  SELECT * INTO v_row FROM public.orders o WHERE o.id::text = trim(both from p_order_id) FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_found');
  END IF;

  IF trim(both from coalesce(v_row.winner_courier_id, '')) <> v_cid THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_winner');
  END IF;

  IF v_row.status NOT IN ('picked_up', 'delivered') THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_status', 'status', v_row.status);
  END IF;

  IF p_lat IS NULL OR p_lng IS NULL OR p_lat < -90 OR p_lat > 90 OR p_lng < -180 OR p_lng > 180 THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_coordinates');
  END IF;

  INSERT INTO public.order_tracking_points (
    order_id, courier_id, lat, lng, heading, speed, accuracy, created_at
  ) VALUES (
    trim(both from p_order_id), v_cid, p_lat, p_lng, p_heading, p_speed, p_accuracy, now()
  );

  UPDATE public.orders SET
    courier_lat = p_lat,
    courier_lng = p_lng,
    courier_heading = p_heading,
    courier_speed = p_speed,
    courier_accuracy = p_accuracy,
    courier_location_updated_at = now()
  WHERE id = v_row.id;

  RETURN jsonb_build_object('ok', true);
END;
$$;

REVOKE ALL ON FUNCTION public.report_order_courier_location(text, double precision, double precision, double precision, double precision, double precision) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.report_order_courier_location(text, double precision, double precision, double precision, double precision, double precision) TO authenticated;

-- TODO(RLS): ALTER TABLE order_tracking_points ENABLE ROW LEVEL SECURITY;
-- Policy misol: SELECT faqat orders.sender_id = auth.uid() yoki orders.winner_courier_id = auth.uid()
-- INSERT/UPDATE/DELETE: taqiqlangan (faqat RPC).
