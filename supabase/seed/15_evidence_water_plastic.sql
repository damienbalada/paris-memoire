-- =============================================================================
-- Seed 15 : evidence pilier Eau & Plastique (WAP). Faits publics, sourcés.
-- Plastique : audits Break Free From Plastic (top pollueurs mondiaux).
-- Engagements : Ellen MacArthur Global Commitment. Eau : controverses documentées.
-- =============================================================================

insert into evidence
  (entity_id, indicator_id, source_id, value_type, value_numeric, value_boolean,
   value_text, normalized_value, nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, v.value_type::value_type, v.value_numeric, v.value_boolean,
       v.value_text, v.normalized_value, v.nature::evidence_nature, v.observed_on::date,
       v.confidence, 'approved'::review_status, 'curation-v1', v.source_url, v.excerpt
from (values
  -- Plastique : top pollueurs mondiaux (Break Free From Plastic brand audits)
  ('coca-cola','WAP_PLASTIC_POLLUTER','BFFP','category',null::numeric,null::boolean,'#1 mondial',0.90,'controversy','2023-01-01',0.85,'https://www.breakfreefromplastic.org/brandaudit/','1er pollueur plastique mondial plusieurs années consécutives (audits BFFP).'),
  ('pepsico','WAP_PLASTIC_POLLUTER','BFFP','category',null,null,'#2 mondial',0.80,'controversy','2023-01-01',0.85,'https://www.breakfreefromplastic.org/brandaudit/','2e pollueur plastique mondial (audits BFFP).'),
  ('nestle','WAP_PLASTIC_POLLUTER','BFFP','category',null,null,'#3 mondial',0.75,'controversy','2023-01-01',0.85,'https://www.breakfreefromplastic.org/brandaudit/','3e pollueur plastique mondial (audits BFFP).'),
  ('unilever','WAP_PLASTIC_POLLUTER','BFFP','category',null,null,'top 10',0.60,'controversy','2023-01-01',0.80,'https://www.breakfreefromplastic.org/brandaudit/','Régulièrement dans le top 10 des pollueurs plastique (audits BFFP).'),
  ('mondelez','WAP_PLASTIC_POLLUTER','BFFP','category',null,null,'top 10',0.60,'controversy','2023-01-01',0.80,'https://www.breakfreefromplastic.org/brandaudit/','Régulièrement dans le top 10 des pollueurs plastique (audits BFFP).'),
  ('procter-gamble','WAP_PLASTIC_POLLUTER','BFFP','category',null,null,'top 10',0.55,'controversy','2023-01-01',0.78,'https://www.breakfreefromplastic.org/brandaudit/','Cité parmi les grands pollueurs plastique (audits BFFP).'),
  ('danone','WAP_PLASTIC_POLLUTER','BFFP','category',null,null,'top 10',0.55,'controversy','2023-01-01',0.78,'https://www.breakfreefromplastic.org/brandaudit/','Cité parmi les grands pollueurs plastique (audits BFFP).'),
  ('mars','WAP_PLASTIC_POLLUTER','BFFP','category',null,null,'top 10',0.55,'controversy','2023-01-01',0.75,'https://www.breakfreefromplastic.org/brandaudit/','Cité parmi les grands pollueurs plastique (audits BFFP).'),
  -- Engagement plastique (Global Commitment EMF) — signataires avec objectifs
  ('coca-cola','WAP_PLASTIC_COMMITMENT','EMF_GC','category',null,null,'signataire',0.60,'policy','2023-01-01',0.72,'https://www.ellenmacarthurfoundation.org/global-commitment-2023/overview','Signataire du Global Commitment (objectifs recyclé/réutilisable).'),
  ('nestle','WAP_PLASTIC_COMMITMENT','EMF_GC','category',null,null,'signataire',0.60,'policy','2023-01-01',0.72,'https://www.ellenmacarthurfoundation.org/global-commitment-2023/overview','Signataire du Global Commitment.'),
  ('danone','WAP_PLASTIC_COMMITMENT','EMF_GC','category',null,null,'signataire',0.60,'policy','2023-01-01',0.72,'https://www.ellenmacarthurfoundation.org/global-commitment-2023/overview','Signataire du Global Commitment.'),
  ('unilever','WAP_PLASTIC_COMMITMENT','EMF_GC','category',null,null,'signataire',0.60,'policy','2023-01-01',0.72,'https://www.ellenmacarthurfoundation.org/global-commitment-2023/overview','Signataire du Global Commitment.'),
  ('pepsico','WAP_PLASTIC_COMMITMENT','EMF_GC','category',null,null,'signataire',0.60,'policy','2023-01-01',0.72,'https://www.ellenmacarthurfoundation.org/global-commitment-2023/overview','Signataire du Global Commitment.'),
  ('loreal','WAP_PLASTIC_COMMITMENT','EMF_GC','category',null,null,'signataire',0.60,'policy','2023-01-01',0.72,'https://www.ellenmacarthurfoundation.org/global-commitment-2023/overview','Signataire du Global Commitment.'),
  -- Eau : controverses documentées
  ('coca-cola','WAP_WATER_STEWARDSHIP','PRESS','category',null,null,'controverses',0.60,'controversy','2022-01-01',0.70,'https://www.business-humanrights.org','Controverses récurrentes sur les prélèvements d''eau en zones de stress hydrique (Inde).'),
  ('nestle','WAP_WATER_STEWARDSHIP','PRESS','category',null,null,'controverses',0.60,'controversy','2022-01-01',0.70,'https://www.business-humanrights.org','Controverses sur l''exploitation de l''eau (Vittel, Poland Spring).')
) as v(entity_slug, indicator_code, source_code, value_type, value_numeric, value_boolean, value_text, normalized_value, nature, observed_on, confidence, source_url, excerpt)
join entities e   on e.slug = v.entity_slug
join indicators i on i.code = v.indicator_code
join sources s    on s.code = v.source_code
on conflict do nothing;
