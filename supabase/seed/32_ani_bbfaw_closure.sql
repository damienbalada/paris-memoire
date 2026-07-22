-- =============================================================================
-- Seed 32 : pilier ANI — fermeture du volet BBFAW (agro/restauration).
-- Starbucks & Yum! Brands en Tier 6 BBFAW 2024 (« aucune preuve à l'agenda »,
-- plus bas niveau). Faits négatifs documentés. RBI / Bonduelle non confirmés
-- -> non renseignés (pas d'invention).
-- =============================================================================

insert into evidence (entity_id, indicator_id, source_id, value_type, value_text, normalized_value,
   nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, 'category'::value_type, 'Tier 6', 0.10,
       'result'::evidence_nature, '2024-04-26'::date, 0.85, 'approved'::review_status, 'curation-v1', v.url, v.ex
from (values
  ('starbucks','https://www.bbfaw.com/media/2190/bbfaw-2024-report.pdf','BBFAW 2024 : Tier 6 (« aucune preuve à l''agenda ») — plus bas niveau du benchmark bien-être animal.'),
  ('yum-brands','https://www.bbfaw.com/media/2190/bbfaw-2024-report.pdf','BBFAW 2024 : Tier 6 (« aucune preuve à l''agenda »).')
) as v(slug, url, ex)
join entities e on e.slug=v.slug
join indicators i on i.code='ANI_BBFAW_TIER'
join sources s on s.code='BBFAW'
where not exists (select 1 from evidence x where x.entity_id=e.id and x.indicator_id=i.id)
on conflict do nothing;
