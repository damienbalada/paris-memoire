import "./globals.css";
import type { Metadata } from "next";
import type { ReactNode } from "react";

export const metadata: Metadata = {
  title: "DIAMS — Diagnostic Indépendant, Auditable et Multi-critères des Sociétés",
  description:
    "DIAMS : score éthique d'entreprise multi-critères, chaque point traçable jusqu'à sa source datée.",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="fr">
      <body>
        <div className="container">
          <header className="row between" style={{ marginBottom: 24 }}>
            <a href="/" title="Diagnostic Indépendant, Auditable et Multi-critères des Sociétés">
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
