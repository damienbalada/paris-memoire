import { revalidatePath } from "next/cache";
import { getAdminSupabase, listPendingEvidence, setReviewStatus } from "@/lib/admin";

export const dynamic = "force-dynamic";

async function approve(formData: FormData) {
  "use server";
  await setReviewStatus(String(formData.get("id")), "approved", "revue-manuelle");
  revalidatePath("/admin/revue");
}

async function reject(formData: FormData) {
  "use server";
  await setReviewStatus(String(formData.get("id")), "rejected", "revue-manuelle");
  revalidatePath("/admin/revue");
}

export default async function ReviewQueuePage() {
  if (!getAdminSupabase()) {
    return (
      <main>
        <h1>File de revue</h1>
        <div className="panel" style={{ borderColor: "#6b4b18" }}>
          <strong>Back-office non configuré.</strong>
          <p className="muted small">
            Ajoutez <code>SUPABASE_SERVICE_ROLE_KEY=...</code> dans{" "}
            <code>apps/web/.env.local</code> (clé secrète, usage local uniquement —
            ne jamais déployer cette page sans authentification).
          </p>
        </div>
      </main>
    );
  }

  const pending = await listPendingEvidence();

  return (
    <main>
      <div className="row between">
        <h1>File de revue</h1>
        <span className="badge">{pending.length} en attente</span>
      </div>
      <p className="muted small">
        Chaque evidence importée par le pipeline doit être validée ici avant de
        compter dans un score. Approuver = publier ; rejeter = écarter.
      </p>

      {pending.length === 0 && (
        <div className="panel">Rien à revoir — la file est vide. ✨</div>
      )}

      {pending.map((e) => (
        <div className="panel" key={e.id}>
          <div className="row between wrap" style={{ gap: 8 }}>
            <div>
              <strong>{e.entity?.name ?? "?"}</strong>
              <span className="muted small"> · {e.indicator?.name ?? "?"} ({e.indicator?.code})</span>
            </div>
            <span className="row" style={{ gap: 6 }}>
              <span className="badge">{e.nature}</span>
              <span className={`badge tier-${e.source?.tier}`}>{e.source?.name}</span>
              <span className="badge">{e.observed_on}</span>
            </span>
          </div>

          <p className="small" style={{ margin: "10px 0 4px" }}>
            {e.excerpt ?? <span className="muted">(pas d'extrait)</span>}
          </p>
          <div className="muted small">
            valeur : {e.value_text ?? e.value_numeric ?? String(e.value_boolean ?? "—")}
            {e.normalized_value !== null && <> · normalisée : {e.normalized_value}</>}
            {" · confiance : "}{e.confidence}
            {e.source_url && (
              <>
                {" · "}
                <a href={e.source_url} target="_blank" rel="noreferrer" style={{ textDecoration: "underline" }}>
                  source
                </a>
              </>
            )}
          </div>

          <div className="row" style={{ gap: 8, marginTop: 12 }}>
            <form action={approve}>
              <input type="hidden" name="id" value={e.id} />
              <button className="btn" style={{ borderColor: "var(--a)", color: "var(--a)" }}>
                ✓ Approuver
              </button>
            </form>
            <form action={reject}>
              <input type="hidden" name="id" value={e.id} />
              <button className="btn" style={{ borderColor: "var(--e)", color: "var(--e)" }}>
                ✕ Rejeter
              </button>
            </form>
          </div>
        </div>
      ))}
    </main>
  );
}
