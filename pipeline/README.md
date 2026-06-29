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

## Sources

| Source | API | Auth | Donnée |
|--------|-----|------|--------|
| GLEIF | `api.gleif.org` | non | LEI, nom légal, pays, parent direct |
| SIRENE | `recherche-entreprises.api.gouv.fr` | non | SIREN, raison sociale (France) |

## Prochaines sources (à venir)

HATVP (lobbying), liste Yale (Russie), Fashion Transparency Index,
plans de vigilance — alimenteront la table `evidence` en statut `pending`
(revue humaine avant passage en `approved`).
