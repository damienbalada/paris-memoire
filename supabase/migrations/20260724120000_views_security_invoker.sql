-- =============================================================================
-- Sécurité : passer les vues publiques en SECURITY INVOKER.
-- -----------------------------------------------------------------------------
-- Par défaut, une vue Postgres s'exécute avec les droits de son CRÉATEUR : elle
-- contourne donc la RLS de l'appelant (advisor Supabase « security_definer_view »,
-- niveau ERROR). Avec `security_invoker = true`, la vue applique les politiques
-- RLS de celui qui l'interroge — ce qu'on veut : `evidence` n'est lisible
-- publiquement qu'en statut `approved`, et la vue doit respecter cette règle
-- plutôt que de l'outrepasser.
-- Sans effet fonctionnel ici (evidence_active filtre déjà sur approved), mais
-- supprime le contournement latent et fait taire l'alerte.
-- =============================================================================

alter view public.evidence_active        set (security_invoker = true);
alter view public.brand_resolution_queue set (security_invoker = true);
