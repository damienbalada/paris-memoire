import { getScorePayload } from "@/lib/data";
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
    return <CompanyScore payload={payload} />;
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
