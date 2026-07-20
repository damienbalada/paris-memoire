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

// Parts pour/contre/abstention (en % de la barre) à partir d'une position.
// Le sens est porté par la DIRECTION de la barre, jamais par une couleur morale.
function shares(stance: string, nFor: number | null, nAgainst: number | null) {
  if (nFor !== null && nAgainst !== null && nFor + nAgainst > 0) {
    const t = nFor + nAgainst;
    return { pour: (nFor / t) * 100, contre: (nAgainst / t) * 100, label: `${nFor}/${t}` };
  }
  if (stance === "for") return { pour: 100, contre: 0, label: "pour" };
  if (stance === "against") return { pour: 0, contre: 100, label: "contre" };
  if (stance === "abstain") return { pour: 0, contre: 0, label: "abstention" };
  return { pour: 50, contre: 50, label: "partagé" }; // split sans décompte -> indicatif
}

// Une ligne = un groupe (ou l'ensemble). Barre divergente : contre à gauche,
// pour à droite, abstention = bloc neutre centré sur le zéro.
function DivergingRow({
  label, pour, contre, abstain = 0, num, title, summary = false,
}: {
  label: string; pour: number; contre: number; abstain?: number;
  num: string; title?: string; summary?: boolean;
}) {
  return (
    <div className={`civ-row${summary ? " sum" : ""}`} title={title}>
      <span className="civ-label">{label}</span>
      <div className="civ-track">
        <div className="civ-side l"><span className="civ-bar contre" style={{ width: `${contre}%` }} /></div>
        <div className="civ-side r"><span className="civ-bar pour" style={{ width: `${pour}%` }} /></div>
        {abstain > 0 && <span className="civ-abst" style={{ width: `${abstain}%` }} />}
      </div>
      <span className="civ-num">{num}</span>
    </div>
  );
}

function VoteCard({ v, groups }: { v: CivicVote; groups: CivicGroup[] }) {
  const posByGroup = new Map(v.positions.map((p) => [p.group_code, p]));
  const tf = v.total_for ?? 0, ta = v.total_against ?? 0, tab = v.total_abstain ?? 0;
  const decisive = Math.max(1, tf + ta);
  const total = Math.max(1, tf + ta + tab);

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

      {v.alignment_note && <p className="muted small" style={{ marginTop: 8 }}>{v.alignment_note}</p>}

      <div className="civ-chart">
        {v.total_for !== null && (
          <DivergingRow
            summary
            label="Ensemble"
            pour={(tf / decisive) * 100}
            contre={(ta / decisive) * 100}
            abstain={(tab / total) * 100}
            num={`${tf} · ${ta} · ${tab}`}
            title={`Résultat : ${tf} pour, ${ta} contre, ${tab} abstentions`}
          />
        )}
        {groups.map((g) => {
          const p = posByGroup.get(g.code);
          if (!p) return null;
          const s = shares(p.stance, p.n_for, p.n_against);
          return (
            <DivergingRow
              key={g.code}
              label={g.short_name}
              pour={s.pour}
              contre={s.contre}
              num={s.label}
              title={`${g.name}${p.note ? " — " + p.note : ""}`}
            />
          );
        })}
      </div>

      <div className="civ-legend">
        <span><span className="civ-sw pour" /> a voté pour</span>
        <span><span className="civ-sw contre" /> a voté contre</span>
        <span><span className="civ-sw abst" /> abstention (neutre)</span>
        <span className="muted">← contre · pour →</span>
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
