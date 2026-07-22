-- =============================================================================
-- Seed 31 : blindage pilier Climat (ENV) — salve 6 (bouclage).
-- SBTi validé : Chanel (net-zéro 2040), RBI, Netflix.
-- NON validé (faits négatifs documentés) : Yum! Brands (engagement retiré),
--   Société Générale (démarche abandonnée en 2023).
-- Restent hors couverture : Ferrero (opaque, pas de CDP), Toyota (statut
--   ambigu entre entités du groupe) — écartés par rigueur.
-- Couverture ENV : 62/64 groupes.
-- =============================================================================

insert into evidence (entity_id, indicator_id, source_id, value_type, value_boolean, normalized_value,
   nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, 'boolean'::value_type, v.vb, v.nv,
       'result'::evidence_nature, v.d::date, v.conf, 'approved'::review_status, 'curation-v1', v.url, v.ex
from (values
  ('chanel', true, 1.00, '2024-04-01', 0.85, 'https://www.esgdive.com/news/chanel-unveils-first-climate-transition-plan-outlines-net-zero-strategy/814965/','Objectif net-zéro 2040 validé par la SBTi (avril 2024).'),
  ('rbi', true, 1.00, '2021-01-01', 0.80, 'https://www.rbi.com/English/sustainability/planet/climate-action/default.aspx','Objectifs science-based (-50% d''ici 2030, net-zéro 2050) fixés via la SBTi.'),
  ('netflix', true, 1.00, '2023-01-01', 0.85, 'https://about.netflix.com/en/news/our-progress-on-sustainability-two-years-in','Deux objectifs validés SBTi (-46% scope 1&2 d''ici 2030).'),
  ('yum-brands', false, 0.00, '2024-01-01', 0.80, 'https://sciencebasedtargets.org/target-dashboard','Engagement SBTi retiré — pas d''objectifs validés.'),
  ('societe-generale', false, 0.00, '2023-01-01', 0.80, 'https://sciencebasedtargets.org/target-dashboard','A abandonné en janvier 2023 sa démarche de validation SBTi.')
) as v(slug, vb, nv, d, conf, url, ex)
join entities e on e.slug=v.slug
join indicators i on i.code='ENV_SBTI_VALIDATED'
join sources s on s.code='SBTI'
where not exists (select 1 from evidence x where x.entity_id=e.id and x.indicator_id=i.id)
on conflict do nothing;
