-- Supabase SQL Editor’da ishga tushiring.

-- 1) Funksiya mavjudligi
SELECT proname, pg_get_function_identity_arguments(p.oid) AS args, n.nspname AS schema
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND proname IN ('finalize_expired_auctions', 'start_or_step_auction')
ORDER BY proname;

-- 2) PostgREST ko‘rinishi uchun EXECUTE huquqi (authenticated JWT bilan chaqiriladi)
SELECT
  p.proname,
  has_function_privilege('authenticated', p.oid, 'EXECUTE') AS authenticated_can_execute
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN ('finalize_expired_auctions', 'start_or_step_auction');

-- 3) Qo‘lda cache yangilash (Dashboard’da ham “Reload schema” bor)
NOTIFY pgrst, 'reload schema';
