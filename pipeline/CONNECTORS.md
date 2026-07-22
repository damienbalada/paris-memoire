# Connecteurs d'ingestion — guide opérateur

> Comment les faits entrent dans DIAMS. Chaque connecteur est du **code pur et
> déterministe** (parsing + normalisation + rapprochement de noms) : **0 token de
> modèle**, coût indépendant du nombre de marques. Tout est écrit en `pending` —
> revue humaine obligatoire avant qu'une preuve compte dans un score.

## Synthèse — quel CSV pour quel connecteur

| Pilier | Commande | Colonne(s) clé du CSV | Indicateur(s) |
|---|---|---|---|
| ENV / WAT | `import_cdp --file cdp.csv` | `cdp_climate`, `cdp_water` (A..D-/F) | `ENV_CDP_CLIMATE`, `WAT_CDP` |
| ENV | `import_sbti --file sbti.csv` | `Company Name`, `Target Status` | `ENV_SBTI_VALIDATED` |
| PLA | `import_bffp --file bffp.csv` | `rank` ou `band` | `PLA_POLLUTER` (gate) |
| LAB | `import_egapro [--file egapro.csv]` | `siren`, `note` (ou API) | `LAB_EGAPRO_INDEX` |
| ANI / SUP | `import_benchmarks --benchmark {bbfaw\|knowthechain\|fti} --file …` | `tier` ou `score` | `ANI_BBFAW_TIER`, `SUP_KNOWTHECHAIN`, `SUP_FTI_SCORE` |
| GEO | `import_hatvp --file agora.json` | JSON AGORA | `GEO_LOBBYING_*` |
| GEO | `import_yale --file yale.csv` | grade A..F | `GEO_RUSSIA_EXIT` |
| TAX | `import_tax --file tax.csv` | `cbcr_published`, `effective_tax_rate`, `haven_entities` | `TAX_*` |
| GOV | `import_governance --file gov.csv` | `women_share`, `independent_share` | `GOV_BOARD_*` |
| INV | `import_investments --file inv.csv` | `responsible_policy`, `fossil_financing`, … | `INV_*` |

(Toutes les commandes : `python -m paris_memoire.<commande>` ; ajouter `--apply` pour écrire.)
Détail de chaque connecteur ci-dessous.

## Invariants (tous connecteurs)

- **Rapprochement conservateur** (`normalize.names.is_strong_match`) : en cas de
  doute sur l'entité, on saute — jamais de devinette.
- **Écriture `pending`** (`load.insert_evidence`) : idempotent sur
  `(entity, indicator, source, observed_on)` ; relancer un import est sans effet.
- **Dry-run par défaut** : chaque `import_*` affiche ce qu'il ferait ; `--apply`
  écrit réellement.
- **Niveau de rattachement** : gouvernance / fiscalité / CDP au niveau **groupe**
  (les marques héritent) ; les benchmarks peuvent viser une **marque**.
- **Quantitatifs en valeur brute** : taux effectif et paradis fiscaux sont chargés
  sans `normalized_value` — le moteur (`scoring.ts`) calcule le percentile
  intra-secteur et applique la direction. Normaliser à la main fausserait la
  comparaison sectorielle.

Colonnes CSV **tolérantes à la casse** ; plusieurs alias acceptés par champ.
Colonne `source_url` facultative partout (sinon URL par défaut du connecteur).

---

## Environnement (ENV)

### CDP — notes climat & eau → `ENV_CDP_CLIMATE`, `WAT_CDP`
- CSV : `company` + `cdp_climate` et/ou `cdp_water` (lettre `A`, `A-`, … `D-`, `F`)
- Barème canonique : `A=1.00, A-=0.88, B=0.75, B-=0.63, C=0.50, C-=0.38, D=0.25, D-=0.13, F=0.00`
- Niveau : groupe · Source : `CDP` (écrit un ou deux indicateurs selon les colonnes présentes)
```bash
python -m paris_memoire.import_cdp --file cdp.csv [--apply]
```

### SBTi — objectifs climat validés → `ENV_SBTI_VALIDATED`
- Export « Companies taking action » (CSV) : `Company Name` + `Target Status` (+ `Target Classification`)
- `Targets Set` +1.5°C → 1.0 (résultat) ; `Committed` → promesse (plafonnée par le moteur) ; `Removed` → 0.0
- Niveau : groupe · Source : `SBTI`
```bash
python -m paris_memoire.import_sbti --file sbti.csv [--apply]
```

---

## Plastique (PLA)

### BFFP — pollueurs plastique → `PLA_POLLUTER` (gate)
- CSV : nom (`company`/`brand`) + `rank` (rang mondial) ou `band` (top3/top10/top50)
- ⚠️ **Gate écrit comme controverse** : `normalized_value` = **sévérité** (haute = fort
  pollueur). Le moteur en dérive le PLAFOND de la dimension via sa logique de
  controverse — `plafond ≈ 0.5×(1 − sévérité×poids_tier)` — donc plus la sévérité
  est haute, plus la note plastique est bridée. Ne PAS fournir un plafond direct.
- Barème rang → sévérité : `#1=0.90, #2=0.80, #3=0.75, top10=0.60, top50=0.45, au-delà=0.35`
- Niveau : groupe ou marque · Source : `BFFP`
```bash
python -m paris_memoire.import_bffp --file bffp.csv [--apply]
```

