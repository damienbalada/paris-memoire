-- =============================================================================
-- Migration 0013 : marques « sans intrant animal », nouveaux secteurs, sources
--                  cliquables (remplissage sources.url + fallback dans le scoring).
-- -----------------------------------------------------------------------------
-- 1) Une marque 100 % végétale (ex : Alpro) N'EXPLOITE PAS d'animaux. Le pilier
--    ANI ne doit donc PAS la plafonner à 40 % : au contraire, l'absence
--    d'intrant animal est le meilleur résultat possible sur ce pilier. On ajoute
--    un drapeau entities.animal_free + un indicateur ANI_ANIMAL_FREE, et la
--    fonction de scoring, pour ces entités, note ANI sur ce seul indicateur
--    positif (sans plafond « exploitation »).
-- 2) Nouveaux secteurs pour élargir la couverture.
-- 3) sources.url renseigné pour toutes les sources ; le scoring renvoie
--    coalesce(evidence.source_url, sources.url) afin que TOUTE preuve soit
--    cliquable, même sans URL de document spécifique.
-- =============================================================================

-- 1. Sources cliquables : compléter les URL manquantes (sans écraser l'existant).
update sources set url = v.url from (values
  ('AMF','https://www.amf-france.org'),
  ('BBFAW','https://www.bbfaw.com'),
  ('BHRRC','https://www.business-humanrights.org'),
  ('CBCR','https://www.oecd.org/tax/beps/country-by-country-reporting-appendix-iv.htm'),
  ('CDP','https://www.cdp.net'),
  ('CNCCFP','https://www.cnccfp.fr'),
  ('CSRD_ESRS','https://www.efrag.org'),
  ('DPEF','https://www.economie.gouv.fr'),
  ('EGAPRO','https://egapro.travail.gouv.fr'),
  ('EU_PAY_TRANSP','https://eur-lex.europa.eu/eli/dir/2023/970/oj'),
  ('EU_TRANSPARENCY','https://transparency-register.europa.eu'),
  ('FAIR_WEAR','https://www.fairwear.org'),
  ('FTI','https://www.fashionrevolution.org/about/transparency'),
  ('FUR_FREE','https://furfreeretailer.com'),
  ('GLEIF','https://www.gleif.org'),
  ('HATVP','https://www.hatvp.fr'),
  ('HIGG','https://howtohigg.org'),
  ('INPI_SIRENE','https://data.inpi.fr'),
  ('KNOWTHECHAIN','https://knowthechain.org'),
  ('LWG','https://www.leatherworkinggroup.com'),
  ('OPENCORPORATES','https://opencorporates.com'),
  ('PETA','https://www.peta.org'),
  ('PRUDHOMMES','https://www.justice.fr'),
  ('RECLAIM_FINANCE','https://reclaimfinance.org'),
  ('SBTI','https://sciencebasedtargets.org/companies-taking-action'),
  ('TAX_JUSTICE','https://taxjustice.net'),
  ('TE_STANDARDS','https://textileexchange.org'),
  ('TEXTILE_EXCHANGE','https://textileexchange.org'),
  ('UN_PRI','https://www.unpri.org'),
  ('VIGILANCE_PLAN','https://plan-vigilance.org'),
  ('YALE_RUSSIA','https://www.yalerussianbusinessretreat.com')
) as v(code, url)
where sources.code = v.code and (sources.url is null or sources.url = '');

-- Source pour un fait produit vérifiable (étiquetage réglementé).
insert into sources (code, name, tier) values
  ('PRODUCT_LABEL', 'Étiquetage produit (réglementé)', 'regulatory')
on conflict (code) do nothing;

-- 2. Nouveaux secteurs
insert into sectors (code, name, description, animal_relevant) values
  ('tech_electronics',    'Tech & Électronique',            'Matériel électronique, informatique, logiciels.', false),
  ('automotive',          'Automobile',                     'Constructeurs et équipementiers automobiles.',   false),
  ('restaurant',          'Restauration & Fast-food',       'Chaînes de restauration, cafés, fast-food.',      true),
  ('retail_distribution', 'Distribution & Retail',          'Grande distribution, e-commerce généraliste.',    false),
  ('energy',              'Énergie',                         'Producteurs et distributeurs d''énergie.',        false),
  ('banking_finance',     'Banque & Finance',               'Banques, assurances, gestion d''actifs.',         false),
  ('home_care',           'Entretien & Maison',             'Produits d''entretien et de nettoyage.',          true),
  ('pet_care',            'Animalerie & Petfood',           'Alimentation et soins pour animaux de compagnie.',true)
on conflict (code) do nothing;

-- 3. Drapeau sans intrant animal
alter table entities add column if not exists animal_free boolean not null default false;
comment on column entities.animal_free is
  'Marque 100 % végétale / sans intrant animal : le pilier ANI est noté sur l''absence d''exploitation animale (positif), sans plafond.';
update entities set animal_free = true where slug in ('alpro');

-- 4. Indicateur ANI_ANIMAL_FREE (applicable uniquement aux entités animal_free)
insert into indicators (code, name, dimension_id, kind, direction, weight, sector_specific, methodology)
select 'ANI_ANIMAL_FREE', 'Gamme sans intrant animal (100 % végétale)', d.id,
       'binary', 'higher_better', 1.0, false,
       'Absence totale d''intrant animal : meilleur résultat possible sur le pilier bien-être animal.'
from dimensions d where d.code = 'ANI'
on conflict (code) do nothing;

-- 5. Evidence Alpro : 100 % végétal (fait produit, sourcé)
insert into evidence
  (entity_id, indicator_id, source_id, value_type, value_boolean, normalized_value,
   nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, 'boolean'::value_type, true, 1.00,
       'result'::evidence_nature, '2025-01-01'::date, 0.95, 'approved'::review_status,
       'curation-v1', 'https://www.alpro.com/fr/nos-produits',
       'Alpro : gamme intégralement végétale, aucun intrant d''origine animale.'
from entities e
join indicators i on i.code = 'ANI_ANIMAL_FREE'
join sources s on s.code = 'PRODUCT_LABEL'
where e.slug = 'alpro'
on conflict do nothing;

-- 6. compute_score_input : gestion animal_free + fallback URL source
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
