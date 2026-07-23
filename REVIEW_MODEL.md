# Modèle de revue — DIAMS

> Décision structurante : **comment valider les faits à l'échelle mondiale sans
> que la revue humaine devienne le goulet d'étranglement.**

## Décision : confiance graduée par tier de source

**Règle d'or : c'est la SOURCE qui détermine le tier et le traitement — jamais le
contributeur.** La revue humaine ne s'applique qu'à la fraction *risquée* (presse
non structurée + contributif). Les données structurées de sources d'autorité sont
auto-publiées, car le connecteur qui les ingère est **déterministe** (il
n'interprète rien) et le risque d'erreur est celui de la source officielle.

| Tier | Exemples | Statut à l'ingestion | Revue humaine unitaire |
|---|---|---|---|
| **1 — regulatory** | CSRD, CbCR, décisions de justice / régulateurs (CNIL, Commission UE), dépôts officiels | **`approved`** (auto) | Non — audit **par échantillon** a posteriori |
| **2 — audited_ngo** | CDP, SBTi, BBFAW, KnowTheChain, InfluenceMap, Reclaim Finance | **`approved`** (auto), fenêtre de contestation | Non — audit par échantillon |
| **3 — press** | articles, extraction de faits (traitement du langage) | **`pending`** | **Oui, avant publication** + corroboration (Règle 4) |
| **crowd** | contributions communautaires | **`pending`**, poids plancher | **Oui** ; jamais promu sans source vérifiable |

### Pourquoi ça résout le goulet
Les tiers 1-2 (structurés, déterministes) constitueront l'essentiel du volume et
ne demandent **aucune revue unitaire**. La revue se concentre sur les tiers 3 /
crowd — minoritaires mais réellement risqués (texte libre, contributions).

## Qui révise le tier 3, en deux temps

- **Phase 1 (maintenant → v1)** : curation interne (équipe restreinte). Suffisant
  tant que le volume presse est faible.
- **Phase 2 (échelle)** : **communauté vérifiée + tri assisté**. Le système
  pré-classe (source, corroboration, sévérité) ; l'humain valide/rejette.
  Réputation des contributeurs. Une contribution reste en tier `crowd` (poids
  plancher) tant qu'une **source vérifiable** ne la fait pas monter de tier.

## Rôle de l'agent IA dans la revue (tier 3 / crowd)

**Principe : l'IA remplace l'*effort* de la revue, pas la *responsabilité* de la revue.**

Un agent IA **pleinement autonome** qui publierait le tier 3 sans humain est
**exclu** — pour des raisons structurelles, pas de principe :
- **Non déterministe** : ce qui autorise l'auto-publication des tiers 1-2, c'est
  que les connecteurs sont déterministes (mêmes entrées → mêmes sorties,
  testables, incapables d'inventer). Un LLM peut **halluciner** source, montant,
  date. Une seule hallucination publiée ruine la crédibilité. Donner à l'IA le
  privilège des connecteurs serait une erreur de catégorie.
- **Responsabilité légale** : le tier 3 contient des accusations nominatives
  (« travail forcé », « fraude ») → risque de diffamation ; un responsable humain
  doit rester dans la boucle.
- **Injection** : la presse est du texte externe → surface d'injection de prompt.
- **Biais non auditable** : un agent qui décide seul « ce qui compte » injecte
  ses biais dans un outil qui se veut neutre.

**Rôle retenu — l'IA comme copilote de revue (clé de l'échelle) :** l'agent
extrait le fait, vérifie que la source le dit bien, compte les sources distinctes
(corroboration / Règle 4), détecte l'adjudication régulatoire, rédige un excerpt
**nuancé**, pré-classe sévérité/nature. L'humain **valide ou rejette en un clic**.
Démultiplie un curateur sans supprimer le point de contrôle.

**Palier intermédiaire autorisé — auto-approbation IA *tracée et bornée* :**
l'IA peut auto-approuver du tier 3 **uniquement** si :
- l'evidence est marquée `reviewer = ai:<modèle>` (distincte d'une validation humaine),
- le poids est **réduit** (jamais au-dessus du tier de sa source),
- la **contestation est facile** et l'**audit humain par échantillon** est actif.

**Jamais** : une approbation IA rendue *indistinguable* d'un fait validé par un
humain, ou sans piste d'audit.

## Garde-fous non négociables

1. **URL de source obligatoire** — aucun fait sans lien vérifiable
   (déjà dans `supabase/checks/integrity.sql`).
2. **Séparation source / contributeur** — le tier découle de la source, pas de
   qui la saisit : impossible d'injecter un faux fait « regulatory ».
3. **Journal d'audit** — qui a approuvé/rejeté quoi et quand ; révocable.
4. **Échantillonnage qualité** — contrôle aléatoire d'un % de l'auto-publié
   (tiers 1-2) pour détecter toute dérive d'un connecteur.
5. **Corroboration (Règle 4)** — une controverse contestée à source unique est
   affichée mais hors calcul tant qu'elle n'est pas corroborée.

## Implications techniques (à implémenter, ≥ v0.5)

Aujourd'hui, `pipeline/.../load.py` insère **tout** en `pending`. La décision
implique de **dériver `review_status` du tier de la source** à l'ingestion :

- connecteurs tier 1-2 → insertion directe en `approved` (reviewer =
  `auto:<connecteur>`), tracée ;
- connecteurs/entrées tier 3 & crowd → `pending`, file de revue
  (`/admin/revue`).

Un `reviewer` distinct (`auto:*` vs humain) permet l'audit par échantillon et la
distinction claire entre publication automatique et validation humaine.

## Ce que ce modèle garantit

- **Scalabilité** : la revue humaine ne croît qu'avec le volume *presse/crowd*,
  pas avec le volume total.
- **Intégrité** : la manipulation est bloquée à la racine (source = autorité du tier).
- **Cohérence** : réutilise les tiers déjà présents dans le moteur — aucune
  nouvelle notion à introduire.

---

*Document vivant. Voir [`ROADMAP.md`](./ROADMAP.md) (Axe C — passage à l'échelle)
et [`METHODOLOGY.md`](./METHODOLOGY.md) (tiers de source, Règle 4).*
