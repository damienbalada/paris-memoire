# Ingestion des marques à l'échelle

> Objectif : couvrir **des milliers de marques** sans saisie manuelle, en
> s'appuyant sur le modèle DIAMS « l'ESG vit au niveau du **groupe**, la marque
> **hérite** » (cf. Peugeot → Stellantis).

## Le principe en deux couches

1. **Univers des marques** (« qu'y a-t-il en rayon ») → **Open Food Facts**
   (+ Open Beauty/Products/Pet Food Facts) : base ouverte, téléchargeable,
   FR/UE, avec marque, `brand_owner`, catégories, pays.
2. **Graphe de propriété** (« marque → groupe ») → **Wikidata** (P127/P749),
   complété par **GLEIF** (propriété légale) et le `brand_owner` d'OFF.

On ne cure que ~quelques centaines de **groupes** (là où vivent CDP, SBTi,
votes, lobbying…) ; toutes leurs marques en héritent automatiquement.

## Flux

```
dump Open Food Facts (.jsonl.gz)
      │  connectors/openfoodfacts.brands_from_products()  (agrégation + secteur)
      ▼
select_brands()  ── filtre marché FR/UE + popularité ≥ 5 produits
      ▼
staging_brands   ── zone d'atterrissage brute (audit)
      │  resolve_brands.resolve()  (off_owner > wikidata > éponymie > none)
      ▼
brand_resolutions (status=pending)  ── FILE DE REVUE HUMAINE
      │  approbation dans /admin
      ▼
entities (is_brand=true, parent_id=groupe)  ── la marque hérite des preuves du groupe
```

## Règles de résolution (conservatrices)

| Ordre | Méthode | Base | Confiance |
|------:|---------|------|:---------:|
| 1 | `off_owner`  | `brand_owner` OFF matche un groupe existant | 0.82 |
| 2 | `wikidata`   | propriétaire Wikidata matche un groupe existant | 0.75 |
| 3 | `name_group` | marque éponyme d'un groupe (ex : « Danone ») | 0.90 |
| 4 | `none`       | aucune correspondance nette → revue manuelle | 0.0 |

Matching via `normalize/names.py` (`is_strong_match`) : **on ne devine jamais**.
En cas de doute → `none`, jamais un rattachement à l'aveugle.

## Neutralité & garde-fous

- **Rien n'entre dans `entities` sans validation humaine** (approbation de la file).
- La popularité (`product_count`) priorise la revue : on traite d'abord les
  marques les plus vendues.
- Le `payload` brut est conservé dans `staging_brands` (audit / reproductibilité).

## Domaines réseau à autoriser (une fois)

```
world.openfoodfacts.org
static.openfoodfacts.org
query.wikidata.org
api.gleif.org
```

## Lancer (le jour du déblocage)

```bash
# 1. récupérer le dump (une fois le domaine autorisé)
curl -o off.jsonl.gz https://static.openfoodfacts.org/data/openfoodfacts-products.jsonl.gz
# 2. ingérer -> staging + file de revue
python -m paris_memoire.import_brands off.jsonl.gz
# 3. réviser/approuver dans /admin, puis les marques héritent des groupes
```

## Composants

| Fichier | Rôle |
|---|---|
| `connectors/openfoodfacts.py` | dump OFF → marques (agrégation, secteur), **pur/testé** |
| `connectors/wikidata.py` | SPARQL propriétaire ↔ marque |
| `resolve_brands.py` | rattachement marque→groupe, **pur/testé** |
| `import_brands.py` | orchestrateur (staging + file de revue) |
| `supabase/migrations/20260721120000_brand_ingestion.sql` | tables `staging_brands`, `entity_aliases`, `brand_resolutions` + vue `brand_resolution_queue` |
