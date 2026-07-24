"use client";

import { useEffect, useState } from "react";

// Bascule clair/sombre. Le thème est stocké dans localStorage et appliqué en
// `data-theme` sur <html> (les tokens CSS font le reste). Le script inline de
// layout.tsx applique la préférence AVANT le rendu pour éviter le flash.
export function ThemeToggle() {
  const [theme, setTheme] = useState<"dark" | "light">("dark");

  useEffect(() => {
    const current = document.documentElement.getAttribute("data-theme");
    setTheme(current === "light" ? "light" : "dark");
  }, []);

  const toggle = () => {
    const next = theme === "dark" ? "light" : "dark";
    setTheme(next);
    if (next === "light") document.documentElement.setAttribute("data-theme", "light");
    else document.documentElement.removeAttribute("data-theme");
    try {
      localStorage.setItem("diams-theme", next);
    } catch {
      // navigation privée / stockage indisponible : la bascule reste valable
      // pour la session en cours, on n'a rien d'autre à faire.
    }
  };

  return (
    <button
      type="button"
      className="theme-toggle"
      onClick={toggle}
      aria-label={theme === "dark" ? "Passer au thème clair" : "Passer au thème sombre"}
      aria-pressed={theme === "light"}
    >
      <span aria-hidden="true">☾</span>
      <span className="knob" />
      <span aria-hidden="true">☀</span>
    </button>
  );
}
