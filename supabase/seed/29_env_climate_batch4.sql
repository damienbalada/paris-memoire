-- =============================================================================
-- Seed 29 : blindage pilier Climat (ENV) — salve 4 (auto + agro confirmés).
-- Renault : SBTi validé (1er constructeur ; corrige l'incertitude Toyota).
-- Danone / Nestlé : SBTi validé + CDP A (déjà en base, inclus ici pour la
-- reproductibilité — inserts idempotents).
-- =============================================================================

insert into evidence (entity_id, indicator_id, source_id, value_type, value_boolean, normalized_value,
   nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, 'boolean'::value_type, true, 1.00,
       'result'::evidence_nature, v.d::date, 0.85, 'approved'::review_status, 'curation-v1', v.url, v.ex
from (values
  ('renault','2024-01-01','https://www.renaultgroup.com/en/magazine/sustainable-development/from-first-mover-to-long-term-transformer-why-science-still-sets-the-course-for-renault-groups-climate-ambition/','Objectifs court & long terme validés par la SBTi (1er constructeur, -72% opérations d''ici 2035).'),
  ('danone','2024-04-01','https://www.danone.com/newsroom/press-releases/danone-recognized-for-the-fifth-year-in-a-row-as-global-environm.html','Objectifs net-zéro 2050 (incl. FLAG) validés SBTi (avril 2024).'),
  ('nestle','2020-01-01','https://www.nestle.com/sustainability/climate-change','Objectif net-zéro 2050 (incl. FLAG) validé par la SBTi (dès 2020).')
) as v(slug, d, url, ex)
join entities e on e.slug=v.slug
join indicators i on i.code='ENV_SBTI_VALIDATED'
join sources s on s.code='SBTI'
where not exists (select 1 from evidence x where x.entity_id=e.id and x.indicator_id=i.id)
on conflict do nothing;

insert into evidence (entity_id, indicator_id, source_id, value_type, value_text, normalized_value,
   nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, 'category'::value_type, 'A', 0.95,
       'result'::evidence_nature, '2024-12-01'::date, 0.85, 'approved'::review_status, 'curation-v1',
       'https://www.danone.com/newsroom/press-releases/danone-recognized-for-the-fifth-year-in-a-row-as-global-environm.html',
       'CDP Climat : note A (5e année de triple-A climat/forêts/eau).'
from entities e join indicators i on i.code='ENV_CDP_CLIMATE' join sources s on s.code='CDP'
where e.slug='danone' and not exists (select 1 from evidence x where x.entity_id=e.id and x.indicator_id=i.id)
on conflict do nothing;
