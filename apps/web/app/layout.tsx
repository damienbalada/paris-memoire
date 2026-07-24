import "./globals.css";
import type { Metadata, Viewport } from "next";
import type { ReactNode } from "react";
import { ThemeToggle } from "@/components/ThemeToggle";

export const metadata: Metadata = {
  title: "DIAMS — Diagnostic Indépendant, Auditable et Multi-critères des Sociétés",
  description:
    "DIAMS : score éthique d'entreprise multi-critères, chaque point traçable jusqu'à sa source datée.",
};

// Zoom laissé libre (pas de maximum-scale) pour l'accessibilité.
export const viewport: Viewport = { width: "device-width", initialScale: 1 };

// Applique la préférence de thème AVANT le premier rendu (évite le flash clair
// sur un thème sombre, et inversement). Volontairement minimal et synchrone.
const THEME_INIT = `try{if(localStorage.getItem('diams-theme')==='light'){document.documentElement.setAttribute('data-theme','light')}}catch(e){}`;

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="fr">
      <head>
        <script dangerouslySetInnerHTML={{ __html: THEME_INIT }} />
      </head>
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
              <ThemeToggle />
            </span>
          </header>
          {children}
        </div>
      </body>
    </html>
  );
}
