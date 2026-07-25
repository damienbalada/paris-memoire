import "./globals.css";
import type { Metadata, Viewport } from "next";
import type { ReactNode } from "react";

export const metadata: Metadata = {
  title: "DIAMS — Documented, Independent, Auditable, Multi-criteria Scoring",
  description:
    "DIAMS : score éthique d'entreprise multi-critères, chaque point traçable jusqu'à sa source datée.",
};

// Zoom laissé libre (pas de maximum-scale) pour l'accessibilité.
export const viewport: Viewport = { width: "device-width", initialScale: 1 };

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="fr">
      <body>
        <div className="container">
          <header className="row between" style={{ marginBottom: 24 }}>
            <a href="/" title="Documented, Independent, Auditable, Multi-criteria Scoring">
              <strong>DIAMS</strong>
            </a>
            <span className="row" style={{ gap: 14 }}>
              <a className="muted small" href="/classement">Classement</a>
              <a className="muted small" href="/pipeline">Pipeline</a>
              <a className="muted small" href="/methodologie">Méthodologie</a>
            </span>
          </header>
          {children}
        </div>
      </body>
    </html>
  );
}
