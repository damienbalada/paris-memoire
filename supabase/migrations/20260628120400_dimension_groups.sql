-- =============================================================================
-- Migration 0005 : groupes de dimensions (méta-scores)
-- -----------------------------------------------------------------------------
-- Permet d'agréger plusieurs dimensions en un méta-score affiché.
-- Cas d'usage validé : "Bien-être du vivant" = bien-être animal (non-humain)
--   + travail/rémunération + chaîne d'appro/droits humains (bien-être humain).
-- Philosophie : les humains sont des animaux ; on couvre tout le vivant. Le
--   calcul reste séparé par dimension (normalisation intra-sujet correcte),
--   le méta-score n'est qu'une vue d'agrégation pondérée.
-- =============================================================================

create table dimension_groups (
  id            uuid primary key default gen_random_uuid(),
  code          text not null unique,
  name          text not null,
  description   text,
  display_order int not null default 0,
  created_at    timestamptz not null default now()
);

comment on table dimension_groups is
  'Méta-scores : regroupements de dimensions affichés au-dessus du détail (ex: "Bien-être du vivant").';

create table dimension_group_members (
  group_id     uuid not null references dimension_groups(id) on delete cascade,
  dimension_id uuid not null references dimensions(id) on delete cascade,
  weight       numeric(5,4) not null default 1.0 check (weight >= 0),
  primary key (group_id, dimension_id)
);

comment on table dimension_group_members is
  'Appartenance pondérée d''une dimension à un méta-score. Une dimension peut appartenir à plusieurs groupes.';

alter table dimension_groups        enable row level security;
alter table dimension_group_members enable row level security;
create policy "public read" on dimension_groups        for select using (true);
create policy "public read" on dimension_group_members for select using (true);
