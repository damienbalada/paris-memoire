-- =============================================================================
-- Migration 0004 : Row Level Security
-- -----------------------------------------------------------------------------
-- Principe : tout le contenu publié est public en lecture (transparence), mais
--   * l'evidence n'est lisible publiquement QUE si review_status = 'approved'
--     (la file de curation humaine reste privée jusqu'à validation) ;
--   * aucune écriture via les clés anon/authenticated : l'ingestion passe par
--     la service_role (pipeline Python / back-office), qui contourne la RLS.
-- =============================================================================

-- Activer la RLS partout.
alter table sectors                enable row level security;
alter table dimensions             enable row level security;
alter table entities               enable row level security;
alter table indicators             enable row level security;
alter table sources                enable row level security;
alter table evidence               enable row level security;
alter table value_profiles         enable row level security;
alter table profile_weights        enable row level security;
alter table source_tier_config     enable row level security;
alter table evidence_nature_config enable row level security;
alter table scoring_params         enable row level security;

-- Lecture publique des tables de référence (faits, pas jugements).
create policy "public read" on sectors                for select using (true);
create policy "public read" on dimensions             for select using (true);
create policy "public read" on entities               for select using (true);
create policy "public read" on indicators             for select using (true);
create policy "public read" on sources                for select using (true);
create policy "public read" on value_profiles         for select using (true);
create policy "public read" on profile_weights        for select using (true);
create policy "public read" on source_tier_config     for select using (true);
create policy "public read" on evidence_nature_config for select using (true);
create policy "public read" on scoring_params         for select using (true);

-- Evidence : seules les evidence approuvées sont publiques.
create policy "public read approved" on evidence
  for select using (review_status = 'approved');

-- NB : aucune policy d'INSERT/UPDATE/DELETE => refus par défaut pour anon et
-- authenticated. Les écritures se font via la service_role (back-office /
-- pipeline) qui bypass la RLS.
