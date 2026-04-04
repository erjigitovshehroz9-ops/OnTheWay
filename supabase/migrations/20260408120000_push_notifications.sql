-- Push notifications: qurilmalar, log, navbat, dedupe, admin qabulchilari.
-- FCM yuborish: Edge Function `process-push-events` + `FCM_LEGACY_SERVER_KEY` yoki HTTP v1.
-- TODO(security): ilova user_id ni serverda tasdiqlash (Supabase Auth yoki imzo).

-- ---------------------------------------------------------------------------
-- Jadval: qurilma tokenlari (bir user — bir nechta qurilma)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_device_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id text NOT NULL,
  token text NOT NULL,
  platform text NOT NULL,
  device_id text NOT NULL DEFAULT '',
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT user_device_tokens_token_unique UNIQUE (token),
  CONSTRAINT user_device_tokens_platform_check CHECK (
    lower(platform) IN ('android', 'ios', 'web', 'unknown')
  )
);

CREATE INDEX IF NOT EXISTS idx_user_device_tokens_user_id
  ON public.user_device_tokens (user_id)
  WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_user_device_tokens_user_device
  ON public.user_device_tokens (user_id, device_id);

COMMENT ON TABLE public.user_device_tokens IS 'FCM/APNs tokenlar; logoutda is_active=false';

-- ---------------------------------------------------------------------------
-- Yuborilgan pushlar logi
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.push_notifications_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id text,
  order_id text,
  type text NOT NULL,
  title text NOT NULL DEFAULT '',
  body text NOT NULL DEFAULT '',
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  sent_at timestamptz NOT NULL DEFAULT now(),
  delivery_status text NOT NULL DEFAULT 'queued',
  error_message text
);

CREATE INDEX IF NOT EXISTS idx_push_notifications_log_user
  ON public.push_notifications_log (user_id, sent_at DESC);

CREATE INDEX IF NOT EXISTS idx_push_notifications_log_order
  ON public.push_notifications_log (order_id, sent_at DESC);

-- ---------------------------------------------------------------------------
-- Navbat: ishlovchi (Edge Function) consume qiladi
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notification_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  type text NOT NULL,
  target_user_id text,
  order_id text,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  dedupe_key text,
  scheduled_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  processed_at timestamptz,
  last_error text
);

