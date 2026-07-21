-- =============================================================================
-- Seed 27 : blindage pilier Climat (ENV) — salve 2 (agro).
-- SBTi : Mars (validé), AB InBev (validé), Kraft Heinz (NON soumis -> 0).
-- Fait négatif assumé : ne pas se faire valider est un choix documenté.
-- (Ferrero : pas de rapport CDP -> laissé en « aucune donnée », noté 0 par la
--  règle d'opacité ; on n'invente pas de valeur.)
-- =============================================================================

insert into evidence (entity_id, indicator_id, source_id, value_type, value_boolean, normalized_value,
   nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, 'boolean'::value_type, v.vb, v.nv,
       'result'::evidence_nature, v.d::date, v.conf, 'approved'::review_status, 'curation-v1', v.url, v.ex
from (values
  ('mars', true, 1.00, '2024-01-01', 0.85, 'https://www.mars.com/about/policies-and-practices/climate-action','Objectif net-zéro 2050 (-80% chaîne de valeur) validé par la SBTi.'),
  ('ab-inbev', true, 1.00, '2024-01-01', 0.80, 'https://sciencebasedtargets.org/target-dashboard','Objectifs science-based validés par la SBTi (suivi publié).'),
  ('kraft-heinz', false, 0.00, '2024-01-01', 0.80, 'https://sciencebasedtargets.org/target-dashboard','N''a pas soumis ses objectifs à la validation SBTi (seule du panel).')
) as v(slug, vb, nv, d, conf, url, ex)
join entities e on e.slug=v.slug
join indicators i on i.code='ENV_SBTI_VALIDATED'
join sources s on s.code='SBTI'
where not exists (select 1 from evidence x where x.entity_id=e.id and x.indicator_id=i.id)
on conflict do nothing;
