-- =============================================================================
-- Seed 20 : bétonnage GEO — financement politique.
-- -----------------------------------------------------------------------------
-- Deux réalités distinctes, documentées par sources institutionnelles :
--   • US  : PAC d'entreprise (contributions déclarées, OpenSecrets) — contextuel.
--   • FR  : financement des partis par les entreprises INTERDIT depuis la loi
--           du 19 janvier 1995 (Légifrance) → aucune contribution légale possible.
-- Indicateur contextuel : affiché, non pénalisant en soi.
-- =============================================================================

insert into sources (code, name, tier, url) values
  ('LEGIFRANCE','Légifrance (droit français)','regulatory','https://www.legifrance.gouv.fr')
on conflict (code) do nothing;

-- États-Unis : contributions PAC déclarées (OpenSecrets).
insert into evidence
  (entity_id, indicator_id, source_id, value_type, value_numeric, value_text, normalized_value,
   nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, 'numeric'::value_type, v.amount, v.vtext, 0.50,
       'result'::evidence_nature, '2024-12-31'::date, 0.80, 'approved'::review_status, 'curation-v1', v.url, v.ex
from (values
  ('amazon', 799000::numeric, '≈ 0,80 M$ (cycle 2024)', 'https://www.opensecrets.org/political-action-committees-pacs/amazon-com/C00360354/candidate-recipients/2024',
   'PAC d''entreprise : ≈ 799 k$ versés aux candidats fédéraux (cycle 2023-2024).'),
  ('meta', 341607, '≈ 0,34 M$ (cycle 2024)', 'https://www.opensecrets.org/political-action-committees-pacs/meta/C00502906/summary/2024',
   'PAC d''entreprise : ≈ 342 k$ (cycle 2023-2024).'),
  ('coca-cola', 166650, '≈ 0,17 M$ (cycle 2024)', 'https://www.opensecrets.org/political-action-committees-pacs/coca-cola-co/C00012468/candidate-recipients/2024',
   'PAC d''entreprise : ≈ 167 k$ versés aux candidats fédéraux (cycle 2023-2024).')
) as v(slug, amount, vtext, url, ex)
join entities e on e.slug=v.slug
join indicators i on i.code='GEO_POL_FINANCING'
join sources s on s.code='OPENSECRETS'
where not exists (select 1 from evidence x where x.entity_id=e.id and x.indicator_id=i.id)
on conflict do nothing;

-- France : interdiction légale du financement des partis par les entreprises.
insert into evidence
  (entity_id, indicator_id, source_id, value_type, value_numeric, value_text, normalized_value,
   nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, 'category'::value_type, 0, 'Interdit (loi FR 1995)', 0.50,
       'result'::evidence_nature, '1995-01-19'::date, 0.90, 'approved'::review_status, 'curation-v1',
       'https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000000186650',
       'Groupe de droit français : le financement des partis politiques par les personnes morales (entreprises) est interdit depuis la loi du 19 janvier 1995. Aucune contribution politique légale possible.'
from (values
  ('danone'),('loreal'),('lvmh'),('kering'),('hermes'),('chanel'),('carrefour'),
  ('bnp-paribas'),('axa'),('credit-agricole'),('societe-generale'),('engie'),
  ('renault'),('totalenergies'),('pernod-ricard'),('decathlon'),('lactalis'),
  ('bonduelle'),('groupe-bel')
) as v(slug)
join entities e on e.slug=v.slug
join indicators i on i.code='GEO_POL_FINANCING'
join sources s on s.code='LEGIFRANCE'
where not exists (select 1 from evidence x where x.entity_id=e.id and x.indicator_id=i.id)
on conflict do nothing;