CREATE INDEX IF NOT EXISTS idx_notification_events_pending
  ON public.notification_events (scheduled_at ASC)
  WHERE processed_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_notification_events_dedupe
  ON public.notification_events (dedupe_key)
  WHERE dedupe_key IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Dedupe (outbid throttle va takroriy eventlar)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.push_notification_dedup (
  dedupe_key text PRIMARY KEY,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_push_notification_dedup_created
  ON public.push_notification_dedup (created_at);

-- Eski kalitlarni tozalash (ixtiyoriy; cron bilan chaqirish mumkin)
CREATE OR REPLACE FUNCTION public.push_dedup_cleanup(p_max_age interval DEFAULT interval '7 days')
RETURNS integer
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  WITH d AS (
    DELETE FROM public.push_notification_dedup
    WHERE created_at < now() - p_max_age
    RETURNING 1
  )
  SELECT count(*)::int FROM d;
$$;

-- ---------------------------------------------------------------------------
-- Admin push qabulchilari (user_id = ilova SQLite uuid, qo‘lda INSERT)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.push_admin_recipients (
  user_id text PRIMARY KEY,
  note text,
  created_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.push_admin_recipients IS 'Shikoyat / past baho pushlari uchun admin user_id ro‘yxati';

-- ---------------------------------------------------------------------------
-- Navbatga qo‘shish (dedupe bilan)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.enqueue_notification_event(
  p_type text,
  p_target_user_id text,
  p_order_id text,
  p_payload jsonb,
  p_dedupe_key text DEFAULT NULL,
  p_scheduled_at timestamptz DEFAULT now()
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
BEGIN
  IF p_dedupe_key IS NOT NULL AND length(trim(p_dedupe_key)) > 0 THEN
    BEGIN
      INSERT INTO public.push_notification_dedup (dedupe_key)
      VALUES (trim(p_dedupe_key));
    EXCEPTION
      WHEN unique_violation THEN
        RETURN NULL;
    END;
  END IF;

  INSERT INTO public.notification_events (
    type, target_user_id, order_id, payload, dedupe_key, scheduled_at
  ) VALUES (
    trim(p_type),
    NULLIF(trim(both FROM p_target_user_id), ''),
    NULLIF(trim(both FROM p_order_id), ''),
    COALESCE(p_payload, '{}'::jsonb),
    NULLIF(trim(both FROM p_dedupe_key), ''),
    COALESCE(p_scheduled_at, now())
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.enqueue_notification_event(text, text, text, jsonb, text, timestamptz) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.enqueue_notification_event(text, text, text, jsonb, text, timestamptz) TO anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Client: token ro‘yxatdan o‘tkazish / o‘chirish
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.register_push_device_token(
  p_user_id text,
  p_token text,
  p_platform text,
  p_device_id text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid text := trim(both FROM p_user_id);
  v_tok text := trim(both FROM p_token);
  v_plat text := lower(trim(both FROM p_platform));
  v_dev text := trim(both FROM COALESCE(p_device_id, ''));
BEGIN
  IF v_uid = '' OR v_tok = '' THEN
    RAISE EXCEPTION 'invalid_token_or_user';
  END IF;
  IF v_plat NOT IN ('android', 'ios', 'web', 'unknown') THEN
    v_plat := 'unknown';
  END IF;

  INSERT INTO public.user_device_tokens (
    user_id, token, platform, device_id, is_active, updated_at
  ) VALUES (
    v_uid, v_tok, v_plat, v_dev, true, now()
  )
  ON CONFLICT (token) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    platform = EXCLUDED.platform,
    device_id = EXCLUDED.device_id,
    is_active = true,
    updated_at = now();
END;
$$;

CREATE OR REPLACE FUNCTION public.deactivate_push_device_token(
  p_user_id text,
  p_device_id text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.user_device_tokens
  SET is_active = false, updated_at = now()
  WHERE user_id = trim(both FROM p_user_id)
    AND device_id = trim(both FROM COALESCE(p_device_id, ''));
END;
$$;

CREATE OR REPLACE FUNCTION public.deactivate_push_token_by_value(p_token text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.user_device_tokens
  SET is_active = false, updated_at = now()
  WHERE token = trim(both FROM p_token);
END;
$$;

REVOKE ALL ON FUNCTION public.register_push_device_token(text, text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.register_push_device_token(text, text, text, text) TO anon, authenticated, service_role;

REVOKE ALL ON FUNCTION public.deactivate_push_device_token(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.deactivate_push_device_token(text, text) TO anon, authenticated, service_role;

REVOKE ALL ON FUNCTION public.deactivate_push_token_by_value(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.deactivate_push_token_by_value(text) TO anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Trigger yordamchilari: orders
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.trg_orders_push_lifecycle()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_old_lead text;
  v_new_lead text;
  v_bidder text;
  v_dedupe text;
BEGIN
  -- Auksion: yetakchi o‘zgarganda oldingi kuryer "outbid"
  IF TG_OP = 'UPDATE' AND NEW.status = 'auction_live' THEN
    v_old_lead := NULLIF(trim(both FROM COALESCE(OLD.leading_courier_id, '')), '');
    v_new_lead := NULLIF(trim(both FROM COALESCE(NEW.leading_courier_id, '')), '');
    IF v_old_lead IS NOT NULL AND v_new_lead IS NOT NULL AND v_old_lead <> v_new_lead THEN
      v_dedupe := 'outbid|' || NEW.id::text || '|' || v_old_lead || '|' ||
        to_char(date_trunc('minute', now()), 'YYYYMMDDHH24MI');
      PERFORM public.enqueue_notification_event(
        'auction_outbid',
        v_old_lead,
        NEW.id::text,
        jsonb_build_object('order_id', NEW.id::text, 'route', 'auction'),
        v_dedupe,
        now()
      );
    END IF;
  END IF;

  IF TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status THEN
    -- G‘olib tanlandi
    IF NEW.status = 'assigned'
       AND NULLIF(trim(both FROM COALESCE(NEW.winner_courier_id, '')), '') IS NOT NULL THEN
      PERFORM public.enqueue_notification_event(
        'winner_selected',
        NULLIF(trim(both FROM NEW.sender_id), ''),
        NEW.id::text,
        jsonb_build_object('order_id', NEW.id::text, 'route', 'job'),
        'winner_sender|' || NEW.id::text,
        now()
      );

      PERFORM public.enqueue_notification_event(
        'auction_won',
        NULLIF(trim(both FROM NEW.winner_courier_id), ''),
        NEW.id::text,
        jsonb_build_object('order_id', NEW.id::text, 'route', 'job'),
        'auction_won|' || NEW.id::text || '|' || trim(both FROM NEW.winner_courier_id),
        now()
      );

      FOR v_bidder IN
        SELECT DISTINCT trim(both FROM courier_id)
        FROM public.bids
        WHERE order_id = NEW.id AND trim(both FROM courier_id) <> trim(both FROM NEW.winner_courier_id)
      LOOP
        IF v_bidder IS NULL OR v_bidder = '' THEN
          CONTINUE;
        END IF;
        PERFORM public.enqueue_notification_event(
          'auction_lost',
          v_bidder,
          NEW.id::text,
          jsonb_build_object('order_id', NEW.id::text, 'route', 'auction'),
          'auction_lost|' || NEW.id::text || '|' || v_bidder,
          now()
        );
      END LOOP;
    END IF;

    IF NEW.status = 'picked_up' THEN
      PERFORM public.enqueue_notification_event(
        'order_picked_up',
        NULLIF(trim(both FROM NEW.sender_id), ''),
        NEW.id::text,
        jsonb_build_object('order_id', NEW.id::text, 'route', 'job'),
        'picked_up|' || NEW.id::text,
        now()
      );
    END IF;

    IF NEW.status = 'delivered' THEN
      PERFORM public.enqueue_notification_event(
        'order_delivered',
        NULLIF(trim(both FROM NEW.sender_id), ''),
        NEW.id::text,
        jsonb_build_object('order_id', NEW.id::text, 'route', 'job'),
        'delivered|' || NEW.id::text,
        now()
      );
    END IF;

    IF NEW.status = 'completed' THEN
      PERFORM public.enqueue_notification_event(
        'feedback_reminder',
        NULLIF(trim(both FROM NEW.sender_id), ''),
        NEW.id::text,
        jsonb_build_object('order_id', NEW.id::text, 'route', 'feedback'),
        'fb_rem_s|' || NEW.id::text || '|' || trim(both FROM NEW.sender_id),
        now() + interval '2 hours'
      );
      IF NULLIF(trim(both FROM COALESCE(NEW.winner_courier_id, '')), '') IS NOT NULL THEN
        PERFORM public.enqueue_notification_event(
          'feedback_reminder',
          NULLIF(trim(both FROM NEW.winner_courier_id), ''),
          NEW.id::text,
          jsonb_build_object('order_id', NEW.id::text, 'route', 'feedback'),
          'fb_rem_c|' || NEW.id::text || '|' || trim(both FROM NEW.winner_courier_id),
          now() + interval '2 hours'
        );
      END IF;

      PERFORM public.enqueue_notification_event(
        'order_completed',
        NULLIF(trim(both FROM NEW.winner_courier_id), ''),
        NEW.id::text,
        jsonb_build_object('order_id', NEW.id::text, 'route', 'job'),
        'completed_courier|' || NEW.id::text,
        now()
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_orders_push_lifecycle ON public.orders;
CREATE TRIGGER trg_orders_push_lifecycle
  AFTER UPDATE ON public.orders
  FOR EACH ROW
  EXECUTE PROCEDURE public.trg_orders_push_lifecycle();

-- Birinchi kuryer auksionni boshlaganda yoki qadam — yuboruvchiga
CREATE OR REPLACE FUNCTION public.trg_bids_notify_sender()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sender text;
  v_order uuid;
BEGIN
  v_order := NEW.order_id;
  SELECT NULLIF(trim(both FROM sender_id), '') INTO v_sender
  FROM public.orders WHERE id = v_order LIMIT 1;

  IF v_sender IS NULL THEN
    RETURN NEW;
  END IF;

  -- Faqat birinchi taklifda yuboruvchiga ("auksionga kuryer kirdi")
  IF (SELECT COUNT(*)::int FROM public.bids WHERE order_id = v_order) <> 1 THEN
    RETURN NEW;
  END IF;

  PERFORM public.enqueue_notification_event(
    'auction_courier_joined',
    v_sender,
    v_order::text,
    jsonb_build_object(
      'order_id', v_order::text,
      'route', 'auction',
      'courier_id', trim(both FROM NEW.courier_id)
    ),
    'bid_first|' || v_order::text,
    now()
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_bids_notify_sender ON public.bids;
CREATE TRIGGER trg_bids_notify_sender
  AFTER INSERT ON public.bids
  FOR EACH ROW
  EXECUTE PROCEDURE public.trg_bids_notify_sender();

-- ---------------------------------------------------------------------------
-- order_feedback: shikoyat va past baho → admin
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.trg_order_feedback_admin_alerts()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  r record;
BEGIN
  IF NEW.feedback_type = 'complaint' THEN
    FOR r IN SELECT user_id FROM public.push_admin_recipients
    LOOP
      PERFORM public.enqueue_notification_event(
        'complaint_created',
        r.user_id,
        NEW.order_id,
        jsonb_build_object(
          'order_id', NEW.order_id,
          'route', 'admin_feedback',
          'feedback_id', NEW.id::text
        ),
        'complaint|' || NEW.id::text || '|' || r.user_id,
        now()
      );
    END LOOP;
  END IF;

  IF NEW.rating IS NOT NULL AND NEW.rating <= 2 THEN
    FOR r IN SELECT user_id FROM public.push_admin_recipients
    LOOP
      PERFORM public.enqueue_notification_event(
        'low_rating_alert',
        r.user_id,
        NEW.order_id,
        jsonb_build_object(
          'order_id', NEW.order_id,
          'route', 'admin_feedback',
          'rating', NEW.rating,
          'feedback_id', NEW.id::text
        ),
        'lowrating|' || NEW.id::text || '|' || r.user_id,
        now()
      );
    END LOOP;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_order_feedback_admin_alerts ON public.order_feedback;
CREATE TRIGGER trg_order_feedback_admin_alerts
  AFTER INSERT ON public.order_feedback
  FOR EACH ROW
  EXECUTE PROCEDURE public.trg_order_feedback_admin_alerts();

-- ---------------------------------------------------------------------------
-- RLS (vaqtincha ochiq — mavjud orders kabi keyin qat’iyroq)
-- ---------------------------------------------------------------------------
ALTER TABLE public.user_device_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.push_notifications_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.push_notification_dedup ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.push_admin_recipients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "push_tokens_allow_all" ON public.user_device_tokens FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "push_log_allow_all" ON public.push_notifications_log FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "push_events_allow_all" ON public.notification_events FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "push_dedup_allow_all" ON public.push_notification_dedup FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "push_admin_recipients_read" ON public.push_admin_recipients FOR SELECT USING (true);

COMMENT ON POLICY "push_tokens_allow_all" ON public.user_device_tokens IS 'TODO: faqat o‘z user_id yoki Edge Function';
