// Recopie le moteur de scoring canonique vers la copie utilisée par le web.
// Le web (Next.js) et l'edge function (Deno) ne peuvent pas partager un import :
// on maintient donc deux fichiers identiques, avec ce script comme source unique
// de vérité et un test miroir qui échoue en cas de divergence.
//
// Usage : node scripts/sync-scoring.mjs
import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const CANONICAL = join(root, "supabase/functions/compute_score/scoring.ts");
const MIRROR = join(root, "apps/web/lib/scoring.ts");

const src = readFileSync(CANONICAL, "utf8");
const current = (() => {
  try {
    return readFileSync(MIRROR, "utf8");
  } catch {
    return null;
  }
})();

if (current === src) {
  console.log("scoring.ts : déjà synchronisé ✓");
} else {
  writeFileSync(MIRROR, src);
  console.log("scoring.ts : copie web resynchronisée depuis le fichier canonique.");
}
