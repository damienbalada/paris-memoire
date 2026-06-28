-- =============================================================================
-- Awareness Score — Moteur de score éthique d'entreprise
-- Migration 0001 : extensions, enums et tables cœur
-- -----------------------------------------------------------------------------
-- Principes structurants (cf. METHODOLOGY.md) :
--   * Résolution d'entités d'abord (marque -> filiale -> groupe, % détention).
--   * Chaque point de score = une evidence sourcée et datée.
--   * Décroissance à 5 ans : valid_until = observed_on + 5 ans (généré).
--   * Faits séparés des jugements : on stocke des indicateurs factuels
--     normalisés ; la pondération est appliquée APRÈS via des profils.
--   * Indice de confiance séparé du score.
--   * Le "tier" de la source conditionne le poids de l'evidence.
-- =============================================================================

create extension if not exists "pgcrypto";   -- gen_random_uuid()

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------

-- Nature de l'indicateur (type de valeur attendue)
create type indicator_kind as enum (
  'quantitative',   -- valeur numérique continue (ratio, montant, score /n)
  'categorical',    -- ensemble de catégories ordonnables ou non
  'binary',         -- vrai / faux
  'ordinal'         -- échelle ordonnée (ex: tiers BBFAW 1..6, note CDP A..D-)
);

-- Sens "favorable" de l'indicateur
create type indicator_direction as enum (
  'higher_better',  -- plus la valeur est haute, mieux c'est (% admin. indépendants)
  'lower_better',   -- plus la valeur est basse, mieux c'est (ratio CEO/médian)
  'contextual'      -- affiché mais pas directement scoré (ex: dépenses lobbying)
);

-- Tier de fiabilité de la source — pilier anti-greenwashing / anti-erreur.
-- regulatory = obligation légale (CSRD, devoir de vigilance) -> tier 1.
-- audited_ngo = ONG/index auditée (FTI, KnowTheChain, BBFAW)   -> tier 2.
-- press       = presse, allégations                            -> tier 3.
-- crowd       = contributif / militant non audité (PETA)       -> tier 3 bas.
create type source_tier as enum (
  'regulatory',
  'audited_ngo',
  'press',
  'crowd'
);

-- Nature de l'evidence — distingue promesse et résultat (anti-greenwashing).
create type evidence_nature as enum (
  'result',       -- résultat mesuré et vérifiable
  'commitment',   -- engagement / promesse future
  'policy',       -- politique formalisée (sans résultat prouvé)
  'controversy'   -- controverse / allégation
);

-- Type de la valeur stockée dans evidence (la valeur factuelle brute).
create type value_type as enum (
  'numeric',
  'boolean',
  'ordinal',
  'category'
);

-- Statut de curation humaine (file de révision avant publication).
create type review_status as enum (
  'pending',
  'approved',
  'rejected'
);

-- ---------------------------------------------------------------------------
-- Secteurs (normalisation intra-secteur)
-- ---------------------------------------------------------------------------
create table sectors (
  id          uuid primary key default gen_random_uuid(),
  code        text not null unique,
  name        text not null,
  description text,
  created_at  timestamptz not null default now()
);

comment on table sectors is
  'Secteurs d''activité. La normalisation des indicateurs se fait à l''intérieur d''un même secteur (comparer une banque et un maroquinier sur le bien-être animal n''a pas de sens).';

-- ---------------------------------------------------------------------------
-- Dimensions (les grands axes éthiques)
-- ---------------------------------------------------------------------------
create table dimensions (
  id             uuid primary key default gen_random_uuid(),
  code           text not null unique,
  name           text not null,
  description    text,
  -- Poids "par défaut" indicatif ; les vrais poids viennent des profils.
  default_weight numeric(5,4) not null default 0.125 check (default_weight >= 0),
  display_order  int not null default 0,
  created_at     timestamptz not null default now()
);

comment on table dimensions is
  'Axes de notation (environnement, travail, chaîne d''appro, etc.). La pondération réelle est portée par profile_weights, pas ici.';

