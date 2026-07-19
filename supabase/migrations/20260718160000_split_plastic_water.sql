-- =============================================================================
-- Migration 0015 : scinde le pilier « Eau & Plastique » (WAP) en DEUX piliers
--                  distincts — 🧴 Plastique (PLA) et 💧 Eau (WAT) — avec un
--                  PLAFOND « gros pollueur plastique » sur PLA.
-- -----------------------------------------------------------------------------
-- Décisions produit : (A) plafonner la note plastique des pollueurs majeurs
-- (comme l'exploitation animale plafonne ANI) ; (B) afficher eau et plastique
-- séparément → deux dimensions.
-- =============================================================================

-- 1. Nouvelles dimensions
insert into dimensions (code, name, description, display_order) values
  ('PLA', 'Plastique', 'Pollution plastique (Break Free From Plastic), emballages recyclés/réutilisables, réduction du plastique vierge.', 9),
  ('WAT', 'Eau',       'Empreinte eau : note CDP Water, intensité de prélèvement, stress hydrique et controverses.', 10)
on conflict (code) do nothing;

-- 2. Renommage + réaffectation des indicateurs WAP_* vers PLA / WAT
--    (les evidence sont liées par id : le renommage ne les casse pas).
update indicators set code='PLA_POLLUTER',   dimension_id=(select id from dimensions where code='PLA'), weight=0.0 where code='WAP_PLASTIC_POLLUTER';
update indicators set code='PLA_REDUCTION',   dimension_id=(select id from dimensions where code='PLA'), weight=0.7 where code='WAP_PLASTIC_COMMITMENT';
update indicators set code='PLA_RECYCLED',    dimension_id=(select id from dimensions where code='PLA'), weight=0.8 where code='WAP_RECYCLED_CONTENT';
update indicators set code='WAT_CDP',         dimension_id=(select id from dimensions where code='WAT'), weight=1.0 where code='WAP_WATER_CDP';
update indicators set code='WAT_CONTROVERSY', dimension_id=(select id from dimensions where code='WAT'), weight=0.9 where code='WAP_WATER_STEWARDSHIP';

-- 3. Nouvel indicateur : intensité de prélèvement d'eau (percentile intra-secteur)
insert into indicators (code, name, dimension_id, kind, direction, weight, sector_specific, unit, methodology)
select 'WAT_INTENSITY', 'Intensité de prélèvement d''eau', d.id,
       'quantitative'::indicator_kind, 'lower_better'::indicator_direction, 0.8, false, 'm³/M€',
       'Prélèvements d''eau rapportés au chiffre d''affaires, normalisés face aux pairs du secteur.'
from dimensions d where d.code='WAT'
on conflict (code) do nothing;

-- 4. Plafond « gros pollueur plastique » : PLA_POLLUTER pilote le plafond de PLA.
--    default_ceiling = 1.0 : une marque NON classée pollueur n'est pas plafonnée
--    (on ne présume pas le pire, contrairement à l'animal) ; une marque classée
--    voit PLA plafonné par la sévérité de son classement.
insert into dimension_gates (dimension_id, gate_indicator_id, default_ceiling)
select (select id from dimensions where code='PLA'),
       (select id from indicators where code='PLA_POLLUTER'), 1.0
where not exists (
  select 1 from dimension_gates dg join dimensions d on d.id = dg.dimension_id where d.code='PLA'
);

-- 5. Pondérations : on remplace WAP par PLA + WAT dans chaque profil.
delete from profile_weights where dimension_id = (select id from dimensions where code='WAP');
insert into profile_weights (profile_id, dimension_id, weight)
select p.id, d.id, v.weight
from (values
  ('ecolo','PLA',0.15),      ('ecolo','WAT',0.15),
  ('equilibre','PLA',0.08),  ('equilibre','WAT',0.07),
  ('transparence','PLA',0.03),('transparence','WAT',0.03),
  ('vivant','PLA',0.05),     ('vivant','WAT',0.05)
) as v(pcode, dcode, weight)
join value_profiles p on p.code = v.pcode
join dimensions d on d.code = v.dcode
on conflict (profile_id, dimension_id) do nothing;

-- 6. Suppression de l'ancienne dimension WAP (vidée de ses indicateurs/poids).
delete from dimensions where code='WAP';

-- 7. compute_score_input : exclut PLA et WAT pour les secteurs non concernés.
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
me_wap as (
  select coalesce((select s.wap_relevant from sectors s where s.id = (select sector_id from me)), false) as wap_relevant
),
me_flags as (
  select coalesce((select animal_free from entities where slug = p_slug), false) as animal_free
),
maxd as (select max(depth) d from chain),
spec as (select c.id, (select d from maxd) - c.depth as specificity, c.depth, c.name from chain c),
appl as (
  select i.id, i.code, i.name, i.unit, d.code as dimension_code, i.kind, i.direction, i.weight
  from indicators i join dimensions d on d.id = i.dimension_id
  where (i.sector_specific = false or i.applies_to_sector_id = (select sector_id from me))
    and (
      d.code <> 'ANI'
      or (
        (select animal_relevant from me_animal)
        and case
              when (select animal_free from me_flags) then i.code = 'ANI_ANIMAL_FREE'
              else i.code <> 'ANI_ANIMAL_FREE'
            end
      )
    )
    and (d.code not in ('PLA','WAT') or (select wap_relevant from me_wap))
),
ev as (
  select a.code as indicator_code, s.tier, e.nature, e.normalized_value, e.value_numeric,
         e.confidence, e.observed_on, sp.specificity, s.code as source_code,
         coalesce(e.source_url, s.url) as source_url
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
      where d.code <> 'ANI' or ((select animal_relevant from me_animal) and not (select animal_free from me_flags))),
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
