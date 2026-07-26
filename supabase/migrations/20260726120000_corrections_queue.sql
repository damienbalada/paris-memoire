-- =============================================================================
-- Signalements de correction (boucle de contribution publique)
-- -----------------------------------------------------------------------------
-- Un lecteur qui repère une donnée manquante, fausse, ou un lien mort peut le
-- signaler depuis la fiche. Un signalement N'EST PAS une preuve :
--   * il n'entre JAMAIS dans un score ;
--   * il atterrit dans une file de revue humaine ;
--   * s'il est retenu, il donne lieu à une `evidence` distincte, avec sa propre
--     source et son propre tier (Règle : la parole d'un lecteur seule vaut
--     `crowd`, tier 0.30 — c'est une piste, pas une preuve).
--
-- Doctrine RLS inchangée : aucune policy => anon et authenticated ne peuvent ni
-- lire ni écrire. L'insertion passe par une Server Action (service_role), donc
-- la clé n'est jamais exposée au navigateur et on n'ouvre pas la table au web.
-- =============================================================================

create table if not exists corrections (
  id             uuid primary key default gen_random_uuid(),
  -- Slug libre (pas de FK) : un signalement peut viser une entité absente de la
  -- base, ce qui est en soi une information utile.
  entity_slug    text not null check (char_length(entity_slug) between 1 and 120),
  indicator_code text check (indicator_code is null or char_length(indicator_code) <= 60),
  kind           text not null check (kind in ('missing', 'wrong', 'dead_link', 'other')),
  message        text not null check (char_length(btrim(message)) between 10 and 2000),
  -- Une source est facultative, mais si elle est fournie elle doit être une URL.
  source_url     text check (source_url is null or source_url ~ '^https?://'),
  -- Contact facultatif : on ne le réclame pas (pas de collecte inutile).
  contact        text check (contact is null or char_length(contact) <= 200),
  status         text not null default 'pending'
                   check (status in ('pending', 'accepted', 'rejected')),
  reviewer_note  text,
  created_at     timestamptz not null default now()
);

create index if not exists corrections_status_idx on corrections(status, created_at);
create index if not exists corrections_entity_idx on corrections(entity_slug);

alter table corrections enable row level security;

comment on table corrections is
  'File de signalements publics. Jamais utilisée dans le calcul d''un score : '
  'un signalement retenu doit être converti en evidence sourcée.';
