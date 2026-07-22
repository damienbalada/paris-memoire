-- =============================================================================
-- Seed 28 : blindage pilier Climat (ENV) — salve 3 (finance).
-- CDP Climate confirmé : BNP Paribas (A), Crédit Agricole (A), AXA (B).
-- (Société Générale : note non confirmée -> écartée, pas d'affirmation.
--  SBTi banques : statut « validé » non confirmé -> non renseigné.)
-- =============================================================================

insert into evidence (entity_id, indicator_id, source_id, value_type, value_text, normalized_value,
   nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, 'category'::value_type, v.grade, v.nv,
       'result'::evidence_nature, '2023-12-01'::date, 0.85, 'approved'::review_status, 'curation-v1', v.url, v.ex
from (values
  ('bnp-paribas','A',0.95,'https://group.bnpparibas/en/news/bnp-paribas-continues-to-accelerate-the-financing-of-low-carbon-energies-and-makes-new-commitments-in-its-climate-report-2024','CDP Climat : note A (2023) — parmi les 346 « A-list » mondiales.'),
  ('credit-agricole','A',0.95,'https://rapport-integre.credit-agricole.com/performance/notations-et-reconnaissance-externe/','CDP Climat : note A (Leadership), 2 niveaux au-dessus de la moyenne du secteur.'),
  ('axa','B',0.70,'https://www.axa.com/investor/sri-ratings-ethical-indexes','CDP Climat : note B.')
) as v(slug, grade, nv, url, ex)
join entities e on e.slug=v.slug
join indicators i on i.code='ENV_CDP_CLIMATE'
join sources s on s.code='CDP'
where not exists (select 1 from evidence x where x.entity_id=e.id and x.indicator_id=i.id)
on conflict do nothing;
