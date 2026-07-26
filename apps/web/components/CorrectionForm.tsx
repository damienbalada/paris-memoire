"use client";

import { useActionState } from "react";
import { submitCorrection, type CorrectionState } from "@/lib/actions";
import { CORRECTION_KINDS } from "@/lib/corrections";

const INITIAL: CorrectionState = { status: "idle" };

/**
 * Boucle de contribution : un lecteur signale une donnée manquante, fausse ou
 * un lien mort. Le formulaire dit explicitement ce que le signalement fait
 * — ouvrir une revue — et ce qu'il ne fait pas : changer la note.
 */
export function CorrectionForm({
  entitySlug,
  indicators = [],
}: {
  entitySlug: string;
  indicators?: { code: string; name: string }[];
}) {
  const [state, action, pending] = useActionState(submitCorrection, INITIAL);

  return (
    <details className="pillar-card">
      <summary>
        <div className="grade sm grade-none" aria-hidden="true">!</div>
        <div className="pillar-name">
          Signaler une erreur ou une donnée manquante
          <small>Ouvre une revue humaine — la note ne change pas automatiquement</small>
        </div>
        <span className="chev" aria-hidden="true">›</span>
      </summary>

      <div className="pillar-body">
        {state.status === "ok" ? (
          <p className="small" style={{ margin: 0 }}>
            ✅ Signalement enregistré. Il sera examiné manuellement. S'il est fondé,
            il donnera lieu à une <strong>preuve sourcée et datée</strong> — c'est
            elle, et elle seule, qui peut faire bouger la note.
          </p>
        ) : (
          <form action={action} className="form-stack">
            <input type="hidden" name="entity_slug" value={entitySlug} />

            <label className="field">
              <span className="small">Type de signalement</span>
              <select name="kind" defaultValue="missing" required>
                {Object.entries(CORRECTION_KINDS).map(([code, label]) => (
                  <option key={code} value={code}>{label}</option>
                ))}
              </select>
            </label>

            {indicators.length > 0 && (
              <label className="field">
                <span className="small">Indicateur concerné <em className="muted">(facultatif)</em></span>
                <select name="indicator_code" defaultValue="">
                  <option value="">— je ne sais pas / autre —</option>
                  {indicators.map((i) => (
                    <option key={i.code} value={i.code}>{i.name}</option>
                  ))}
                </select>
              </label>
            )}

            <label className="field">
              <span className="small">Ce qui est faux ou manquant</span>
              <textarea
                name="message"
                rows={4}
                minLength={10}
                maxLength={2000}
                required
                placeholder="Ex. : la note de gouvernance ignore la condamnation de mars 2026 par…"
              />
            </label>

            <label className="field">
              <span className="small">
                Lien vers la source <em className="muted">(facultatif, mais décisif)</em>
              </span>
              <input
                name="source_url"
                type="url"
                inputMode="url"
                placeholder="https://…"
              />
            </label>

            <label className="field">
              <span className="small">Contact <em className="muted">(facultatif)</em></span>
              <input name="contact" type="text" maxLength={200} placeholder="e-mail, si vous voulez un retour" />
            </label>

            {state.status === "error" && (
              <p className="badge warn" style={{ whiteSpace: "normal", lineHeight: 1.4 }}>
                ⚠️ {state.message}
              </p>
            )}

            <div className="row" style={{ gap: 10 }}>
              <button className="btn" type="submit" disabled={pending}>
                {pending ? "Envoi…" : "Envoyer le signalement"}
              </button>
            </div>

            <p className="muted small" style={{ margin: 0, lineHeight: 1.45 }}>
              Un signalement <strong>n'est pas une preuve</strong> : il n'entre dans
              aucun calcul. Sans source vérifiable, il a peu de chances d'être retenu
              — c'est le prix de la traçabilité.
            </p>
          </form>
        )}
      </div>
    </details>
  );
}