-- ---------------------------------------------------------------------------
-- Entités (résolution d'entités : marque -> filiale -> groupe)
-- ---------------------------------------------------------------------------
create table entities (
  id            uuid primary key default gen_random_uuid(),
  slug          text not null unique,
  legal_name    text not null,
  display_name  text,                       -- nom de marque grand public
  -- Résolution d'entités
  parent_id     uuid references entities(id) on delete set null,
  ownership_pct numeric(5,2)
                  check (ownership_pct is null or (ownership_pct >= 0 and ownership_pct <= 100)),
  -- Identifiants officiels (ancrage entité)
  lei           text,                        -- GLEIF Legal Entity Identifier
  siren         text,                        -- SIRENE / INPI (France)
  country       text,                        -- ISO 3166-1 alpha-2
  sector_id     uuid references sectors(id),
  is_brand      boolean not null default false,  -- true = marque, false = groupe/holding
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  constraint entities_not_self_parent check (parent_id is null or parent_id <> id)
);

comment on table entities is
  'Entités juridiques et marques. La hiérarchie parent_id + ownership_pct est le SOCLE : sans elle, un score de marque (ex: Bottega) ne remonte pas au bon groupe (Kering).';
comment on column entities.ownership_pct is
  'Pourcentage de détention de cette entité par son parent_id (0-100).';

create index entities_parent_id_idx on entities(parent_id);
create index entities_sector_id_idx on entities(sector_id);
create index entities_lei_idx on entities(lei) where lei is not null;
create index entities_siren_idx on entities(siren) where siren is not null;

-- ---------------------------------------------------------------------------
-- Indicateurs (faits normalisables, rattachés à une dimension)
-- ---------------------------------------------------------------------------
create table indicators (
  id                 uuid primary key default gen_random_uuid(),
  code               text not null unique,
  dimension_id       uuid not null references dimensions(id),
  name               text not null,
  kind               indicator_kind not null,
  direction          indicator_direction not null,
  -- Spécificité sectorielle (ex: bien-être animal -> mode/cuir uniquement)
  sector_specific    boolean not null default false,
  applies_to_sector_id uuid references sectors(id),  -- non null si sector_specific
  -- Poids de l'indicateur À L'INTÉRIEUR de sa dimension
  weight             numeric(5,4) not null default 1.0 check (weight >= 0),
  unit               text,                            -- '%', 'ratio', 'count', 'score/250'...
  methodology        text,                            -- comment on normalise (texte court)
  created_at         timestamptz not null default now(),
  constraint indicators_sector_specific_consistent
    check (not sector_specific or applies_to_sector_id is not null)
);

comment on table indicators is
  'Indicateurs factuels. On stocke le fait normalisé ; le jugement (pondération) est appliqué après via les profils.';

create index indicators_dimension_id_idx on indicators(dimension_id);

-- ---------------------------------------------------------------------------
-- Sources (avec leur tier de fiabilité)
-- ---------------------------------------------------------------------------
create table sources (
  id          uuid primary key default gen_random_uuid(),
  code        text not null unique,
  name        text not null,
  tier        source_tier not null,
  publisher   text,
  url         text,
  description text,
  created_at  timestamptz not null default now()
);

comment on table sources is
  'Registre des sources. Le tier conditionne le poids et le plafond de confiance des evidence rattachées (anti-erreur "99% Républicain sans justification").';

-- ---------------------------------------------------------------------------
-- Evidence (le cœur : un fait sourcé, daté, typé, à durée de vie 5 ans)
-- ---------------------------------------------------------------------------
create table evidence (
  id              uuid primary key default gen_random_uuid(),
  entity_id       uuid not null references entities(id) on delete cascade,
  indicator_id    uuid not null references indicators(id),
  source_id       uuid not null references sources(id),
  -- Valeur factuelle typée (une seule colonne remplie selon value_type)
  value_type      value_type not null,
  value_numeric   numeric,
  value_boolean   boolean,
  value_text      text,        -- pour ordinal/category (libellé brut, ex: 'A-', 'Tier 3')
  -- Valeur normalisée [0,1] (calculée à l'ingestion ou par l'Edge Function)
  normalized_value numeric(6,5)
                    check (normalized_value is null or (normalized_value >= 0 and normalized_value <= 1)),
  -- Anti-greenwashing : nature de la preuve
  nature          evidence_nature not null,
  -- Datation et décroissance à 5 ans
  observed_on     date not null,
  valid_until     date generated always as (observed_on + interval '5 years') stored,
  -- Confiance au niveau de l'evidence [0,1]
  confidence      numeric(4,3) not null default 0.5
                    check (confidence >= 0 and confidence <= 1),
  -- Traçabilité / curation humaine
  reviewer        text,
  review_status   review_status not null default 'pending',
  excerpt         text,        -- extrait cité de la source
  source_url      text,        -- lien direct, daté, cliquable depuis la fiche
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

comment on table evidence is
  'Cœur du système. Chaque point de score découle d''une evidence : entité + indicateur + source, valeur typée, datée (valid_until = +5 ans), nature (result/commitment/policy/controversy), confiance, et lien cliquable.';

create index evidence_entity_id_idx on evidence(entity_id);
create index evidence_indicator_id_idx on evidence(indicator_id);
create index evidence_source_id_idx on evidence(source_id);
create index evidence_valid_until_idx on evidence(valid_until);
create index evidence_review_status_idx on evidence(review_status);

-- ---------------------------------------------------------------------------
-- Profils de valeurs + pondérations (le jugement, configurable)
-- ---------------------------------------------------------------------------
create table value_profiles (
  id          uuid primary key default gen_random_uuid(),
  code        text not null unique,
  name        text not null,
  description text,
  is_default  boolean not null default false,
  created_at  timestamptz not null default now()
);

comment on table value_profiles is
  'Profils de pondération (ex: "écolo", "droits humains d''abord", "équilibré"). Pas de score one-size-fits-all.';

create unique index value_profiles_one_default_idx
  on value_profiles((is_default)) where is_default;

create table profile_weights (
  id           uuid primary key default gen_random_uuid(),
  profile_id   uuid not null references value_profiles(id) on delete cascade,
  dimension_id uuid not null references dimensions(id) on delete cascade,
  weight       numeric(5,4) not null check (weight >= 0),
  unique (profile_id, dimension_id)
);

comment on table profile_weights is
  'Poids d''une dimension dans un profil donné. C''est ici que se règle le jugement, séparé des faits.';

-- ---------------------------------------------------------------------------
-- Trigger updated_at
-- ---------------------------------------------------------------------------
create or replace function set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger entities_set_updated_at
  before update on entities
  for each row execute function set_updated_at();

create trigger evidence_set_updated_at
  before update on evidence
  for each row execute function set_updated_at();
