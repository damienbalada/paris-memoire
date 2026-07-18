-- =============================================================================
-- Migration 0012 : pertinence animale par secteur
-- -----------------------------------------------------------------------------
-- Une marque d'eau / soda n'a pas d'intrant animal : le pilier « bien-être
-- animal » ne doit pas s'y appliquer (ni être plafonné par défaut). On marque
-- les secteurs sans enjeu animal, et la fonction de scoring EXCLUT alors le
-- pilier ANI (indicateurs + plafond) pour ces entités — le pilier n'apparaît
-- tout simplement pas, au lieu d'être noté 0/plafonné.
-- =============================================================================

alter table sectors add column if not exists animal_relevant boolean not null default true;

-- Boissons (eau, sodas, café) : aucun intrant animal.
update sectors set animal_relevant = false where code = 'beverages';

-- Fonction de scoring : exclut le pilier ANI quand le secteur n'a pas d'enjeu animal.
create or replace function compute_score_input(p_slug text, p_profile text default 'equilibre')
returns jsonb
language sql
stable
set search_path = public
as $$
with recursive chain as (
  select id, parent_id, 0 as depth, sector_id, slug, coalesce(display_name, legal_name) as name
  from entities where slug = p_slug
  union all
  select e.id, e.parent_id, c.depth+1, e.sector_id, e.slug, coalesce(e.display_name, e.legal_name)
  from entities e join chain c on e.id = c.parent_id
),
me as (select * from chain where depth = 0),
me_animal as (
  select coalesce((select s.animal_relevant from sectors s where s.id = (select sector_id from me)), true) as animal_relevant
),
maxd as (select max(depth) d from chain),
spec as (select c.id, (select d from maxd) - c.depth as specificity, c.depth, c.name from chain c),
appl as (
  select i.id, i.code, i.name, i.unit, d.code as dimension_code, i.kind, i.direction, i.weight
  from indicators i join dimensions d on d.id = i.dimension_id
  where (i.sector_specific = false or i.applies_to_sector_id = (select sector_id from me))
    and (d.code <> 'ANI' or (select animal_relevant from me_animal))
),
ev as (
  select a.code as indicator_code, s.tier, e.nature, e.normalized_value, e.value_numeric,
         e.confidence, e.observed_on, sp.specificity, s.code as source_code, e.source_url
  from evidence_active e
  join spec sp on sp.id = e.entity_id
  join appl a  on a.id = e.indicator_id
  join sources s on s.id = e.source_id
),
peer as (
  select a.code as indicator_code, e.value_numeric
  from evidence_active e
  join appl a on a.id = e.indicator_id and a.kind = 'quantitative'
  join entities en on en.id = e.entity_id and en.sector_id = (select sector_id from me)
  where e.value_numeric is not null
),
prof as (
  select p.id, p.code, p.name from value_profiles p where p.code = p_profile
  union all
  select p.id, p.code, p.name from value_profiles p
  where p.is_default and not exists (select 1 from value_profiles where code = p_profile)
)
select jsonb_build_object(
  'entity', (select jsonb_build_object('slug', slug, 'name', name, 'sector_id', sector_id) from me),
  'ownership_chain', (select jsonb_agg(name order by depth) from spec),
  'profile', (select jsonb_build_object('code', code, 'name', name) from prof limit 1),
  'applicableIndicators', (select coalesce(jsonb_agg(jsonb_build_object(
      'code', code, 'name', name, 'unit', unit,
      'dimension_code', dimension_code, 'kind', kind, 'direction', direction, 'weight', weight)), '[]') from appl),
  'evidence', (select coalesce(jsonb_agg(jsonb_build_object(
      'indicator_code', indicator_code, 'tier', tier, 'nature', nature, 'normalized_value', normalized_value,
      'value_numeric', value_numeric, 'confidence', confidence, 'observed_on', observed_on,
      'specificity', specificity, 'source_code', source_code, 'source_url', source_url)), '[]') from ev),
  'dimensions', (select jsonb_agg(jsonb_build_object('code', code, 'name', name)) from dimensions),
  'profileWeights', (select coalesce(jsonb_agg(jsonb_build_object('dimension_code', d.code, 'weight', pw.weight)), '[]')
      from profile_weights pw join dimensions d on d.id = pw.dimension_id where pw.profile_id = (select id from prof limit 1)),
  'dimensionGroups', (select coalesce(jsonb_agg(jsonb_build_object('code', dg.code, 'name', dg.name,
      'members', (select coalesce(jsonb_agg(jsonb_build_object('dimension_code', d.code, 'weight', m.weight)), '[]')
                  from dimension_group_members m join dimensions d on d.id = m.dimension_id where m.group_id = dg.id))), '[]')
      from dimension_groups dg),
  'dimensionGates', (select coalesce(jsonb_agg(jsonb_build_object(
      'dimension_code', d.code, 'gate_indicator_code', gi.code, 'default_ceiling', dgt.default_ceiling)), '[]')
      from dimension_gates dgt join dimensions d on d.id = dgt.dimension_id join indicators gi on gi.id = dgt.gate_indicator_id
      where d.code <> 'ANI' or (select animal_relevant from me_animal)),
  'tierConfig', (select jsonb_object_agg(tier, jsonb_build_object('evidence_weight', evidence_weight,
      'max_confidence', max_confidence, 'can_penalize_alone', can_penalize_alone,
      'min_score_floor_alone', min_score_floor_alone)) from source_tier_config),
  'natureConfig', (select jsonb_object_agg(nature, jsonb_build_object('score_multiplier', score_multiplier,
      'max_score_without_result', max_score_without_result)) from evidence_nature_config),
  'params', (select jsonb_object_agg(key, value) from scoring_params),
  'peerValues', (select coalesce(jsonb_object_agg(indicator_code, vals), '{}')
      from (select indicator_code, jsonb_agg(value_numeric) as vals from peer group by indicator_code) pp)
);
$$;