---

## Travail & Rémunération (LAB)

### Égapro — index égalité professionnelle F/H → `LAB_EGAPRO_INDEX`
- **Deux modes** : par défaut interroge l'open data ODS (`data.economie.gouv.fr`)
  pour les SIREN déjà renseignés en base (via `enrich_entities`) ; ou fallback
  **hors-ligne** `--file egapro.csv` (colonnes `siren` + `note`, + `annee`,
  `raison_sociale`) quand l'API n'est pas joignable.
- **Rapprochement par SIREN exact uniquement** — la donnée est indexée par SIREN ;
  pas de matching par nom (raisons sociales trop ambiguës). Garde l'année la plus récente.
- Normalisation : note / 100 · Niveau : entité portant le SIREN (groupe)
- Source : `EGAPRO` (réglementaire, Ministère du Travail)
```bash
python -m paris_memoire.import_egapro [--apply]                 # API ODS live
python -m paris_memoire.import_egapro --file egapro.csv [--apply]  # hors-ligne
```

---

## Gouvernance (GOV)

### `GOV_BOARD_GENDER` + `GOV_BOARD_INDEP`
- CSV : `company` + `women_share` (+ `independent_share`) — accepte `40`, `40 %`, `0.4`, `55,5`
- Mixité : parité (50 %) = 1.0, proportionnel en dessous, plafonné · Indépendance : part directe
- Niveau : groupe · Source : `CSRD_ESRS`
```bash
python -m paris_memoire.import_governance --file gov.csv [--apply]
```

---

## Fiscalité (TAX)

### `TAX_CBCR_PUBLISHED` + `TAX_EFFECTIVE_RATE` + `TAX_HAVEN_PRESENCE`
- CSV : `company` + au moins une de : `cbcr_published` (oui/non), `effective_tax_rate` (%), `haven_entities` (nb)
- CbCR normalisé ici (oui→1.0 / non→0.0) ; **taux effectif** (négatif autorisé) et **paradis fiscaux** en valeur brute (percentile par le moteur)
- Niveau : groupe · Sources : `CBCR`, `AMF`, `TAX_JUSTICE`
```bash
python -m paris_memoire.import_tax --file tax.csv [--apply]
```

---

## Benchmarks tiers (ANI, SUP)

Un seul CLI, sélection par `--benchmark` :

| `--benchmark` | Indicateur | Colonne valeur | Normalisation |
|---|---|---|---|
| `bbfaw` | `ANI_BBFAW_TIER` | `tier` (`Tier 6`, `6`…) | Tier 1→1.0 … Tier 6→0.10 |
| `knowthechain` | `SUP_KNOWTHECHAIN` | `score` (/100) | score / 100 |
| `fti` | `SUP_FTI_SCORE` | `score` (en %) | score / 100 |

- CSV : nom (`company`/`name`/`brand`) + colonne valeur ci-dessus
- Niveau : groupe **ou marque** (l'evidence se rattache à l'entité nommée)
```bash
python -m paris_memoire.import_benchmarks --benchmark bbfaw --file bbfaw.csv [--apply]
```

---

## Investissements & Finance éthique (INV)

### `INV_RESPONSIBLE_POLICY` · `INV_SUSTAINABLE_FINANCE` · `INV_FOSSIL_FINANCING` · `INV_CONTROVERSIAL_HOLDINGS`
- CSV : `company` + au moins une de : `responsible_policy` (none/policy/signatory),
  `sustainable_finance` (none/occasional/framework), `fossil_financing` (montant),
  `controversial_holdings` (nombre). Alias FR acceptés.
- Statuts normalisés ici (absent 0.0 / politique 0.5 / signataire 1.0) ; **fossile
  et participations en valeur brute** (percentile inversé `lower_better` par le moteur).
- Niveau : groupe · Sources : `UN_PRI` (politique / finance durable), `RECLAIM_FINANCE` (fossile / participations)
```bash
python -m paris_memoire.import_investments --file inv.csv [--apply]
```

---

## Géopolitique (GEO)

- **HATVP** (lobbying France) → `import_hatvp` · Source `HATVP`
- **Yale** (position Russie) → `import_yale` · Source `YALE_RUSSIA`

---

## Résolution d'entités & univers de marques

- **GLEIF / SIRENE** — LEI / SIREN (`connectors/gleif.py`, `connectors/sirene.py`)
- **Open Food Facts / Wikidata** — univers de marques + chaînes de détention.
  Voir [`BRAND_PIPELINE.md`](./BRAND_PIPELINE.md) pour le flux complet.

---

## Écrire un nouveau connecteur

1. `connectors/<source>.py` : **module pur** — `parse_csv()`, normalisation(s),
   `match_*()` conservateur. Aucun accès réseau/DB ici (testable hors ligne).
2. `import_<source>.py` : `build_rows(entities, records, observed_on)` → liste
   d'`EvidenceRow`, `main()` avec dry-run / `--apply`.
3. `tests/test_<source>.py` : parsing (formats + valeurs aberrantes),
   normalisation, matching conservateur, `build_rows` (bon niveau + indicateurs).
4. Recenser le connecteur dans `apps/web/lib/connectors.ts` (page `/pipeline`) et
   la section 7 de `METHODOLOGY.md`.
