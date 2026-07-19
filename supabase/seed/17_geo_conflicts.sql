-- =============================================================================
-- Seed 17 : pilier GEO — implication dans les conflits actuels.
-- -----------------------------------------------------------------------------
-- Principe de NEUTRALITÉ : on ne note QUE des actes attribuables et documentés
-- par des sources institutionnelles (ONU OHCHR, décisions CIJ, faits avérés).
-- Jamais le boycott seul, jamais une opinion. Les faits sensibles entrent en
-- review_status='pending' → validation humaine (/admin/revue) avant de compter.
-- =============================================================================

insert into sources (code, name, tier, url) values
  ('UN_OHCHR','Base de données ONU (OHCHR) — entreprises & colonies','audited_ngo','https://www.ohchr.org/en/hr-bodies/hrc/db-hr-business')
on conflict (code) do nothing;

insert into indicators (code, name, dimension_id, kind, direction, weight, sector_specific, methodology)
select 'GEO_CONFLICT_TIES', 'Implication dans un conflit / une occupation', d.id,
       'categorical'::indicator_kind, 'higher_better'::indicator_direction, 0.8, false,
       'Implication matérielle documentée dans un conflit armé ou une occupation (base ONU OHCHR, décisions CIJ, actes attribuables). Faits institutionnels uniquement — jamais le boycott seul ni une opinion.'
from dimensions d where d.code='GEO'
on conflict (code) do nothing;

-- Faits en attente de revue humaine (n'affectent pas le score tant que non approuvés).
insert into evidence
  (entity_id, indicator_id, source_id, value_type, value_text, normalized_value,
   nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, 'category'::value_type, v.value_text, v.normalized_value,
       'controversy'::evidence_nature, v.observed_on::date, v.confidence, 'pending'::review_status, 'curation-v1', v.source_url, v.excerpt
from (values
  ('mcdonalds','GEO_CONFLICT_TIES','BHRRC','franchisé — soutien armée',0.50,'2024-01-01',0.75,
   'https://www.business-humanrights.org/en/latest-news/israelopt-mcdonalds-sales-hit-by-boycotts-following-israel-based-franchisee-giving-free-meals-to-israeli-soldiers/',
   'Le franchisé israélien de McDonald''s a offert des repas gratuits à l''armée pendant la guerre à Gaza (prise de position dans un conflit). McDonald''s Corp a ensuite racheté ce franchisé (2024).'),
  ('starbucks','GEO_CONFLICT_TIES','BHRRC','poursuite du syndicat',0.45,'2024-01-01',0.72,
   'https://www.business-humanrights.org/en/latest-news/impact-of-boycotts-mcdonalds-and-starbucks-sales-decline-amid-war-on-gaza/',
   'Starbucks a poursuivi en justice son syndicat (Workers United) après un message de soutien à la Palestine — controverse liée au conflit.')
) as v(entity_slug, indicator_code, source_code, value_text, normalized_value, observed_on, confidence, source_url, excerpt)
join entities e on e.slug=v.entity_slug
join indicators i on i.code=v.indicator_code
join sources s on s.code=v.source_code
on conflict do nothing;
