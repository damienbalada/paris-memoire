# Feuille de route — DIAMS

> **DIAMS** — Documented, Independent, Auditable, Multi-criteria Scoring.
> Ambition : un outil de référence **mondial**, utilisable par tous, où chaque
> point de note est traçable jusqu'à une source publique, datée et vérifiable.

## Principe directeur (à ne jamais trahir)

> **Exhaustivité des données publiques *qui existent* + honnêteté sur les manques.**

DIAMS ne vise pas « 100 % des cases remplies » (ce serait intenable : beaucoup
d'entités n'ont aucune obligation de publication, et la presse couvre de façon
inégale). Il vise à **capter tout ce qui est publiquement disponible** et à
**afficher clairement ce qui manque** via l'indice de fiabilité. Un « je ne sais
pas encore » assumé vaut mieux qu'une note fabriquée sur du vide — c'est la
condition de la crédibilité mondiale.

Deux natures de sources, deux régimes de coût :
- **Données obligatoires / structurées** (CSRD, CbCR, dépôts réglementaires,
  index officiels, benchmarks ONG) → connecteurs **déterministes, 0 token**.
- **Presse / controverses** (texte non structuré) → extraction assistée
  (traitement du langage) + **revue humaine** obligatoire. C'est le volet coûteux.

---

## État actuel (socle — v0.4)

**Acquis :**
- Moteur de scoring pur, testé (règles 1-5, gates, méta-scores, percentile intra-secteur).
- 10 piliers + résolution d'entités (marque → groupe, héritage).
- **Connecteurs déterministes par pilier** : SBTi, CDP (climat+eau), Égapro,
  Gouvernance, Fiscalité, Benchmarks (BBFAW/KnowTheChain/FTI), BFFP, Finance
  éthique, HATVP, Yale. + résolution GLEIF/SIRENE, univers OFF/Wikidata.
- Indice de fiabilité affiché séparément ; distinction non-applicable / sans-donnée / controverse hors-note.
- **Alternatives mieux notées** par fiche (même secteur, même nature, jamais une
  entité non publiable) et **signalements** de lecteurs hors calcul (Règles 6 et 7).
- Curation manuelle sourcée en cours (CDP, sanctions, controverses) — mais **plafonne** (données derrière paywall, presse inégale).

**Limite structurelle identifiée :** la curation manuelle ne passe pas à
l'échelle. La suite passe par l'**ingestion par fichiers/API** via les connecteurs
(bloquée aujourd'hui par la politique réseau de l'environnement).

---

## Axe A — Couverture des données **obligatoires**, juridiction par juridiction

Chaque régime réglementaire = un connecteur déterministe. Ordre proposé (du plus
riche/structuré au plus marginal) :

| Phase | Régime | Apporte | Piliers |
|---|---|---|---|
| A1 | **UE — CSRD / ESRS** | reporting durabilité normalisé (climat, eau, social, gouvernance) | ENV, WAT, LAB, GOV, SUP |
| A1 | **UE — CbCR** | reporting fiscal pays-par-pays | TAX |
| A1 | **FR — devoir de vigilance, Égapro, HATVP** | plans de vigilance, égalité F/H, lobbying | SUP, LAB, GEO |
| A2 | **US — SEC** (10-K, climate disclosure) | émissions, risques, gouvernance | ENV, GOV |
| A2 | **UK — SECR / modern slavery act** | énergie, travail forcé | ENV, SUP |
| A3 | **Japon, Canada, Australie…** | équivalents locaux | variable |

> Réalité : le périmètre CSRD a été *réduit* (omnibus 2025). Les entités hors
> grands régimes (PME, non-cotées, Sud global) resteront **sans donnée
> obligatoire** — fiabilité basse assumée, pas un défaut.

---

## Axe B — Couverture **presse / controverses** (le volet coûteux)

Objectif : ne manquer **aucune controverse documentée** (travail forcé, pollution,
évasion fiscale, lobbying, sanctions).

- **Sources structurées d'abord** (déterministes, 0 token) : décisions de
  régulateurs (CNIL/EDPB, Commission européenne concurrence, AMF), bases ONG
  (BHRRC, InfluenceMap, Reclaim Finance). *Déjà commencé (RGPD, antitrust, lobbying).*
- **Presse non structurée ensuite** (coût réel) : extraction de faits d'articles
  via traitement du langage → **toujours en `pending`**, jamais publié sans revue.
  Encadré par : source datée obligatoire, règle de corroboration (Règle 4),
  distinction allégation / fait tranché.

