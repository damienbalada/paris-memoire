-- =============================================================================
-- Seed 26 : blindage pilier Climat (ENV) — salve 1 (luxe + boissons).
-- Données réelles sourcées : SBTi (objectifs validés) + CDP Climate (note).
-- Priorité aux groupes à fort effet d'héritage (LVMH/Kering/Richemont portent
-- ~30 marques rattachées).
-- =============================================================================

insert into evidence (entity_id, indicator_id, source_id, value_type, value_boolean, normalized_value,
   nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, 'boolean'::value_type, true, 1.00,
       'result'::evidence_nature, v.d::date, 0.85, 'approved'::review_status, 'curation-v1', v.url, v.ex
from (values
  ('lvmh','2024-01-01','https://www.lvmh.com/en/commitment-in-action/for-the-environment/taking-action-for-the-climate','Trajectoire de décarbonation validée par la SBTi (net-zéro aligné Accord de Paris).'),
  ('kering','2023-01-01','https://sciencebasedtargets.org/news/global-luxury-group-kering-commits-to-industry-and-country-leading-carbon-reduction-targets','1er groupe de luxe / français à faire valider ses objectifs par la SBTi.'),
  ('richemont','2024-01-01','https://www.richemont.com/media/tjbjiob5/richemont-non-financial-report-2024.pdf','Objectifs -46% scope 1&2 d''ici 2030 validés SBTi.'),
  ('pernod-ricard','2024-05-15','https://www.pernod-ricard.com/en/media/pernod-ricard-s-net-zero-science-based-targets-line-15degc-trajectory-validated-science-based','Objectifs net-zéro alignés 1,5°C validés par la SBTi (mai 2024).'),
  ('heineken','2023-01-01','https://www.theheinekencompany.com/sites/heineken-corp/files/heineken-corp/sustainability-and-responsibility/heineken-n-v-annual-report-2023-final-22feb24.pdf','Objectifs net-zéro + FLAG approuvés par la SBTi (2023).')
) as v(slug, d, url, ex)
join entities e on e.slug=v.slug
join indicators i on i.code='ENV_SBTI_VALIDATED'
join sources s on s.code='SBTI'
where not exists (select 1 from evidence x where x.entity_id=e.id and x.indicator_id=i.id)
on conflict do nothing;

insert into evidence (entity_id, indicator_id, source_id, value_type, value_text, normalized_value,
   nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, 'category'::value_type, v.grade, v.nv,
       'result'::evidence_nature, v.d::date, 0.85, 'approved'::review_status, 'curation-v1', v.url, v.ex
from (values
  ('lvmh','A',0.95,'2025-12-01','https://www.lvmh.com/en/commitment-in-action/for-the-environment/taking-action-for-the-climate','CDP Climat : note A (triple-A climat/forêts/eau 2025).'),
  ('richemont','A-',0.85,'2024-01-01','https://www.richemont.com/news-media/press-releases-news/richemont-makes-cdp-s-a-list-for-leadership-in-corporate-sustainability-and-tackling-climate-change/','CDP Climat : note A-.')
) as v(slug, grade, nv, d, url, ex)
join entities e on e.slug=v.slug
join indicators i on i.code='ENV_CDP_CLIMATE'
join sources s on s.code='CDP'
where not exists (select 1 from evidence x where x.entity_id=e.id and x.indicator_id=i.id)
on conflict do nothing;
