-- =============================================================================
-- Ingestion des MARQUES à l'échelle (Open Food Facts / Wikidata / GLEIF).
-- -----------------------------------------------------------------------------
-- Principe : l'ESG vit au niveau du GROUPE, la marque hérite (cf. Peugeot →
-- Stellantis). On ne cure donc pas des marques à la main : on ingère l'univers
-- des marques (Open Food Facts), on les rattache à un groupe existant
-- (Wikidata/GLEIF + matching de noms), et la marque hérite des preuves du groupe.
--
-- Trois tables :
--   1. staging_brands    : zone d'atterrissage brute d'un catalogue externe.
--   2. entity_aliases    : noms alternatifs d'une entité, pour le matching.
--   3. brand_resolutions : rattachement proposé marque→groupe + FILE DE REVUE.
--        Rien n'entre dans `entities` sans validation humaine (status=approved).
-- =============================================================================

create table if not exists staging_brands (
  id uuid primary key default gen_random_uuid(),
  source        text not null,            -- 'openfoodfacts', 'openbeautyfacts', ...
  source_ref    text not null,            -- identifiant stable dans la source (tag marque)
  name          text not null,            -- nom d'affichage de la marque
  owner_raw     text,                     -- brand_owner tel que fourni (bruité)
  sector_guess  text,                     -- code secteur DIAMS déduit des catégories (nullable)
  country       text,                     -- pays principal (ex: 'en:france')
  product_count int,                      -- proxy de popularité (nb de produits)
  payload       jsonb,                    -- enregistrement brut (audit)
  imported_at   timestamptz not null default now(),
  unique (source, source_ref)
);
create index if not exists staging_brands_popularity on staging_brands (product_count desc nulls last);

create table if not exists entity_aliases (
  id        uuid primary key default gen_random_uuid(),
  entity_id uuid not null references entities(id) on delete cascade,
  alias     text not null,
  norm      text not null,                -- forme normalisée (matching exact)
  source    text,                         -- provenance de l'alias
  unique (entity_id, norm)
);
create index if not exists entity_aliases_norm on entity_aliases (norm);

create table if not exists brand_resolutions (
  id               uuid primary key default gen_random_uuid(),
  staging_brand_id uuid not null references staging_brands(id) on delete cascade,
  brand_name       text not null,         -- dénormalisé pour la file de revue
  group_slug       text,                  -- groupe propriétaire proposé (entité existante)
  method           text not null,         -- exact_alias | off_owner | wikidata | gleif | manual | none
  confidence       numeric,               -- 0..1
  status           text not null default 'pending'
                     check (status in ('pending','approved','rejected')),
  entity_id        uuid references entities(id),  -- entité marque créée à l'approbation
  reviewer         text,
  note             text,
  created_at       timestamptz not null default now(),
  unique (staging_brand_id)
);
create index if not exists brand_resolutions_status on brand_resolutions (status);

-- File de revue : rattachements en attente, les plus vendus d'abord.
create or replace view brand_resolution_queue as
  select br.id, br.brand_name, br.group_slug, br.method, br.confidence,
         sb.source, sb.sector_guess, sb.country, sb.product_count
  from brand_resolutions br
  join staging_brands sb on sb.id = br.staging_brand_id
  where br.status = 'pending'
  order by sb.product_count desc nulls last;

-- Lecture publique (cohérent avec le reste ; l'écriture passe par la clé service).
alter table staging_brands    enable row level security;
alter table entity_aliases    enable row level security;
alter table brand_resolutions enable row level security;
create policy "public read" on staging_brands    for select using (true);
create policy "public read" on entity_aliases    for select using (true);
create policy "public read" on brand_resolutions for select using (true);
