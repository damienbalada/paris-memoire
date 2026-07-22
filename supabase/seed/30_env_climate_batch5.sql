-- =============================================================================
-- Seed 30 : blindage pilier Climat (ENV) — salve 5 (finale).
-- SBTi validé : Kenvue, Bonduelle, Decathlon, Schwarz (Lidl), Lactalis,
--   Groupe Bel, Kellanova. NON validé : Tesla (fait négatif — seul grand
--   constructeur sans engagement net-zéro formel). Barilla : engagement 2025
--   non validé -> nature commitment (plafonné par le moteur).
-- =============================================================================

insert into evidence (entity_id, indicator_id, source_id, value_type, value_boolean, normalized_value,
   nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, 'boolean'::value_type, v.vb, v.nv,
       'result'::evidence_nature, v.d::date, v.conf, 'approved'::review_status, 'curation-v1', v.url, v.ex
from (values
  ('kenvue', true, 1.00, '2024-05-01', 0.85, 'https://www.kenvue.com/media/healthy-lives-mission-science-based-targets-validation','Objectifs court terme validés SBTi (1,5°C, -42% scope 1&2 d''ici 2030).'),
  ('bonduelle', true, 1.00, '2024-01-01', 0.80, 'https://sciencebasedtargets.org/target-dashboard','Objectifs validés par la SBTi.'),
  ('decathlon', true, 1.00, '2024-01-01', 0.85, 'https://www.decathlon-united.media/pressfiles/sbti-press-release','Objectifs court & long terme alignés 1,5°C validés SBTi.'),
  ('schwarz-gruppe', true, 1.00, '2025-01-01', 0.85, 'https://gruppe.schwarz/en/press/archive/2025/sbti-validation-confirms-companies-of-schwarz-group-are-on-track-for-climate-action','Objectifs court terme (2030/2034) + net-zéro 2050 validés SBTi.'),
  ('lactalis', true, 1.00, '2024-01-01', 0.85, 'https://www.lactalisingredients.com/news/lactalis-group-achieves-sbti-validation-for-net-zero-targets/','Trajectoire -46,2% scope 1&2 d''ici 2030 validée SBTi (2024).'),
  ('groupe-bel', true, 1.00, '2024-01-01', 0.85, 'https://www.groupe-bel.com/en/our-journey/our-commitments/climate-water-biodiversity/','Trajectoire net-zéro <1,5°C validée par la SBTi.'),
  ('kellanova', true, 1.00, '2024-01-01', 0.85, 'https://betterdayspromise.kellanova.com/climate-action','Objectif net-zéro 2050 validé par la SBTi.'),
  ('tesla', false, 0.00, '2024-01-01', 0.80, 'https://sciencebasedtargets.org/target-dashboard','Pas d''objectifs validés SBTi — seul grand constructeur sans engagement net-zéro formel.')
) as v(slug, vb, nv, d, conf, url, ex)
join entities e on e.slug=v.slug
join indicators i on i.code='ENV_SBTI_VALIDATED'
join sources s on s.code='SBTI'
where not exists (select 1 from evidence x where x.entity_id=e.id and x.indicator_id=i.id)
on conflict do nothing;

insert into evidence (entity_id, indicator_id, source_id, value_type, value_text, normalized_value,
   nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, 'category'::value_type, 'engagement SBTi (non validé)', 1.00,
       'commitment'::evidence_nature, '2025-01-01'::date, 0.75, 'approved'::review_status, 'curation-v1',
       'https://www.barillagroup.com/en/sustainability/climate/',
       'Engagement pris auprès de la SBTi en 2025 ; objectifs pas encore validés (traité comme promesse).'
from entities e join indicators i on i.code='ENV_SBTI_VALIDATED' join sources s on s.code='SBTI'
where e.slug='barilla' and not exists (select 1 from evidence x where x.entity_id=e.id and x.indicator_id=i.id)
on conflict do nothing;
