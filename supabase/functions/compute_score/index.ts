// =============================================================================
// Edge Function : compute_score
// -----------------------------------------------------------------------------
// POST { "entity": "<slug|uuid>", "profile": "<code>" (optionnel) }
//   -> appelle la fonction SQL compute_score_input() (assemblage des entrées :
//      résolution marque→groupe, indicateurs applicables, evidence active,
//      gates, config méthodo), puis applique le moteur pur scoring.ts.
//   -> renvoie { entity, profile, score, confidence, grade, dimensions, groups }
//
// La logique de calcul vit dans scoring.ts (pure, testée). L'assemblage des
// données vit dans la fonction SQL. Ici : juste l'orchestration + I/O.
// =============================================================================
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { computeScore, type ScoreInput } from "./scoring.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const { entity: entityKey, profile: profileCode = "equilibre" } = await req.json();
    if (!entityKey) return json({ error: "Champ 'entity' requis (slug ou uuid)." }, 400);

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // Assemblage des entrées de scoring côté base (résolution d'entités incluse).
    const { data, error } = await supabase.rpc("compute_score_input", {
      p_slug: entityKey,
      p_profile: profileCode,
    });
    if (error) return json({ error: error.message }, 500);
    if (!data || !data.entity) return json({ error: `Entité introuvable: ${entityKey}` }, 404);

    const result = computeScore(data as ScoreInput);

    return json({
      entity: { ...data.entity, ownership_chain: data.ownership_chain },
      profile: data.profile,
      ...result,
    });
  } catch (err) {
    return json({ error: String((err as Error)?.message ?? err) }, 500);
  }
});
