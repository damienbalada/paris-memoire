import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

// Protection au niveau de l'app (indépendante du plan Vercel) : mot de passe
// HTTP Basic. Garde le site privé tant qu'on ne veut pas le rendre public.
//
// Aucun identifiant en dur : SITE_USER / SITE_PASSWORD DOIVENT être définis
// dans l'environnement (Vercel → Settings → Environment Variables). Si le mot
// de passe est absent, on refuse tout (fail-closed) plutôt que de retomber sur
// une valeur par défaut publique — un secret versionné n'est plus un secret.
// Ce n'est PAS un coffre-fort : juste un mur pendant le développement.
const USER = process.env.SITE_USER || "diams";
const PASS = process.env.SITE_PASSWORD;

/** Comparaison à temps constant (évite de fuiter le secret par timing). */
function safeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

export function middleware(req: NextRequest) {
  if (!PASS) {
    return new NextResponse(
      "Configuration incomplète : la variable d'environnement SITE_PASSWORD n'est pas définie.",
      { status: 503 },
    );
  }
  const auth = req.headers.get("authorization");
  if (auth?.startsWith("Basic ")) {
    try {
      const decoded = atob(auth.slice(6));
      const idx = decoded.indexOf(":");
      const u = decoded.slice(0, idx);
      const p = decoded.slice(idx + 1);
      if (safeEqual(u, USER) && safeEqual(p, PASS)) return NextResponse.next();
    } catch {
      // en-tête malformé -> demande d'authentification
    }
  }
  return new NextResponse("Authentification requise.", {
    status: 401,
    headers: { "WWW-Authenticate": 'Basic realm="DIAMS", charset="UTF-8"' },
  });
}

// S'applique à tout sauf les assets statiques.
export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"],
};
