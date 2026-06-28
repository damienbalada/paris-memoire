-- =============================================================================
-- Migration 0006 : durcissement sécurité (suite aux advisors Supabase)
-- -----------------------------------------------------------------------------
--   * Vues passées en security_invoker : elles appliquent la RLS de l'appelant
--     (anon ne voit que l'evidence approuvée), pas celle du créateur.
--   * search_path figé sur la fonction trigger (anti-injection via search_path).
-- =============================================================================

alter view evidence_active              set (security_invoker = true);
alter view entity_applicable_indicators set (security_invoker = true);
alter view entity_dimension_coverage    set (security_invoker = true);
alter view entity_coverage              set (security_invoker = true);

alter function set_updated_at() set search_path = '';
