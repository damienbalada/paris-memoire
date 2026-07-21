// Génère apps/web/lib/methodology.ts depuis METHODOLOGY.md (source de vérité).
// Usage : node scripts/gen-methodology.mjs
import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const md = readFileSync(join(root, "METHODOLOGY.md"), "utf8");

// Échappe pour insertion dans un template literal TS.
const esc = md
  .replace(/\\/g, "\\\\")
  .replace(/`/g, "\\`")
  .replace(/\$\{/g, "\\${");

const out =
  "// ⚠️ Généré automatiquement depuis METHODOLOGY.md (racine du dépôt).\n" +
  "// Ne pas éditer à la main : régénérer via `node scripts/gen-methodology.mjs`.\n" +
  "export const METHODOLOGY_MD = `" + esc + "`;\n";

writeFileSync(join(root, "apps/web/lib/methodology.ts"), out);
console.log("methodology.ts régénéré (%d caractères).", md.length);
