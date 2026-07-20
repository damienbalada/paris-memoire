-- =============================================================================
-- Module « DIAMS Civique » — cartographie des votes des groupes politiques.
-- -----------------------------------------------------------------------------
-- Principe : on ne NOTE pas les partis. On rattache à chaque pilier DIAMS des
-- VOTES réels par appel nominal (faits datés, sourcés, cliquables) et on montre
-- la position de chaque groupe. L'utilisateur pondère via ses curseurs de
-- profil : DIAMS ne classe personne. Module isolé (n'affecte pas les marques).
-- =============================================================================

create table if not exists political_groups (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null,
  short_name text not null,
  chamber text not null default 'EP',   -- EP (Parlement européen), AN, SENAT…
  seats int,
  ordinal int not null default 0,        -- ordre d'affichage (gauche→droite indicatif)
  created_at timestamptz not null default now()
);

create table if not exists civic_votes (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  title text not null,
  vote_date date not null,
  pillar_code text not null,             -- dimensions.code (ex : 'ENV')
  chamber text not null default 'EP',
  source_url text not null,              -- lien vers le scrutin / communiqué officiel
  alignment_note text,                   -- ce que « pour » signifie au regard du pilier
  total_for int,
  total_against int,
  total_abstain int,
  created_at timestamptz not null default now()
);

create table if not exists civic_positions (
  id uuid primary key default gen_random_uuid(),
  vote_id uuid not null references civic_votes(id) on delete cascade,
  group_id uuid not null references political_groups(id) on delete cascade,
  stance text not null check (stance in ('for','against','split','abstain')),
  n_for int, n_against int, n_abstain int,   -- décompte exact si connu (sinon null)
  note text,
  source_url text,
  unique (vote_id, group_id)
);

-- Lecture publique (comme les autres tables du projet), écriture réservée au service.
alter table political_groups enable row level security;
alter table civic_votes      enable row level security;
alter table civic_positions  enable row level security;
create policy "public read" on political_groups for select using (true);
create policy "public read" on civic_votes      for select using (true);
create policy "public read" on civic_positions  for select using (true);
