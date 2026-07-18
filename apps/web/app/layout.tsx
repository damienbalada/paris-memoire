import "./globals.css";
import type { Metadata } from "next";
import type { ReactNode } from "react";

export const metadata: Metadata = {
  title: "Awareness Score",
  description: "Score éthique d'entreprise, multi-critères, traçable.",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="fr">
      <body>
        <div className="container">
          <header className="row between" style={{ marginBottom: 24 }}>
            <a href="/"><strong>Awareness Score</strong></a>
            <span className="row" style={{ gap: 14 }}>
              <a className="muted small" href="/classement">Classement</a>
              <a className="muted small" href="/methodologie">Méthodologie</a>
            </span>
          </header>
          {children}
        </div>
      </body>
    </html>
  );
}
