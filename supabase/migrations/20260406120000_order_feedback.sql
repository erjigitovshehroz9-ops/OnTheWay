-- Order feedback: rating + optional complaint/praise (completed orders only).
-- TODO(security): qat’iy RLS va moderation workflow.

CREATE TABLE IF NOT EXISTS public.order_feedback (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id text NOT NULL,
  from_user_id text NOT NULL,
  to_user_id text NOT NULL,
  from_role text NOT NULL,
  to_role text NOT NULL,
  rating integer NOT NULL,
  feedback_type text NOT NULL,
  complaint_category text,
  praise_category text,
  comment text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT order_feedback_rating_check CHECK (rating >= 1 AND rating <= 5),
  CONSTRAINT order_feedback_type_check CHECK (feedback_type IN ('rating', 'complaint', 'praise')),
  CONSTRAINT order_feedback_roles_from_check CHECK (from_role IN ('sender', 'courier')),
  CONSTRAINT order_feedback_roles_to_check CHECK (to_role IN ('sender', 'courier')),
  CONSTRAINT order_feedback_unique_from UNIQUE (order_id, from_user_id),
  CONSTRAINT order_feedback_categories_check CHECK (
    (feedback_type = 'rating' AND complaint_category IS NULL AND praise_category IS NULL)
    OR (feedback_type = 'complaint' AND praise_category IS NULL)
    OR (feedback_type = 'praise' AND complaint_category IS NULL)
  )
);

CREATE INDEX IF NOT EXISTS idx_order_feedback_order_id ON public.order_feedback (order_id);
CREATE INDEX IF NOT EXISTS idx_order_feedback_to_user ON public.order_feedback (to_user_id);
CREATE INDEX IF NOT EXISTS idx_order_feedback_from_user ON public.order_feedback (from_user_id);
CREATE INDEX IF NOT EXISTS idx_order_feedback_created_at ON public.order_feedback (created_at DESC);

COMMENT ON TABLE public.order_feedback IS 'Buyurtma yakunidan keyin bitta tomondan bitta feedback; shikoyat/muammo moderatsiya uchun.';

-- Atomik yozuv: faqat completed, faqat sender<->g‘olib kuryer.
CREATE OR REPLACE FUNCTION public.submit_order_feedback(
  p_order_id text,
  p_to_user_id text,
  p_rating integer,
  p_feedback_type text,
  p_complaint_category text DEFAULT NULL,
  p_praise_category text DEFAULT NULL,
  p_comment text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row public.orders%ROWTYPE;
  v_from text := trim(both from auth.uid()::text);
  v_to text := trim(both from p_to_user_id);
  v_oid text := trim(both from p_order_id);
  v_ft text := lower(trim(both from p_feedback_type));
  v_from_role text;
  v_to_role text;
  v_new_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_authenticated');
  END IF;

  IF p_rating IS NULL OR p_rating < 1 OR p_rating > 5 THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_rating');
  END IF;

  IF v_ft NOT IN ('rating', 'complaint', 'praise') THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_feedback_type');
  END IF;

  SELECT * INTO v_row FROM public.orders o WHERE o.id::text = v_oid LIMIT 1;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_found');
  END IF;

  IF trim(both from coalesce(v_row.status, '')) <> 'completed' THEN
    RETURN jsonb_build_object('ok', false, 'error', 'order_not_completed', 'status', v_row.status);
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.order_feedback f
    WHERE f.order_id = v_oid AND f.from_user_id = v_from
  ) THEN
    RETURN jsonb_build_object('ok', false, 'error', 'duplicate');
  END IF;

  IF v_row.sender_id IS NULL OR trim(both from v_row.sender_id) = ''
     OR v_row.winner_courier_id IS NULL OR trim(both from v_row.winner_courier_id) = '' THEN
    RETURN jsonb_build_object('ok', false, 'error', 'missing_parties');
  END IF;

  IF v_from = trim(both from v_row.sender_id) THEN
    IF v_to <> trim(both from v_row.winner_courier_id) THEN
      RETURN jsonb_build_object('ok', false, 'error', 'sender_must_rate_winner');
    END IF;
    v_from_role := 'sender';
    v_to_role := 'courier';
  ELSIF v_from = trim(both from v_row.winner_courier_id) THEN
    IF v_to <> trim(both from v_row.sender_id) THEN
      RETURN jsonb_build_object('ok', false, 'error', 'courier_must_rate_sender');
    END IF;
    v_from_role := 'courier';
    v_to_role := 'sender';
  ELSE
    RETURN jsonb_build_object('ok', false, 'error', 'forbidden');
  END IF;

  INSERT INTO public.order_feedback (
    order_id, from_user_id, to_user_id, from_role, to_role,
    rating, feedback_type, complaint_category, praise_category, comment
  ) VALUES (
    v_oid, v_from, v_to, v_from_role, v_to_role,
    p_rating, v_ft, p_complaint_category, p_praise_category, p_comment
  )
  RETURNING id INTO v_new_id;

  RETURN jsonb_build_object('ok', true, 'id', v_new_id::text);

END;
$$;

REVOKE ALL ON FUNCTION public.submit_order_feedback(text, text, integer, text, text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_order_feedback(text, text, integer, text, text, text, text) TO authenticated;

-- Reputatsiya: agregat (profil / debug).
CREATE OR REPLACE FUNCTION public.get_user_feedback_summary(p_user_id text)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT jsonb_build_object(
    'average_rating', COALESCE(ROUND(AVG(rating)::numeric, 2), 0),
    'total_ratings', COUNT(*)::int,
    'total_complaints', COUNT(*) FILTER (WHERE feedback_type = 'complaint')::int,
    'total_praises', COUNT(*) FILTER (WHERE feedback_type = 'praise')::int
  )
  FROM public.order_feedback
  WHERE to_user_id = trim(both from p_user_id);
$$;

REVOKE ALL ON FUNCTION public.get_user_feedback_summary(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_user_feedback_summary(text) TO authenticated;

-- TODO(RLS): ALTER TABLE order_feedback ENABLE ROW LEVEL SECURITY;
-- Policy: SELECT where auth.uid() = from_user_id OR to_user_id; INSERT revoked for authenticated (faqat RPC).
