-- =============================================================================
-- Seed 33 : pilier SUP (droits humains / travail forcé) — salve 1.
-- Scores KnowTheChain (Business & Human Rights Resource Centre), /100.
-- Habillement/chaussures 2023 + ICT 2025 (Samsung). normalized = score/100.
-- =============================================================================

insert into evidence (entity_id, indicator_id, source_id, value_type, value_numeric, value_text, normalized_value,
   nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, 'numeric'::value_type, v.sc, (v.sc||'/100'), (v.sc/100.0),
       'result'::evidence_nature, v.d::date, 0.85, 'approved'::review_status, 'curation-v1', v.url, v.ex
from (values
  ('adidas', 55, '2023-12-01', 'https://www.business-humanrights.org/en/from-us/briefings/2023-knowthechain-apparel-footwear-benchmark/','KnowTheChain 2023 (travail forcé, habillement) : 55/100.'),
  ('hm-group', 49, '2023-12-01', 'https://www.business-humanrights.org/en/from-us/briefings/2023-knowthechain-apparel-footwear-benchmark/','KnowTheChain 2023 : 49/100.'),
  ('nike', 48, '2023-12-01', 'https://www.business-humanrights.org/en/from-us/briefings/2023-knowthechain-apparel-footwear-benchmark/','KnowTheChain 2023 : 48/100.'),
  ('inditex', 38, '2023-12-01', 'https://www.business-humanrights.org/en/from-us/briefings/2023-knowthechain-apparel-footwear-benchmark/','KnowTheChain 2023 : 38/100.'),
  ('fast-retailing', 38, '2023-12-01', 'https://www.business-humanrights.org/en/from-us/briefings/2023-knowthechain-apparel-footwear-benchmark/','KnowTheChain 2023 : 38/100 (15e).'),
  ('kering', 23, '2023-12-01', 'https://www.business-humanrights.org/en/from-us/briefings/2023-knowthechain-apparel-footwear-benchmark/','KnowTheChain 2023 : 23/100.'),
  ('lvmh', 6, '2023-12-01', 'https://www.business-humanrights.org/en/from-us/briefings/2023-knowthechain-apparel-footwear-benchmark/','KnowTheChain 2023 : 6/100 — très bas sur la lutte contre le travail forcé.'),
  ('samsung', 61, '2025-01-01', 'https://www.business-humanrights.org/en/from-us/briefings/2025-knowthechain-ict-benchmark/','KnowTheChain ICT 2025 : 61/100 (parmi les 3 seules entreprises tech > 50).')
) as v(slug, sc, d, url, ex)
join entities e on e.slug=v.slug
join indicators i on i.code='SUP_KNOWTHECHAIN'
join sources s on s.code='KNOWTHECHAIN'
where not exists (select 1 from evidence x where x.entity_id=e.id and x.indicator_id=i.id)
on conflict do nothing;
