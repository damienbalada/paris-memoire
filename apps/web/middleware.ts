import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

// Protection au niveau de l'app (indépendante du plan Vercel) : mot de passe
// HTTP Basic. Garde le site privé tant qu'on ne veut pas le rendre public.
// Identifiants configurables via SITE_USER / SITE_PASSWORD, sinon valeurs par
// défaut ci-dessous. Ce n'est PAS une protection de secrets — juste un mur
// pour empêcher l'accès public pendant le développement.
const USER = process.env.SITE_USER || "diams";
const PASS = process.env.SITE_PASSWORD || "awareness2026";

export function middleware(req: NextRequest) {
  const auth = req.headers.get("authorization");
  if (auth?.startsWith("Basic ")) {
    try {
      const decoded = atob(auth.slice(6));
      const idx = decoded.indexOf(":");
      const u = decoded.slice(0, idx);
      const p = decoded.slice(idx + 1);
      if (u === USER && p === PASS) return NextResponse.next();
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
