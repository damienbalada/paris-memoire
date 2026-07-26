import { getScorePayload, getOwnerGroup, getAlternatives, type Alternative } from "@/lib/data";
import { computeScore } from "@/lib/scoring";
import { CompanyScore } from "@/components/CompanyScore";

export const dynamic = "force-dynamic";

export default async function CompanyPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;

  try {
    const payload = await getScorePayload(slug);
    if (!payload) {
      return (
        <main>
          <a className="muted small" href="/">← retour</a>
          <div className="panel" style={{ marginTop: 12 }}>Entité introuvable : {slug}</div>
        </main>
      );
    }

    const result = computeScore(payload);

    // Groupe propriétaire (le vrai bénéficiaire économique) : on calcule aussi
    // sa note pour l'afficher en regard de celle de la marque.
    let group: { name: string; result: ReturnType<typeof computeScore> } | null = null;
    try {
      const owner = await getOwnerGroup(slug);
      if (owner) {
        const gp = await getScorePayload(owner.slug);
        if (gp) group = { name: owner.name, result: computeScore(gp) };
      }
    } catch {
      // encart groupe optionnel : on ignore les erreurs
    }

    // Alternatives mieux notées du même secteur. Bloc optionnel : une erreur ici
    // ne doit jamais empêcher l'affichage de la note.
    let alternatives: Alternative[] = [];
    try {
      alternatives = await getAlternatives(slug, result.score);
    } catch {
      // ignoré
    }

    return <CompanyScore payload={payload} group={group} alternatives={alternatives} />;
  } catch (e) {
    return (
      <main>
        <a className="muted small" href="/">← retour</a>
        <div className="panel" style={{ marginTop: 12, borderColor: "#6b2222" }}>
          <strong>Erreur de chargement.</strong>
          <p className="muted small">{(e as Error).message}</p>
        </div>
      </main>
    );
  }
}
