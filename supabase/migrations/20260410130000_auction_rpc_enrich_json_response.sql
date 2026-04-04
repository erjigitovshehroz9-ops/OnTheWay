-- RPC javobiga `current_price_cents`, `start_price_cents`, `auction_last_courier_id` qo‘shiladi
-- (oldingi migratsiyalar allaqachon ishga tushgan bo‘lsa ham idempotent yangilanish).

CREATE OR REPLACE FUNCTION public.start_or_step_auction(p_order_id text, p_courier_id text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row public.orders%ROWTYPE;
  v_now timestamptz := now();
  v_expires timestamptz := v_now + interval '30 seconds';
  v_start bigint;
  v_min bigint;
  v_old bigint;
  v_new bigint;
  v_step int;
  v_count int;
  v_bid_id uuid := gen_random_uuid();
  v_cid text := trim(both from p_courier_id);
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_authenticated');
  END IF;
  IF trim(both from auth.uid()::text) <> v_cid THEN
    RETURN jsonb_build_object('ok', false, 'error', 'forbidden');
  END IF;

  SELECT * INTO v_row FROM public.orders o WHERE o.id::text = trim(both from p_order_id) FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_found');
  END IF;

  v_start := COALESCE(v_row.start_price_cents, v_row.price, 0)::bigint;
  IF v_start <= 0 THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_start_price');
  END IF;

  IF v_row.status = 'posted' THEN
    v_min := ROUND(v_start * 0.5)::bigint;

    UPDATE public.orders SET
      status = 'auction_live',
      current_price_cents = v_start,
      minimum_price_cents = v_min,
      auction_started_at = v_now,
      auction_expires_at = v_expires,
      auction_ends_at = v_expires,
      auction_step_percent = COALESCE(v_row.auction_step_percent, 5::numeric),
      leading_courier_id = v_cid,
      auction_last_courier_id = v_cid,
      auction_bid_count = 1,
      auction_step = 0,
      floor_price_cents = COALESCE(v_row.floor_price_cents, v_min)
    WHERE id = v_row.id;

    INSERT INTO public.bids (
      id, order_id, courier_id, step_index, price_cents,
      price_before_cents, price_after_cents, created_at
    ) VALUES (
      v_bid_id, v_row.id, v_cid, 0, v_start,
      NULL, v_start, v_now
    );

    RETURN jsonb_build_object(
      'ok', true,
      'action', 'start',
      'bid_id', v_bid_id::text,
      'price_after_cents', v_start,
      'current_price_cents', v_start,
      'start_price_cents', v_start,
      'auction_step', 0,
      'auction_bid_count', 1,
      'auction_ends_at', to_jsonb(v_expires),
      'auction_expires_at', to_jsonb(v_expires),
      'leading_courier_id', to_jsonb(v_cid),
      'auction_last_courier_id', to_jsonb(v_cid),
      'minimum_price_cents', v_min,
      'status', 'auction_live'
    );
  END IF;

  IF v_row.status = 'auction_live' THEN
    IF COALESCE(v_row.auction_expires_at, v_row.auction_ends_at) IS NOT NULL
       AND v_now >= COALESCE(v_row.auction_expires_at, v_row.auction_ends_at) THEN
      RETURN jsonb_build_object('ok', false, 'error', 'auction_expired');
    END IF;

    IF v_row.leading_courier_id IS NOT NULL
       AND trim(both from v_row.leading_courier_id) = v_cid THEN
      RETURN jsonb_build_object('ok', false, 'error', 'already_leading');
    END IF;

    v_min := COALESCE(
      v_row.minimum_price_cents,
      v_row.floor_price_cents,
      ROUND(v_start * 0.5)::bigint
    );
    v_old := COALESCE(v_row.current_price_cents, v_start)::bigint;

    v_new := (v_old * 95) / 100;
    IF v_new < v_min THEN
      v_new := v_min;
    END IF;

    IF v_new >= v_old THEN
      RETURN jsonb_build_object('ok', false, 'error', 'at_floor');
    END IF;

    v_step := COALESCE(v_row.auction_step, 0) + 1;
    v_count := COALESCE(v_row.auction_bid_count, 0) + 1;

    UPDATE public.orders SET
      current_price_cents = v_new,
      minimum_price_cents = v_min,
      auction_expires_at = v_expires,
      auction_ends_at = v_expires,
      leading_courier_id = v_cid,
      auction_last_courier_id = v_cid,
      auction_bid_count = v_count,
      auction_step = v_step,
      floor_price_cents = COALESCE(v_row.floor_price_cents, v_min)
    WHERE id = v_row.id;

    INSERT INTO public.bids (
      id, order_id, courier_id, step_index, price_cents,
      price_before_cents, price_after_cents, created_at
    ) VALUES (
      v_bid_id, v_row.id, v_cid, v_step, v_new,
      v_old, v_new, v_now
    );

    RETURN jsonb_build_object(
      'ok', true,
      'action', 'step',
      'bid_id', v_bid_id::text,
      'price_before_cents', v_old,
      'price_after_cents', v_new,
      'current_price_cents', v_new,
      'start_price_cents', v_start,
      'auction_step', v_step,
      'auction_bid_count', v_count,
      'auction_ends_at', to_jsonb(v_expires),
      'auction_expires_at', to_jsonb(v_expires),
      'leading_courier_id', to_jsonb(v_cid),
      'auction_last_courier_id', to_jsonb(v_cid),
      'minimum_price_cents', v_min,
      'status', 'auction_live'
    );
  END IF;

  RETURN jsonb_build_object('ok', false, 'error', 'bad_status', 'status', v_row.status);
END;
$$;
