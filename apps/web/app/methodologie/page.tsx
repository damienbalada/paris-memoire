import { marked } from "marked";
import { METHODOLOGY_MD } from "@/lib/methodology";

export const dynamic = "force-dynamic";

// La méthodologie est la source versionnée METHODOLOGY.md, embarquée à la
// compilation (cf. lib/methodology.ts) : aucune lecture de fichier au runtime,
// donc un rendu fiable quel que soit l'environnement de déploiement.
export default async function MethodologiePage() {
  const html = await marked.parse(METHODOLOGY_MD);
  return (
    <main>
      {/* contenu de notre propre repo, versionné — pas de contenu externe */}
      <article className="prose" dangerouslySetInnerHTML={{ __html: html }} />
    </main>
  );
}
