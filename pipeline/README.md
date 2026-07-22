# Pipeline de collecte — DIAMS

Collecte et normalisation des données, avec revue humaine avant publication.
Socle : **résolution d'entités** (LEI via GLEIF, SIREN via SIRENE) ; puis un
connecteur déterministe par pilier de score.

👉 **Liste complète des connecteurs, formats CSV et commandes : [`CONNECTORS.md`](./CONNECTORS.md)**
(source de vérité). Ce README couvre l'installation et la résolution d'entités.

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

## Importer de l'evidence

Chaque import écrit l'evidence en statut **`pending`** : rien n'est publié sans
revue humaine (page `/admin/revue` de l'app web). Les imports sont
**idempotents** (index unique : relancer un import ne crée pas de doublon) et en
**dry-run** par défaut (`--apply` pour écrire).

La liste complète des connecteurs (un par pilier), les colonnes CSV attendues et
les commandes exactes sont dans **[`CONNECTORS.md`](./CONNECTORS.md)**. Exemple :

```bash
# SBTi (objectifs climat) — export « Companies taking action » :
python -m paris_memoire.import_sbti --file sbti.csv            # dry-run
python -m paris_memoire.import_sbti --file sbti.csv --apply    # écrit (pending)
```
