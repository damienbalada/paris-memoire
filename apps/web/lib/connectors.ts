// Source unique des connecteurs d'ingestion, partagée par la page /pipeline
// (et disponible pour toute autre vue). Éviter la double maintenance : cette
// liste fait foi côté web. La prose versionnée reste dans METHODOLOGY.md.

export type ConnectorLevel = "groupe" | "marque" | "groupe ou marque" | "—";

export type Connector = {
  name: string;
  pillar: string;
  produces: string;
  source: string;
  level: ConnectorLevel;
};

export const CONNECTORS: Connector[] = [
  { name: "GLEIF / SIRENE", pillar: "—", produces: "Résolution d'entités (LEI / SIREN)", source: "GLEIF, INSEE", level: "—" },
  { name: "OpenFoodFacts / Wikidata", pillar: "—", produces: "Univers de marques + chaînes de détention", source: "OFF, Wikidata", level: "—" },
  { name: "HATVP", pillar: "GEO", produces: "Lobbying (France)", source: "HATVP", level: "groupe" },
  { name: "Yale", pillar: "GEO", produces: "Position Russie", source: "Yale CELI", level: "groupe" },
  { name: "SBTi", pillar: "ENV", produces: "Objectifs climat validés (anti-greenwashing)", source: "Science Based Targets initiative", level: "groupe" },
  { name: "CDP", pillar: "ENV", produces: "Note climat A..D- (barème canonique A=1.00 … D-=0.13, F=0)", source: "CDP", level: "groupe" },
  { name: "Gouvernance", pillar: "GOV", produces: "Mixité (parité = 1.0) + indépendance du conseil", source: "Déclarations CSRD / ESRS", level: "groupe" },
  { name: "Fiscalité", pillar: "TAX", produces: "CbCR (oui/non), taux effectif (%), entités en paradis fiscaux", source: "CbCR, états financiers, Tax Justice Network", level: "groupe" },
  { name: "Benchmarks", pillar: "ANI, SUP", produces: "BBFAW (Tier 1→1.0 … 6→0.10), KnowTheChain (/100), FTI (%)", source: "BBFAW, BHRRC, Fashion Revolution", level: "groupe ou marque" },
];

export type Guard = { title: string; body: string };

export const GUARDS: Guard[] = [
  {
    title: "Code pur, 0 token de modèle",
    body: "Chaque connecteur est déterministe : parsing + normalisation + rapprochement de noms. Aucun appel à un modèle de langage, donc le coût ne dépend pas du nombre de marques — on peut passer à l'échelle sans dérive de facture ni d'aléa.",
  },
  {
    title: "Rapprochement conservateur",
    body: "Un fait n'est rattaché à une entité que si les noms correspondent nettement. En cas de doute, on saute : on ne devine jamais à quelle société appartient une donnée.",
  },
  {
    title: "Revue humaine avant publication",
    body: "Aucun connecteur ne publie directement. Toute preuve importée attend en file de revue (statut « pending ») et ne compte dans aucun score tant qu'un humain ne l'a pas validée.",
  },
];
