import { getCivicData, type CivicVote, type CivicGroup } from "@/lib/data";

export const dynamic = "force-dynamic";

const pillarName: Record<string, string> = {
  ENV: "🌡️ Climat & Environnement",
  ANI: "🐄 Bien-être animal",
  SOC: "👷 Social & droits humains",
  PLA: "♻️ Plastique",
  WAT: "💧 Eau",
  GEO: "🏛️ Politique & géopolitique",
  INV: "💰 Finance",
};

// Couleur factuelle du sens du vote — pas un jugement, juste pour / contre.
const stanceStyle: Record<string, { bg: string; label: string }> = {
  for:     { bg: "var(--a)", label: "pour" },
  against: { bg: "var(--e)", label: "contre" },
  split:   { bg: "var(--c)", label: "divisé" },
  abstain: { bg: "var(--border)", label: "abstention" },
};

function Bar({ f, a, ab }: { f: number; a: number; ab: number }) {
  const t = Math.max(1, f + a + ab);
  return (
    <div className="row" style={{ height: 8, borderRadius: 5, overflow: "hidden", width: "100%", background: "var(--border)" }}>
      <span style={{ width: `${(f / t) * 100}%`, background: "var(--a)" }} />
      <span style={{ width: `${(ab / t) * 100}%`, background: "var(--c)" }} />
      <span style={{ width: `${(a / t) * 100}%`, background: "var(--e)" }} />
    </div>
  );
}

function VoteCard({ v, groups }: { v: CivicVote; groups: CivicGroup[] }) {
  const posByGroup = new Map(v.positions.map((p) => [p.group_code, p]));
  return (
    <div className="panel">
      <div className="row between wrap" style={{ gap: 8 }}>
        <div>
          <strong>{v.title}</strong>
          <div className="muted small">{v.chamber} · {v.vote_date}</div>
        </div>
        <a className="small" href={v.source_url} target="_blank" rel="noreferrer" style={{ textDecoration: "underline" }}>
          scrutin officiel ↗
        </a>
      </div>

      {v.total_for !== null && (
        <div style={{ margin: "10px 0 4px" }}>
          <Bar f={v.total_for} a={v.total_against ?? 0} ab={v.total_abstain ?? 0} />
          <div className="muted small" style={{ marginTop: 4 }}>
            <span style={{ color: "var(--a)" }}>{v.total_for} pour</span>
            {" · "}
            <span style={{ color: "var(--e)" }}>{v.total_against} contre</span>
            {" · "}{v.total_abstain} abstentions
          </div>
        </div>
      )}

      {v.alignment_note && <p className="muted small" style={{ marginTop: 6 }}>{v.alignment_note}</p>}

      <div className="row wrap" style={{ gap: 6, marginTop: 10 }}>
        {groups.map((g) => {
          const p = posByGroup.get(g.code);
          if (!p) return null;
          const st = stanceStyle[p.stance];
          return (
            <span
              key={g.code}
              title={`${g.name} — ${st.label}${p.note ? " · " + p.note : ""}`}
              className="badge"
              style={{ borderColor: st.bg, color: st.bg }}
            >
              {g.short_name} · {st.label}
              {p.n_for !== null && p.stance === "split" ? ` (${p.n_for} pour)` : ""}
            </span>
          );
        })}
      </div>
    </div>
  );
}

export default async function CivicPage() {
  let data: Awaited<ReturnType<typeof getCivicData>> | null = null;
  try {
    data = await getCivicData();
  } catch (e) {
    return (
      <main>
        <a className="muted small" href="/">← accueil</a>
        <div className="panel" style={{ marginTop: 12, borderColor: "#6b2222" }}>
          <strong>Erreur de chargement.</strong>
          <p className="muted small">{(e as Error).message}</p>
        </div>
      </main>
    );
  }

  const byPillar = new Map<string, CivicVote[]>();
  for (const v of data.votes) {
    const arr = byPillar.get(v.pillar_code) ?? [];
    arr.push(v);
    byPillar.set(v.pillar_code, arr);
  }

  return (
    <main>
      <a className="muted small" href="/">← accueil</a>

      <div className="panel" style={{ marginTop: 12 }}>
        <h1 style={{ marginBottom: 4 }}>DIAMS Civique</h1>
        <p className="muted small" style={{ marginBottom: 8 }}>
          Comment les groupes politiques ont voté sur les grands textes rattachés à chaque pilier DIAMS.
        </p>
        <p className="small" style={{ lineHeight: 1.5 }}>
          🔍 <strong>On ne note pas les partis.</strong> On affiche des <strong>faits de vote</strong> —
          par appel nominal, datés, sourcés vers le scrutin officiel — pour que vous dirigiez votre pouvoir
          de vote en connaissance de cause. À vous de décider quels piliers comptent le plus : DIAMS ne
          classe personne et ne prend pas parti.
        </p>
      </div>

      {[...byPillar.entries()].map(([pillar, votes]) => (
        <section key={pillar} style={{ marginTop: 18 }}>
          <h2 style={{ fontSize: 18, marginBottom: 8 }}>{pillarName[pillar] ?? pillar}</h2>
          {votes.map((v) => (
            <VoteCard key={v.code} v={v} groups={data!.groups} />
          ))}
        </section>
      ))}

      <p className="muted small" style={{ marginTop: 20 }}>
        Pilote (Parlement européen, pilier Climat). Sélection des votes fondée sur une règle objective
        — le vote final des grands textes législatifs — et destinée à être publiée et versionnée.
        Les décomptes exacts par groupe seront ajoutés à mesure que les scrutins nominatifs sont intégrés.
      </p>
    </main>
  );
}
