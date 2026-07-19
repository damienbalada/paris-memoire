-- =============================================================================
-- Migration 0014 : nouveau pilier « Eau & Plastique » (WAP).
-- -----------------------------------------------------------------------------
-- L'eau et le plastique ne sont pas le climat : enjeux distincts, sources
-- dédiées (Break Free From Plastic, Ellen MacArthur Global Commitment, CDP
-- Water). Pertinents pour boissons/agro/hygiène-beauté/mode/resto, PAS pour
-- tech/auto/banque/énergie → on applique le même mécanisme de pertinence par
-- secteur que le pilier animal (sectors.wap_relevant + exclusion dans le
-- scoring), pour ne pas pénaliser injustement les secteurs non concernés.
-- =============================================================================

-- 1. Dimension
insert into dimensions (code, name, description, display_order)
values ('WAP', 'Eau & Plastique',
        'Empreinte eau (stress hydrique, CDP Water) et plastique (pollution, emballages, engagements).', 9)
on conflict (code) do nothing;

-- 2. Pertinence par secteur
alter table sectors add column if not exists wap_relevant boolean not null default false;
update sectors set wap_relevant = true where code in (
  'beverages','food','fmcg_group','personal_care','beauty_fragrance',
  'fashion_leather','wines_spirits','home_care','restaurant','pet_care','luxury_group'
);

-- 3. Sources dédiées
insert into sources (code, name, tier, url) values
  ('BFFP',   'Break Free From Plastic (audits de marques)', 'audited_ngo', 'https://www.breakfreefromplastic.org/brandaudit/'),
  ('EMF_GC', 'Ellen MacArthur Foundation — Global Commitment', 'audited_ngo', 'https://www.ellenmacarthurfoundation.org/global-commitment-2023/overview')
on conflict (code) do nothing;

-- 4. Indicateurs (sector_specific=false : filtrés par wap_relevant dans le scoring)
insert into indicators (code, name, dimension_id, kind, direction, weight, sector_specific, unit, methodology)
select v.code, v.name, d.id, v.kind::indicator_kind, v.direction::indicator_direction, v.weight, false, v.unit, v.methodology
from (values
  ('WAP_PLASTIC_POLLUTER', 'Pollueur plastique (Break Free From Plastic)', 'categorical', 'higher_better', 1.0, 'rang', 'Présence dans le top des pollueurs plastique mondiaux (audits de marques BFFP).'),
  ('WAP_PLASTIC_COMMITMENT', 'Engagement plastique (Global Commitment)', 'categorical', 'higher_better', 0.7, 'status', 'Signataire du Global Commitment (EMF) avec objectifs de réduction/recyclage.'),
  ('WAP_RECYCLED_CONTENT', 'Part d''emballages recyclés / réutilisables', 'quantitative', 'higher_better', 0.8, '%', 'Part d''emballages en matière recyclée ou réellement réutilisable/recyclable.'),
  ('WAP_WATER_CDP', 'Sécurité de l''eau (CDP Water)', 'ordinal', 'higher_better', 1.0, 'grade', 'Note CDP Water Security (A à D-).'),
  ('WAP_WATER_STEWARDSHIP', 'Gestion de l''eau / stress hydrique', 'categorical', 'higher_better', 0.9, 'status', 'Prélèvements en zones de stress hydrique, controverses d''accaparement, gestion.')
) as v(code, name, kind, direction, weight, unit, methodology)
cross join (select id from dimensions where code='WAP') d
on conflict (code) do nothing;

-- 5. Pondération dans les profils de valeurs (le moteur normalise par la somme).
insert into profile_weights (profile_id, dimension_id, weight)
select p.id, d.id, v.weight
from (values ('ecolo', 0.30), ('equilibre', 0.15), ('transparence', 0.06), ('vivant', 0.10)) as v(code, weight)
join value_profiles p on p.code = v.code
cross join (select id from dimensions where code='WAP') d
on conflict (profile_id, dimension_id) do nothing;

-- 6. compute_score_input : exclut le pilier WAP pour les secteurs non concernés.
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
    and (d.code <> 'WAP' or (select wap_relevant from me_wap))
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
