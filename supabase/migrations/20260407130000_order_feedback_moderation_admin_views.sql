-- Shikoyat moderatsiyasi (lokal SQLite v21 bilan mos).
-- Remote guard: faqat service_role yoki keyingi admin RPC orqali o‘qing (hozircha TODO).

ALTER TABLE public.order_feedback
  ADD COLUMN IF NOT EXISTS complaint_status text,
  ADD COLUMN IF NOT EXISTS admin_note text,
  ADD COLUMN IF NOT EXISTS reviewed_by text,
  ADD COLUMN IF NOT EXISTS reviewed_at timestamptz;

COMMENT ON COLUMN public.order_feedback.complaint_status IS 'new | reviewed | resolved (faqat shikoyatlar)';

-- Admin statistikasi (PostgREST orqali ochilmasin — RLS/privilege keyin sozlanadi).
CREATE OR REPLACE VIEW public.admin_order_stats_v AS
SELECT status::text AS code, count(*)::bigint AS c
FROM public.orders
GROUP BY status;

CREATE OR REPLACE VIEW public.admin_feedback_stats_v AS
SELECT
  count(*)::bigint AS total_feedback,
  avg(rating)::double precision AS avg_rating,
  count(*) FILTER (WHERE feedback_type = 'complaint')::bigint AS complaints,
  count(*) FILTER (WHERE feedback_type = 'praise')::bigint AS praises
FROM public.order_feedback;

CREATE OR REPLACE VIEW public.admin_region_stats_v AS
SELECT
  coalesce(nullif(trim(region_code), ''), '—') AS region_code,
  count(*)::bigint AS order_count
FROM public.orders
GROUP BY 1;

CREATE OR REPLACE VIEW public.admin_user_quality_v AS
SELECT
  to_user_id AS user_id,
  count(*)::bigint AS ratings_received,
  avg(rating)::double precision AS avg_rating_received,
  count(*) FILTER (WHERE feedback_type = 'complaint')::bigint AS complaints_received,
  count(*) FILTER (WHERE feedback_type = 'praise')::bigint AS praises_received
FROM public.order_feedback
GROUP BY 1;

COMMENT ON VIEW public.admin_order_stats_v IS 'Admin: buyurtmalar status bo‘yicha';
COMMENT ON VIEW public.admin_feedback_stats_v IS 'Admin: feedback yig‘indisi';
COMMENT ON VIEW public.admin_region_stats_v IS 'Admin: viloyat bo‘yicha buyurtmalar';
COMMENT ON VIEW public.admin_user_quality_v IS 'Admin: foydalanuvchi sifati (feedback tomondan)';
