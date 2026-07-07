# Pipeline de collecte — Awareness Score

Collecte et normalisation des données, avec revue humaine avant publication.
Premier module livré : **résolution d'entités** (LEI via GLEIF, SIREN via SIRENE).

## Installation

```bash
cd pipeline
python -m venv .venv && source .venv/bin/activate   # Windows : .venv\Scripts\activate
pip install -e ".[dev]"
```

## Tests (hors-ligne, sur fixtures)

```bash
pytest
```

## Enrichir les entités (LEI + SIREN)

```bash
cp .env.example .env        # renseigner SUPABASE_SERVICE_ROLE_KEY (secrète)

python -m paris_memoire.enrich_entities            # DRY-RUN : montre ce qui serait écrit
python -m paris_memoire.enrich_entities --apply     # écrit réellement en base
python -m paris_memoire.enrich_entities --limit 5   # limiter
```

### Garde-fous

- **Matching conservateur** : un identifiant n'est écrit que si le nom correspond
  nettement. En cas de doute, rien n'est écrit et c'est signalé pour revue manuelle.
- **Dry-run par défaut** : aucune écriture sans `--apply`.
- La `service_role` contourne la RLS : elle est réservée à ce pipeline et ne doit
  jamais être exposée côté navigateur ni committée.

## Importer de l'evidence (HATVP, liste Yale)

Chaque import écrit l'evidence en statut **`pending`** : rien n'est publié sans
revue humaine (page `/admin/revue` de l'app web). Les imports sont
**idempotents** (index unique : relancer un import ne crée pas de doublon).

```bash
# HATVP (lobbying) — télécharger le JSON open data AGORA :
# https://www.hatvp.fr/agora/opendata/
python -m paris_memoire.import_hatvp --file agora_repertoire.json          # dry-run
python -m paris_memoire.import_hatvp --file agora_repertoire.json --apply

# Liste Yale (Russie) — télécharger le CSV :
# https://www.yalerussianbusinessretreat.org/
python -m paris_memoire.import_yale --file yale.csv                         # dry-run
python -m paris_memoire.import_yale --file yale.csv --apply
```

## Sources

| Source | Donnée | Accès | Indicateurs alimentés |
|--------|--------|-------|------------------------|
| GLEIF (`api.gleif.org`) | LEI, nom légal, pays, parent direct | API sans clé | identifiants d'entités |
| SIRENE (`recherche-entreprises.api.gouv.fr`) | SIREN, raison sociale (FR) | API sans clé | identifiants d'entités |
| HATVP (open data AGORA) | inscription + dépenses de lobbying | fichier JSON à télécharger | `GEO_LOBBYING_TRANSP`, `GEO_LOBBYING_SPEND` |
| Liste Yale CELI | position Russie (grades A..F) | CSV à télécharger | `GEO_RUSSIA_EXIT` |

## Prochaines sources (à venir)

Fashion Transparency Index, plans de vigilance, Égapro, CDP/SBTi.
