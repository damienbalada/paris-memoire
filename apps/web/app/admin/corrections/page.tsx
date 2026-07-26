import { revalidatePath } from "next/cache";
import {
  getAdminSupabase,
  listPendingCorrections,
  setCorrectionStatus,
} from "@/lib/admin";
import { CORRECTION_KINDS, type CorrectionKind } from "@/lib/corrections";

export const dynamic = "force-dynamic";

async function accept(formData: FormData) {
  "use server";
  await setCorrectionStatus(String(formData.get("id")), "accepted");
  revalidatePath("/admin/corrections");
}

async function reject(formData: FormData) {
  "use server";
  await setCorrectionStatus(String(formData.get("id")), "rejected");
  revalidatePath("/admin/corrections");
}

const frDateTime = (iso: string) => {
  const d = new Date(iso);
  return `${String(d.getDate()).padStart(2, "0")}/${String(d.getMonth() + 1).padStart(2, "0")}/${d.getFullYear()}`;
};

export default async function CorrectionsPage() {
  if (!getAdminSupabase()) {
    return (
      <main>
        <h1>Signalements</h1>
        <div className="panel" style={{ borderColor: "#6b4b18" }}>
          <strong>Back-office non configuré.</strong>
          <p className="muted small">
            Ajoutez <code>SUPABASE_SERVICE_ROLE_KEY=...</code> dans les variables
            d'environnement.
          </p>
        </div>
      </main>
    );
  }

  const items = await listPendingCorrections();

  return (
    <main className="fiche-stack">
      <div>
        <a className="muted small" href="/admin/revue">← file de revue des preuves</a>
        <div className="row between" style={{ marginTop: 8 }}>
          <h1 style={{ margin: 0 }}>Signalements</h1>
          <span className="badge">{items.length} en attente</span>
        </div>
        <p className="muted small">
          Signalements envoyés depuis les fiches. <strong>Accepter ne publie rien</strong> :
          cela acte que le signalement est fondé. La note ne bouge que lorsqu'une
          <em> evidence</em> sourcée et datée a été créée — via le pipeline ou la
          curation. Un signalement sans source vérifiable se rejette.
        </p>
      </div>

      {items.length === 0 && <div className="panel">Aucun signalement en attente. ✨</div>}

      {items.map((c) => (
        <div className="panel" key={c.id}>
          <div className="row between wrap" style={{ gap: 8 }}>
            <div>
              <a href={`/entreprise/${c.entity_slug}`}>
                <strong>{c.entity_slug}</strong>
              </a>
              {c.indicator_code && (
                <span className="muted small"> · {c.indicator_code}</span>
              )}
            </div>
            <span className="row" style={{ gap: 6 }}>
              <span className="badge">
                {CORRECTION_KINDS[c.kind as CorrectionKind] ?? c.kind}
              </span>
              <span className="muted small">{frDateTime(c.created_at)}</span>
            </span>
          </div>

          <p className="small" style={{ marginTop: 10, whiteSpace: "pre-wrap", lineHeight: 1.5 }}>
            {c.message}
          </p>

          <div className="muted small">
            {c.source_url ? (
              <a href={c.source_url} target="_blank" rel="noreferrer" style={{ textDecoration: "underline" }}>
                {c.source_url} ↗
              </a>
            ) : (
              <span className="badge warn">aucune source fournie</span>
            )}
            {c.contact && <span> · contact : {c.contact}</span>}
          </div>

          <div className="row" style={{ gap: 8, marginTop: 12 }}>
            <form action={accept}>
              <input type="hidden" name="id" value={c.id} />
              <button className="btn" type="submit">Fondé → créer une evidence</button>
            </form>
            <form action={reject}>
              <input type="hidden" name="id" value={c.id} />
              <button className="btn" type="submit">Rejeter</button>
            </form>
          </div>
        </div>
      ))}
    </main>
  );
}
