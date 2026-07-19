-- =============================================================================
-- Seed 19 : bétonnage GEO — lobbying UE (Registre de transparence).
-- -----------------------------------------------------------------------------
-- Le Registre de transparence UE est OBLIGATOIRE pour rencontrer les
-- institutions européennes (Commission/Parlement/Conseil). L'inscription est
-- donc un acte de transparence documenté et vérifiable (source regulatory).
-- Les montants sont ceux déclarés par les registrants (contextuels, non
-- pénalisants). Données confirmées via les datacards LobbyFacts (CEO/LobbyControl)
-- qui reflètent le registre officiel.
-- =============================================================================

-- Transparence : inscription au Registre de transparence UE (oui -> 0.80).
insert into evidence
  (entity_id, indicator_id, source_id, value_type, value_boolean, normalized_value,
   nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, 'boolean'::value_type, true, 0.80,
       'result'::evidence_nature, '2024-01-01'::date, 0.85, 'approved'::review_status, 'curation-v1', v.url,
       'Inscrit au Registre de transparence UE (obligatoire pour rencontrer les institutions). Budget lobbying déclaré publiquement.'
from (values
  ('totalenergies','https://www.lobbyfacts.eu/datacard/totalenergies-se?rid=1849405799-88'),
  ('shell','https://www.lobbyfacts.eu/datacard/shell-companies?rid=05032108616-26'),
  ('lvmh','https://www.lobbyfacts.eu/datacard/lvmh-publica?rid=16094042309-21'),
  ('nestle','https://www.lobbyfacts.eu/datacard/nestl%C3%A9-sa?rid=15366395387-57'),
  ('danone','https://www.lobbyfacts.eu/datacard/danone?rid=65744846168-89'),
  ('loreal','https://www.lobbyfacts.eu/datacard/lor%C3%A9al?rid=02776221598-67'),
  ('volkswagen','https://www.lobbyfacts.eu/datacard/volkswagen-aktiengesellschaft?rid=6504541970-40'),
  ('mercedes-benz','https://www.lobbyfacts.eu/datacard/mercedes-benz-group-ag?rid=2349218828-41'),
  ('bnp-paribas','https://www.lobbyfacts.eu/datacard/bnp-paribas?rid=78787381113-69'),
  ('axa','https://www.lobbyfacts.eu/datacard/axa?rid=36423781099-10'),
  ('unilever','https://transparency-register.europa.eu/search-register-or-update/search-register_en'),
  ('bmw','https://transparency-register.europa.eu/search-register-or-update/search-register_en'),
  ('pernod-ricard','https://www.lobbyfacts.eu/datacard/pernod-ricard?rid=352172811-92'),
  ('renault','https://www.lobbyfacts.eu/datacard/renault?rid=946343776-69'),
  ('stellantis','https://www.lobbyfacts.eu/datacard/stellantis?rid=986044541551-20'),
  ('engie','https://www.lobbyfacts.eu/datacard/engie?rid=90947457424-20'),
  ('carrefour','https://www.lobbyfacts.eu/datacard/groupe-carrefour?rid=118080510828-42'),
  ('kering','https://www.lobbyfacts.eu/datacard/kering?rid=465818716727-39'),
  ('heineken','https://www.lobbyfacts.eu/datacard/heineken-nv?rid=827688315793-86'),
  ('adidas','https://lobbyfacts.eu/representative/ee090e7b667242e4af30a637953ac254/adidas-ag')
) as v(slug, url)
join entities e on e.slug=v.slug
join indicators i on i.code='GEO_LOBBYING_TRANSP'
join sources s on s.code='EU_TRANSPARENCY'
where not exists (select 1 from evidence x where x.entity_id=e.id and x.indicator_id=i.id)
on conflict do nothing;

-- Dépenses de lobbying UE déclarées (contextuel, non pénalisant).
insert into evidence
  (entity_id, indicator_id, source_id, value_type, value_numeric, value_text, normalized_value,
   nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, 'numeric'::value_type, v.amount, v.vtext, 0.50,
       'result'::evidence_nature, v.d::date, v.conf, 'approved'::review_status, 'curation-v1', v.url, v.ex
from (values
  ('totalenergies', 3000000::numeric, '≈ 3 M€ (2024)', '2024-12-31', 0.80,
   'https://www.lobbyfacts.eu/datacard/totalenergies-se?rid=1849405799-88',
   'Budget lobbying UE déclaré ≈ 3 M€ (2024) — parmi les plus gros lobbyistes énergie à Bruxelles.'),
  ('shell', 4500000, '≈ 4,5 M€ (2024)', '2024-12-31', 0.80,
   'https://www.lobbyfacts.eu/datacard/shell-companies?rid=05032108616-26',
   'Budget lobbying UE déclaré ≈ 4,5 M€ (2024).'),
  ('volkswagen', 2750000, '≈ 2,75 M€ (2024)', '2024-12-31', 0.80,
   'https://www.lobbyfacts.eu/datacard/volkswagen-aktiengesellschaft?rid=6504541970-40',
   'Budget lobbying UE déclaré ≈ 2,75 M€ (2024) — top 3 des constructeurs automobiles.'),
  ('bnp-paribas', 550000, '≈ 0,55 M€', '2023-12-31', 0.65,
   'https://www.lobbyfacts.eu/datacard/bnp-paribas?rid=78787381113-69',
   'Budget lobbying UE déclaré ≈ 0,55 M€ (Registre de transparence UE).'),
  ('unilever', 550000, '≈ 0,55 M€', '2023-12-31', 0.65,
   'https://transparency-register.europa.eu/search-register-or-update/search-register_en',
   'Budget lobbying UE déclaré ≈ 0,55 M€ (Registre de transparence UE).')
) as v(slug, amount, vtext, d, conf, url, ex)
join entities e on e.slug=v.slug
join indicators i on i.code='GEO_LOBBYING_SPEND'
join sources s on s.code='EU_TRANSPARENCY'
where not exists (select 1 from evidence x where x.entity_id=e.id and x.indicator_id=i.id)
on conflict do nothing;
