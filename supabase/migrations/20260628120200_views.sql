-- =============================================================================
-- Migration 0003 : vues (faits actifs + indice de confiance)
-- -----------------------------------------------------------------------------
--   * evidence_active        : evidence approuvées et non périmées (< 5 ans).
--   * entity_dimension_coverage / entity_coverage : indice de confiance,
--     = part des indicateurs applicables effectivement couverts par une
--       evidence active. C'est l'indice "Fiabilité" affiché À PART du score.
-- =============================================================================

-- Faits actifs : approuvés ET dans l'horizon de 5 ans.
create view evidence_active as
select e.*
from evidence e
where e.review_status = 'approved'
  and e.valid_until >= current_date;

comment on view evidence_active is
  'Evidence validées et non périmées (observed_on de moins de 5 ans). Base de tout calcul de score.';

-- Indicateurs applicables à une entité, compte tenu de son secteur.
-- Un indicateur sector_specific ne compte que pour les entités du bon secteur.
create view entity_applicable_indicators as
select
  en.id as entity_id,
  i.id  as indicator_id,
  i.dimension_id
from entities en
join indicators i
  on i.sector_specific = false
     or (i.sector_specific = true and i.applies_to_sector_id = en.sector_id);

comment on view entity_applicable_indicators is
  'Pour chaque entité, les indicateurs qui la concernent (en tenant compte de la spécificité sectorielle).';

-- Couverture par entité ET dimension (indice de confiance fin).
create view entity_dimension_coverage as
select
  ai.entity_id,
  ai.dimension_id,
  count(distinct ai.indicator_id) as applicable_indicators,
  count(distinct ea.indicator_id) as covered_indicators,
  case
    when count(distinct ai.indicator_id) = 0 then 0
    else round(count(distinct ea.indicator_id)::numeric
               / count(distinct ai.indicator_id), 4)
  end as coverage_ratio
from entity_applicable_indicators ai
left join evidence_active ea
  on ea.entity_id = ai.entity_id
 and ea.indicator_id = ai.indicator_id
group by ai.entity_id, ai.dimension_id;

comment on view entity_dimension_coverage is
  'Indice de confiance par dimension : part des indicateurs applicables couverts par une evidence active.';

-- Couverture globale par entité (indice de confiance affiché).
create view entity_coverage as
select
  entity_id,
  sum(applicable_indicators) as applicable_indicators,
  sum(covered_indicators)    as covered_indicators,
  case
    when sum(applicable_indicators) = 0 then 0
    else round(sum(covered_indicators)::numeric
               / sum(applicable_indicators), 4)
  end as coverage_ratio
from entity_dimension_coverage
group by entity_id;

comment on view entity_coverage is
  'Indice de confiance global d''une entité. Affiché SÉPARÉMENT du score (ex: "Note B / Fiabilité 40%").';
