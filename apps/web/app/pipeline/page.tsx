export const dynamic = "force-dynamic";

// Page statique de transparence : décrit comment les faits entrent dans DIAMS.
// Aucune donnée externe, aucun accès base — c'est une page d'explication.

type Connector = {
  name: string;
  pillar: string;
  produces: string;
  source: string;
  level: "groupe" | "marque" | "groupe ou marque" | "—";
};

const CONNECTORS: Connector[] = [
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

const GUARDS = [
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

export default function PipelinePage() {
  return (
    <main>
      <h1>Transparence du pipeline</h1>
      <p className="muted">
        DIAMS ne saisit pas les faits « à la main » à l'échelle. Chaque source
        institutionnelle est ingérée par un <strong>connecteur</strong> auditable.
        Voici lesquels, ce qu'ils produisent, et les garde-fous qui s'appliquent à
        tous.{" "}
        <a href="/methodologie" style={{ textDecoration: "underline" }}>Méthodologie complète →</a>
      </p>

      <div className="panel">
        <h3>Les trois garde-fous invariants</h3>
        {GUARDS.map((g) => (
          <div key={g.title} style={{ marginTop: 12 }}>
            <div className="row" style={{ gap: 8, alignItems: "center" }}>
              <span className="badge">déterministe</span>
              <strong>{g.title}</strong>
            </div>
            <p className="muted small" style={{ marginTop: 4 }}>{g.body}</p>
          </div>
        ))}
      </div>

      <div className="panel">
        <h3>Connecteurs</h3>
        <div className="prose">
          <table>
            <thead>
              <tr>
                <th>Connecteur</th>
                <th>Pilier</th>
                <th>Ce qu'il produit</th>
                <th>Source</th>
                <th>Niveau</th>
              </tr>
            </thead>
            <tbody>
              {CONNECTORS.map((c) => (
                <tr key={c.name}>
                  <td><strong>{c.name}</strong></td>
                  <td>{c.pillar}</td>
                  <td>{c.produces}</td>
                  <td>{c.source}</td>
                  <td>{c.level}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <p className="muted small" style={{ marginTop: 12 }}>
          Les indicateurs quantitatifs (taux effectif, présence en paradis fiscaux)
          sont chargés en <strong>valeur brute</strong> : c'est le moteur qui calcule
          le percentile intra-secteur et applique la direction (« plus haut = mieux »
          ou l'inverse). Normaliser à la main fausserait la comparaison sectorielle.
        </p>
      </div>

      <div className="panel">
        <h3>Niveau de rattachement</h3>
        <p className="muted small">
          Gouvernance, fiscalité et note climat sont consolidées au niveau du{" "}
          <strong>groupe</strong> et héritées par les marques. Certains benchmarks
          notent directement une <strong>marque</strong> (ex. le Fashion Transparency
          Index note Gucci) : la preuve s'y rattache alors. La marque hérite de son
          groupe uniquement là où elle n'a pas de preuve propre.
        </p>
      </div>
    </main>
  );
}
