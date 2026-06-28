// =============================================================================
// Edge Function : compute_score
// -----------------------------------------------------------------------------
// POST { "entity": "<slug|uuid>", "profile": "<code>" (optionnel) }
//   -> charge entité + ancêtres (résolution marque→groupe), indicateurs
//      applicables, evidence active, config méthodo, puis applique scoring.ts.
//   -> renvoie { entity, profile, score, confidence, grade, dimensions, groups }
//
// La logique de calcul vit dans scoring.ts (pure, testée). Ici : data + I/O.
// =============================================================================
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  computeScore,
  type Evidence,
  type Indicator,
  type Nature,
  type ScoreInput,
  type Tier,
} from "./scoring.ts";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

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

    // --- 1) Entité + chaîne d'ancêtres (résolution d'entités) -----------------
    const col = UUID_RE.test(entityKey) ? "id" : "slug";
    const { data: entity, error: entErr } = await supabase
      .from("entities").select("*").eq(col, entityKey).single();
    if (entErr || !entity) return json({ error: `Entité introuvable: ${entityKey}` }, 404);

    const chain: { id: string; name: string }[] = [
      { id: entity.id, name: entity.display_name ?? entity.legal_name },
    ];
    let cursor = entity.parent_id;
    let guard = 0;
    while (cursor && guard++ < 10) {
      const { data: parent } = await supabase
        .from("entities").select("id, legal_name, display_name, parent_id").eq("id", cursor).single();
      if (!parent) break;
      chain.push({ id: parent.id, name: parent.display_name ?? parent.legal_name });
      cursor = parent.parent_id;
    }
    // specificity : entité notée = la plus haute, ancêtres décroissants
    const specificityById = new Map<string, number>();
    chain.forEach((c, i) => specificityById.set(c.id, chain.length - 1 - i));
    const entityIds = chain.map((c) => c.id);

    // --- 2) Config méthodo, dimensions, groupes ------------------------------
    const [tierRows, natureRows, paramRows, dimRows, groupRows, groupMemberRows] =
      await Promise.all([
        supabase.from("source_tier_config").select("*"),
        supabase.from("evidence_nature_config").select("*"),
        supabase.from("scoring_params").select("*"),
        supabase.from("dimensions").select("code, name"),
        supabase.from("dimension_groups").select("id, code, name"),
        supabase.from("dimension_group_members").select("group_id, weight, dimensions(code)"),
      ]);

    const tierConfig = Object.fromEntries(
      (tierRows.data ?? []).map((t) => [t.tier, {
        evidence_weight: Number(t.evidence_weight),
        max_confidence: Number(t.max_confidence),
        can_penalize_alone: t.can_penalize_alone,
        min_score_floor_alone: Number(t.min_score_floor_alone),
      }]),
    ) as ScoreInput["tierConfig"];

    const natureConfig = Object.fromEntries(
      (natureRows.data ?? []).map((n) => [n.nature, {
        score_multiplier: Number(n.score_multiplier),
        max_score_without_result: n.max_score_without_result === null
          ? null : Number(n.max_score_without_result),
      }]),
    ) as ScoreInput["natureConfig"];

    const p = Object.fromEntries((paramRows.data ?? []).map((r) => [r.key, Number(r.value)]));
    const params = {
      missing_data_score: p["missing_data_score"] ?? 0,
      missing_data_confidence: p["missing_data_confidence"] ?? 0,
      min_confidence_to_publish: p["min_confidence_to_publish"] ?? 0.3,
    };

    const groupIdToCode = new Map((groupRows.data ?? []).map((g) => [g.id, { code: g.code, name: g.name }]));
    const groupMembers = new Map<string, { dimension_code: string; weight: number }[]>();
    for (const m of (groupMemberRows.data ?? []) as any[]) {
      const g = groupIdToCode.get(m.group_id);
      if (!g || !m.dimensions) continue;
      const arr = groupMembers.get(g.code) ?? [];
      arr.push({ dimension_code: m.dimensions.code, weight: Number(m.weight) });
      groupMembers.set(g.code, arr);
    }
    const dimensionGroups = [...groupIdToCode.values()].map((g) => ({
      code: g.code, name: g.name, members: groupMembers.get(g.code) ?? [],
    }));

    // --- 3) Profil de valeurs -------------------------------------------------
    let { data: profile } = await supabase
      .from("value_profiles").select("id, code, name").eq("code", profileCode).maybeSingle();
    if (!profile) {
      const def = await supabase.from("value_profiles").select("id, code, name").eq("is_default", true).single();
      profile = def.data;
    }
    const { data: pwRows } = await supabase
      .from("profile_weights").select("weight, dimensions(code)").eq("profile_id", profile!.id);
    const profileWeights = (pwRows ?? [] as any[])
      .filter((r: any) => r.dimensions)
      .map((r: any) => ({ dimension_code: r.dimensions.code, weight: Number(r.weight) }));

    // --- 4) Indicateurs applicables (filtre secteur) -------------------------
    const { data: indRows } = await supabase
      .from("indicators")
      .select("id, code, kind, direction, weight, sector_specific, applies_to_sector_id, dimensions(code)");
    const applicableIndicators: Indicator[] = (indRows ?? [] as any[])
      .filter((i: any) => !i.sector_specific || i.applies_to_sector_id === entity.sector_id)
      .map((i: any) => ({
        code: i.code,
        dimension_code: i.dimensions.code,
        kind: i.kind,
        direction: i.direction,
        weight: Number(i.weight),
      }));
    const indIdToCode = new Map((indRows ?? []).map((i: any) => [i.id, i.code]));
    const applicableCodes = new Set(applicableIndicators.map((i) => i.code));

    // --- 5) Sources (tier) ----------------------------------------------------
    const { data: srcRows } = await supabase.from("sources").select("id, code, tier");
    const srcById = new Map((srcRows ?? []).map((s) => [s.id, { code: s.code, tier: s.tier as Tier }]));

    // --- 6) Evidence active de l'entité + ancêtres ---------------------------
    const { data: evRows } = await supabase
      .from("evidence_active")
      .select("indicator_id, entity_id, nature, normalized_value, value_numeric, confidence, observed_on, source_id, source_url")
      .in("entity_id", entityIds);
    const evidence: Evidence[] = (evRows ?? [] as any[])
      .map((e: any): Evidence | null => {
        const code = indIdToCode.get(e.indicator_id);
        if (!code || !applicableCodes.has(code)) return null;
        const src = srcById.get(e.source_id);
        return {
          indicator_code: code,
          tier: (src?.tier ?? "press") as Tier,
          nature: e.nature as Nature,
          normalized_value: e.normalized_value === null ? null : Number(e.normalized_value),
          value_numeric: e.value_numeric === null ? null : Number(e.value_numeric),
          confidence: Number(e.confidence),
          observed_on: e.observed_on,
          specificity: specificityById.get(e.entity_id) ?? 0,
          source_code: src?.code,
          source_url: e.source_url ?? undefined,
        };
      })
      .filter((x): x is Evidence => x !== null);

    // --- 7) Valeurs des pairs pour normalisation intra-secteur (quantitatif) --
    const quantCodes = applicableIndicators.filter((i) => i.kind === "quantitative").map((i) => i.code);
    const peerValues: Record<string, number[]> = {};
    if (quantCodes.length > 0 && entity.sector_id) {
      const { data: peerEntities } = await supabase
        .from("entities").select("id").eq("sector_id", entity.sector_id);
      const peerIds = (peerEntities ?? []).map((e) => e.id);
      const quantIds = (indRows ?? []).filter((i: any) => quantCodes.includes(i.code)).map((i: any) => i.id);
      if (peerIds.length && quantIds.length) {
        const { data: peerEv } = await supabase
          .from("evidence_active").select("indicator_id, value_numeric")
          .in("entity_id", peerIds).in("indicator_id", quantIds);
        for (const row of (peerEv ?? []) as any[]) {
          if (row.value_numeric === null) continue;
          const code = indIdToCode.get(row.indicator_id);
          if (!code) continue;
          (peerValues[code] ??= []).push(Number(row.value_numeric));
        }
      }
    }

    // --- 8) Calcul ------------------------------------------------------------
    const result = computeScore({
      applicableIndicators,
      evidence,
      dimensions: (dimRows.data ?? []).map((d) => ({ code: d.code, name: d.name })),
      profileWeights,
      dimensionGroups,
      tierConfig,
      natureConfig,
      params,
      peerValues,
    });

    return json({
      entity: {
        id: entity.id,
        slug: entity.slug,
        name: entity.display_name ?? entity.legal_name,
        ownership_chain: chain.map((c) => c.name),
        sector_id: entity.sector_id,
      },
      profile: { code: profile!.code, name: profile!.name },
      ...result,
    });
  } catch (err) {
    return json({ error: String(err?.message ?? err) }, 500);
  }
});
