import { CONNECTORS, GUARDS } from "@/lib/connectors";

export const dynamic = "force-dynamic";

// Page statique de transparence : décrit comment les faits entrent dans DIAMS.
// Aucune donnée externe, aucun accès base — c'est une page d'explication.
// La liste des connecteurs vient de lib/connectors.ts (source unique).

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