> C'est ici que le « 0 token » ne tient plus. À cadrer : budget, garde-fous
> anti-hallucination, priorisation (grandes entités d'abord).

---

## Axe C — Passage à l'échelle (millions de marques)

1. **Univers de marques** : Open Food Facts + Wikidata (déjà scaffoldé) →
   ingestion massive, marque → groupe.
2. **Le scoring est gratuit** (code pur, 0 token) : le coût est borné par le
   nombre de **groupes** curés, pas de marques (héritage).
3. **Goulet = la revue humaine → TRANCHÉ** (voir [`REVIEW_MODEL.md`](./REVIEW_MODEL.md)) :
   confiance graduée par tier de source. Auto-publication des tiers 1-2
   (regulatory + ONG auditée, connecteurs déterministes) ; revue humaine
   concentrée sur les tiers 3/crowd (presse, contributif). La revue ne croît
   qu'avec le volume presse/crowd, pas avec le volume total.
4. **Contribution par le bas — amorcée** : formulaire de signalement sur chaque
   fiche → file `/admin/corrections`. Un signalement n'entre dans aucun calcul
   (Règle 7) ; il ne fait qu'ouvrir une revue. Le volume ne fait pas la vérité.
5. **Limite de calcul à lever** : les notes sont recalculées à chaque affichage
   (un appel `compute_score_input` par entité). Tenable à ~200 entités, pas à
   l'échelle du million : il faudra **matérialiser les scores** en base, avec
   invalidation sur écriture d'evidence. C'est aujourd'hui le bloc le plus
   sensible au volume, avant même le coût d'ingestion.

---

## Axe D — Accessibilité mondiale (produit)

### Langue : FR aujourd'hui → EN à terme (décidé)

**Aujourd'hui : interface en français.** Cohérent avec les sources actuelles,
massivement françaises (Égapro, HATVP, plans de vigilance, Assemblée nationale,
loi de 1995) et avec le public de départ.

**À terme : bascule en anglais**, pilotée par un déclencheur clair — **le
périmètre des sources**. Quand elles deviennent européennes (Axe A1 : CSRD, CbCR)
puis mondiales (Axe A2-A3 : SEC, UK, Japon…), le français devient un plafond :
il exclut la majorité des utilisateurs comme des contributeurs de la revue
(Axe C). L'anglais devient alors la langue par défaut, le français une locale.

Séquence : **FR seul** → **FR + EN** (le temps de la transition européenne) →
**EN par défaut** + locales.

Déjà acquis : la glose de l'acronyme est **déjà en anglais** (*Documented,
Independent, Auditable, Multi-criteria Scoring*) et DIAMS se lit à l'identique
dans les deux langues — la bascule ne coûtera aucun rebranding.

Reste à faire, le jour J : extraire les libellés dans des fichiers de traduction
(aucune chaîne en dur), traduire `METHODOLOGY.md` (le plus gros volume), et
décider du sort des `excerpt` d'evidence — rédigés en français aujourd'hui, et
qui ne sont pas de l'interface mais de la **donnée** (donc à traiter par langue
de source, pas par simple traduction).

- **Internationalisation** (i18n) : extraction des libellés, FR + EN d'abord.
- **Recherche** d'une marque par nom / code-barres (scan en magasin).
- **API publique** ouverte (la traçabilité est un argument de confiance).
- **Accessibilité** (a11y) et mobile-first (déjà entamé).
- Neutralité éditoriale : aucune monétisation qui compromette l'indépendance.

---

## Jalons

| Version | Contenu | État |
|---|---|---|
| **v0.4** (actuel) | socle moteur + connecteurs + curation manuelle amorcée | ✅ en cours |
| **v0.5** | déblocage réseau → ingestion réelle CSV (CDP, SBTi, benchmarks) | ⏳ nécessite accès environnement |
| **v1.0** | Axe A1 complet (UE + FR) sur les grands groupes ; presse structurée (régulateurs/ONG) ; i18n FR/EN | à venir |
| **v1.5** | Axe A2 (US/UK) ; ingestion massive marques (Axe C) ; recherche/scan | à venir |
| **v2.0** | presse non structurée à l'échelle + revue communautaire ; API publique | à venir |

---

## Ce qui restera *toujours* partiel (et c'est assumé)

- Les entités **sans obligation légale** et **sans couverture presse** : fiabilité
  basse, affichée honnêtement.
- Les données **derrière paywall** (scores CDP détaillés, etc.) : ingérées via
  fichiers officiels quand accessibles, sinon absentes.
- **On n'invente jamais.** Une case vide reste vide. La force de DIAMS n'est pas
  de tout savoir, mais de ne dire que ce qui est vrai, sourcé et daté.

---

*Document vivant. À réviser à chaque franchissement de jalon. Voir aussi
[`METHODOLOGY.md`](./METHODOLOGY.md) (règles de calcul) et
[`pipeline/CONNECTORS.md`](./pipeline/CONNECTORS.md) (connecteurs).*
