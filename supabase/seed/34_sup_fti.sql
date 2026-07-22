-- =============================================================================
-- Seed 34 : pilier SUP — salve 2 : Fashion Transparency Index 2023 (%).
-- Noté au niveau MARQUE quand disponible (Gucci 80 %). « < 30 % » = bande
-- documentée (confiance moindre) pour Louis Vuitton, Dior, Cartier, Hermès.
-- =============================================================================

insert into evidence (entity_id, indicator_id, source_id, value_type, value_numeric, value_text, normalized_value,
   nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, 'numeric'::value_type, v.sc, (v.sc||' %'), (v.sc/100.0),
       'result'::evidence_nature, '2023-01-01'::date, 0.85, 'approved'::review_status, 'curation-v1',
       'https://www.fashionrevolution.org/fashion-transparency-index-2023/', v.ex
from (values
  ('gucci', 80, 'Fashion Transparency Index 2023 : 80 % (2e mondial).'),
  ('hm-group', 71, 'Fashion Transparency Index 2023 : 71 %.'),
  ('inditex', 50, 'Fashion Transparency Index 2023 : 50 % (Zara, marque phare du groupe).')
) as v(slug, sc, ex)
join entities e on e.slug=v.slug
join indicators i on i.code='SUP_FTI_SCORE'
join sources s on s.code='FTI'
where not exists (select 1 from evidence x where x.entity_id=e.id and x.indicator_id=i.id)
on conflict do nothing;

insert into evidence (entity_id, indicator_id, source_id, value_type, value_text, normalized_value,
   nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, 'category'::value_type, '< 30 %', 0.25,
       'result'::evidence_nature, '2023-01-01'::date, 0.70, 'approved'::review_status, 'curation-v1',
       'https://www.fashionrevolution.org/fashion-transparency-index-2023/',
       'Fashion Transparency Index 2023 : sous 30 % (faible transparence de la chaîne).'
from (values ('louis-vuitton'),('dior'),('cartier'),('hermes')) as v(slug)
join entities e on e.slug=v.slug
join indicators i on i.code='SUP_FTI_SCORE'
join sources s on s.code='FTI'
where not exists (select 1 from evidence x where x.entity_id=e.id and x.indicator_id=i.id)
on conflict do nothing;
