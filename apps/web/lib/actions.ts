"use server";

import { validateCorrection } from "./corrections";
import { insertCorrection } from "./admin";

export interface CorrectionState {
  status: "idle" | "ok" | "error";
  message?: string;
}

/**
 * Server Action du formulaire de signalement. Rejoue la validation côté serveur
 * (le contrôle navigateur n'est qu'un confort) avant d'écrire via la
 * `service_role` — jamais depuis le client.
 */
export async function submitCorrection(
  _prev: CorrectionState,
  formData: FormData,
): Promise<CorrectionState> {
  const raw = Object.fromEntries(formData.entries()) as Record<string, unknown>;
  const parsed = validateCorrection(raw);
  if (!parsed.ok) return { status: "error", message: parsed.error };
  try {
    await insertCorrection(parsed.value);
    return { status: "ok" };
  } catch (e) {
    return { status: "error", message: (e as Error).message };
  }
}
