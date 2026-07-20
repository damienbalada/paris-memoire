// ⚠️ Généré automatiquement depuis METHODOLOGY.md (racine du dépôt).
// Ne pas éditer à la main : régénérer via le script de build.
export const METHODOLOGY_MD = `# Méthodologie — DIAMS

> **DIAMS** — **D**iagnostic **I**ndépendant, **A**uditable et **M**ulti-critères
> des **S**ociétés. Score éthique d'entreprise, multi-critères, **traçable** :
> chaque point de note renvoie à une preuve sourcée et datée. La méthodo est
> publique et versionnée : c'est la condition de la confiance.

Version : \`0.2.0\` — périmètre : **Luxe/Mode, agroalimentaire/FMCG, hygiène-beauté,
tech, automobile, restauration, énergie, banque** (France + international).

---

## 1. Principes fondateurs

1. **Résolution d'entités d'abord.** Une marque n'est pas une entreprise.
   Bottega → Kering, Dior → LVMH. Sans table marque → filiale → groupe avec les
   % de détention, le score est faux dès le départ. C'est le socle.
2. **Chaque point de score = une evidence sourcée et datée.** Jamais une opinion.
3. **Décroissance à 5 ans.** Un fait de 2014 ne plombe pas une entreprise à vie :
   une evidence n'est « active » que pendant 5 ans après sa date d'observation.
4. **Faits séparés des jugements.** On stocke des indicateurs factuels
   normalisés ; la pondération est appliquée *après*, via des profils de valeurs
   configurables. Pas de score « one-size-fits-all ».
5. **Indice de confiance séparé du score.** La donnée manquante ne produit jamais
   une bonne note. On affiche « Note : B / Fiabilité : 40 % ».
6. **Normalisation intra-secteur.** Comparer une banque et un maroquinier sur le
   bien-être animal n'a pas de sens.
7. **Anti-greenwashing.** Un engagement (promesse) pèse beaucoup moins qu'un
   résultat mesuré. On les distingue explicitement.
8. **Tout est daté, versionné, auditable.** Chaque point est cliquable vers sa
   source datée.

---

## 2. Les trois règles de calcul (tranchées, gravées en base)

Ces règles sont stockées **en base** (\`source_tier_config\`,
\`evidence_nature_config\`, \`scoring_params\`) pour être datées, auditables et
modifiables sans redéploiement de code.

### Règle 1 — Donnée manquante = note pénalisante

Une dimension sans aucune evidence active reçoit un score de **0** (paramètre
\`missing_data_score\`) **et** une confiance de 0. L'opacité est donc **punie dans
la note ET signalée dans la fiabilité**. Justification : le périmètre vise des
grands groupes soumis à obligation légale de publication (CSRD, devoir de
vigilance) — ne pas publier est un choix, pas une excuse.

### Règle 2 — Solidité des sources : pondérée et plafonnée

Le \`tier\` de la source conditionne le poids ET le plafond d'impact d'une
evidence :

| Tier | Exemples | Poids | Plafond confiance | Peut pénaliser seule ? |
|------|----------|------:|------:|:--:|
| \`regulatory\`  | CSRD, devoir de vigilance, AMF, CbCR | 1.00 | 1.00 | oui |
| \`audited_ngo\` | FTI, KnowTheChain, BBFAW, CDP, SBTi | 0.80 | 0.85 | oui |
| \`press\`       | presse, allégations (BHRRC) | 0.35 | 0.45 | non (plancher 0.30) |
| \`crowd\`       | militant non audité (PETA) | 0.20 | 0.30 | non (plancher 0.40) |

Une source peu fiable **compte un peu, mais ne peut pas, seule, faire chuter un
indicateur sous son plancher** tant qu'aucune source fiable ne confirme. C'est
ce qui protège des erreurs façon « 99 % Républicain sans justification ».

### Règle 3 — Promesse vs preuve (anti-greenwashing)

La \`nature\` de l'evidence module sa valeur et plafonne l'indicateur :

| Nature | Multiplicateur | Plafond sans \`result\` |
|--------|------:|------:|
| \`result\` (résultat mesuré) | 1.00 | aucun |
| \`policy\` (politique formalisée) | 0.70 | 0.60 |
| \`commitment\` (promesse) | 0.40 | 0.50 |
| \`controversy\` (controverse) | 1.00 (pénalité) | — |

**Une promesse rapporte peu, une preuve rapporte plein.** Tant qu'aucune
evidence \`result\` ne confirme, l'indicateur est plafonné.

### Règle 4 — Corroboration des controverses (anti-parti-pris)

Une controverse **n'affecte la note que si elle est corroborée**. Sinon elle
est **affichée** (transparence) mais **exclue du calcul** (\`display_only\`) :

| Situation de la controverse | Effet sur la note |
|---|---|
| Source \`regulatory\` (justice / régulateur : décision, sanction) | ✅ pénalise (fait adjudiqué) |
| Corroborée par **≥ 2 sources distinctes** | ✅ pénalise |
| **Source unique** non réglementaire (une ONG, un rapport isolé, une allégation presse) | 🟡 affichée « hors note », n'affecte pas le score |

On ne laisse **jamais une source unique contestée piloter un score**. Le fait
reste visible sur la fiche, sourcé et daté, mais il ne devient scorant que s'il
est confirmé par une décision officielle ou recoupé par une autre source. Cela
protège le label du reproche de parti pris tout en préservant la transparence.

> Exemple : les entreprises citées par le seul rapport d'une Rapporteuse
> spéciale de l'ONU (source contestée, non recoupée par la base « consensus »
> OHCHR) sont **affichées mais non comptées** tant qu'aucune source consensus
> ou décision de justice ne corrobore.

---

## 3. Du fait au score (pipeline de calcul)

\`\`\`
evidence (faits sourcés, datés, typés)
   │  filtre : evidence_active  (approuvée + < 5 ans)
   ▼
normalisation INTRA-SECTEUR  →  valeur [0,1] par indicateur
   │  applique : poids de tier (règle 2) + nature (règle 3)
   ▼
agrégation par DIMENSION  (donnée manquante → 0, règle 1)
   │  applique : poids du PROFIL de valeurs choisi
   ▼
score global  +  INDICE DE CONFIANCE (séparé) = entity_coverage
\`\`\`

---

## 4. Dimensions

| Code | Dimension | Note |
|------|-----------|------|
| ENV | Environnement | climat, émissions, matières |
| PLA | Plastique | pollution plastique (Break Free From Plastic), emballages recyclés, réduction du plastique vierge — *pertinent selon le secteur* |
| WAT | Eau | note CDP Water, intensité de prélèvement, stress hydrique et controverses — *pertinent selon le secteur* |
| LAB | Travail & Rémunération | bien-être des **animaux humains**, en interne |
| SUP | Chaîne d'appro & Droits humains | bien-être des **animaux humains**, en amont |
| ANI | Bien-être animal (non-humain) | élevage, cuirs, laine, duvet, fourrure, tests, abattage |
| GEO | Géopolitique & Prises de position | lobbying, Russie, financement politique |
| TAX | Fiscalité | CbCR, juridictions à faible imposition |
| GOV | Gouvernance | conseil, sanctions |
| INV | Investissements & Finance éthique | finance durable, désinvestissement fossile, participations controversées |

### Règle ANI — Plafond d'exploitation animale (gate)

Principe antispéciste : **l'exploitation animale est la base**. S'il y a
exploitation (matières animales : cuir, laine, soie, duvet, fourrure, peaux…),
la note du pilier ANI est **plafonnée** — le bien-être ne fait que positionner
la note *sous* ce plafond, il ne le lève pas. Seules des matières non-animales
le lèvent.

| Niveau d'exploitation (\`ANI_EXPLOITATION\`) | Plafond ANI | Note max |
|---|---:|:--:|
| \`animal_free\` (aucune matière animale) | 1.00 | A |
| \`limited\` (animal marginal) | 0.55 | C |
| \`extensive\` (cuir/laine au cœur) | 0.40 | D |
| inconnu (défaut secteur mode) | 0.40 | D |

Mécanisme générique (\`dimension_gates\`) : un indicateur « gate » borne le score
d'une dimension sans entrer dans sa moyenne. Si le niveau est inconnu, on
suppose l'exploitation (plafond 0.40) — anti-opacité.

**Cas d'une marque 100 % végétale (\`animal_free\`).** Une marque sans aucun
intrant animal (ex : Alpro) n'exploite pas d'animaux : le postulat d'exploitation
ne s'applique pas. Le pilier ANI n'est alors **pas plafonné** ; il est au
contraire noté positivement sur l'indicateur « gamme sans intrant animal », car
ne causer aucun tort à un animal est le **meilleur** résultat possible sur ce
pilier. À l'inverse, un secteur sans enjeu animal (ex : boissons) voit le pilier
ANI simplement **retiré** (ni noté, ni plafonné).

### Règle PLA — Plafond « gros pollueur plastique »

Symétrique de la règle animale : un indicateur *gate* (\`PLA_POLLUTER\`, alimenté
par les audits *Break Free From Plastic*) **plafonne** la note du pilier
Plastique selon la gravité du classement — un pollueur mondial majeur ne peut pas
obtenir une bonne note plastique, même avec de beaux engagements (la preuve prime
sur la promesse). Contrairement à l'animal, l'absence de classement **ne
présume pas** le pire (plafond par défaut 1.0) : seules les marques explicitement
classées sont plafonnées.

### Méta-score « Bien-être du vivant »

Philosophie : **les humains sont des animaux**. On couvre tout le vivant. Le
calcul reste séparé par dimension (pour une normalisation intra-sujet correcte),
mais un **méta-score « Bien-être du vivant »** agrège bien-être animal
non-humain (\`ANI\`) + travail (\`LAB\`) + chaîne d'appro/droits humains (\`SUP\`).

---

## 5. Profils de valeurs (pondération)

- **Équilibré** (défaut) — toutes les dimensions comptent de façon comparable.
- **Écologie d'abord** — priorité à l'environnement.
- **Bien-être du vivant** — priorité aux animaux humains et non-humains.
- **Transparence & probité** — priorité fiscalité / gouvernance / prises de position.

Le profil appliqué par défaut est **Équilibré**. La pondération est fixée côté
serveur (pas de réglage libre côté visiteur, pour garder des notes comparables et
non « bricolables »).

---

## 6. Sources et tiers de fiabilité

Voir \`supabase/seed/03_sources.sql\` pour le registre complet. Règle d'or :
**CSRD / devoir de vigilance = tier 1 ; presse / PETA = tier 3.**

---

## 7. Statut

Document vivant. Toute modification des paramètres de calcul (tables de config)
doit être datée et justifiée ici.
`;
