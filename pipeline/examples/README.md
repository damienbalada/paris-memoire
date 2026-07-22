# Exemples de CSV d'ingestion

Un fichier par connecteur, avec les **en-têtes réels** attendus et des données
**fictives** (`ExempleCorp` / `DemoGroup` — aucun fait réel).

But : le jour où le réseau est débloqué, l'ingestion se résume à remplacer
l'exemple par le vrai export, puis :

```bash
python -m paris_memoire.import_<connecteur> --file examples/<fichier>.csv   # dry-run
```

Le format de chaque fichier est décrit dans [`../CONNECTORS.md`](../CONNECTORS.md).
Le test `tests/test_examples.py` vérifie que chaque exemple reste compris par son
connecteur (si les colonnes changent, le test casse).

| Fichier | Connecteur |
|---|---|
| `cdp.csv` | `import_cdp` |
| `sbti.csv` | `import_sbti` |
| `bffp.csv` | `import_bffp` |
| `egapro.csv` | `import_egapro --file` |
| `benchmarks_{bbfaw,knowthechain,fti}.csv` | `import_benchmarks --benchmark …` |
| `tax.csv` | `import_tax` |
| `governance.csv` | `import_governance` |
| `investments.csv` | `import_investments` |
