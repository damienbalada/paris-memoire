# DIAMS

> **DIAMS** — **D**ocumented, **I**ndependent, **A**uditable, **M**ulti-criteria **S**coring.

Moteur de notation **éthique** des entreprises, multi-critères et **traçable** —
un « B Corp élargi » couvrant environnement, travail/rémunération, chaîne
d'approvisionnement, bien-être animal (humain et non-humain), prises de
position/géopolitique, fiscalité et gouvernance.

Ce qui nous différencie n'est pas la techno mais la **fiabilité** :
résolution d'entités d'abord, chaque point de score adossé à une **preuve
sourcée et datée**, décroissance à 5 ans, faits séparés des jugements, indice de
confiance affiché à part du score, et anti-greenwashing explicite.

👉 Méthodologie publique : [`METHODOLOGY.md`](./METHODOLOGY.md)

## Périmètre de départ

**Luxe / Mode, France + UE** — parce que les obligations légales FR/UE (devoir
de vigilance, CSRD) fournissent de la donnée structurée que les outils US n'ont
jamais eue.

## Architecture

```
diams/
├─ apps/web/            # Next.js (App Router) — fiche entreprise + sliders
├─ supabase/
│  ├─ migrations/       # schéma versionné (source de vérité)
│  ├─ seed/             # données de départ (dimensions, indicateurs, sources, entités)
│  └─ functions/        # Edge Functions (compute_score)
├─ pipeline/            # collecte Python (APIs + scraping) + curation humaine
├─ packages/shared/     # types partagés (générés depuis Supabase)
└─ docs/                # data model, registre des sources
```

## Stack

- **Front** : Next.js (App Router).
- **Données** : Supabase (Postgres).
- **Scoring** : Edge Functions Supabase (pas de logique de score en SQL brut).
- **Collecte** : pipeline Python avec révision humaine avant publication.

## Modèle de données (résumé)

`sectors`, `entities` (auto-référence parent + `ownership_pct` + LEI/SIREN +
secteur), `dimensions`, `indicators`, `sources` (avec `tier` de fiabilité),
`evidence` (cœur : entité + indicateur + source, valeur typée, `observed_on`,
`valid_until` = +5 ans, `nature`, `confidence`, reviewer, extrait + URL),
`value_profiles` + `profile_weights`. Config méthodo en base :
`source_tier_config`, `evidence_nature_config`, `scoring_params`. Vues :
`evidence_active`, `entity_coverage` (= indice de confiance).

## Base de données — appliquer le schéma

Migrations dans `supabase/migrations/` (ordre chronologique), puis seeds dans
`supabase/seed/` (ordre numérique 01 → 05) :

```bash
# via Supabase CLI
supabase db push
psql "$DATABASE_URL" -f supabase/seed/01_sectors_dimensions.sql
psql "$DATABASE_URL" -f supabase/seed/02_indicators.sql
psql "$DATABASE_URL" -f supabase/seed/03_sources.sql
psql "$DATABASE_URL" -f supabase/seed/04_entities_luxe.sql
psql "$DATABASE_URL" -f supabase/seed/05_value_profiles.sql
```

## Roadmap

- **Palier 1 — Fondations** *(en cours)* : migrations, résolution d'entités luxe,
  seed dimensions/indicateurs/sources.
- **Palier 2 — Scoring** : Edge Function `compute_score(entity, profile)`.
- **Palier 3 — Collecte** : connecteurs SIRENE/HATVP/GLEIF/Yale puis scraping
  (FTI, plans de vigilance) + file de révision humaine.
- **Palier 4 — Front** : fiche entreprise transparente + sliders de pondération.
