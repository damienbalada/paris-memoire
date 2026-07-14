import { promises as fs } from "node:fs";
import path from "node:path";
import { marked } from "marked";

export const dynamic = "force-dynamic";

// La méthodologie publique EST le fichier versionné METHODOLOGY.md du repo :
// une seule source de vérité, auditable via l'historique git.
async function loadMethodology(): Promise<string | null> {
  const candidates = [
    path.join(process.cwd(), "..", "..", "METHODOLOGY.md"), // apps/web -> racine repo
    path.join(process.cwd(), "METHODOLOGY.md"),
  ];
  for (const p of candidates) {
    try {
      return await fs.readFile(p, "utf-8");
    } catch {
      // essaie le suivant
    }
  }
  return null;
}

export default async function MethodologiePage() {
  const md = await loadMethodology();
  if (!md) {
    return (
      <main>
        <h1>Méthodologie</h1>
        <div className="panel">METHODOLOGY.md introuvable dans ce déploiement.</div>
      </main>
    );
  }
  const html = await marked.parse(md);
  return (
    <main>
      {/* contenu de notre propre repo, versionné — pas de contenu externe */}
      <article className="prose" dangerouslySetInnerHTML={{ __html: html }} />
    </main>
  );
}
