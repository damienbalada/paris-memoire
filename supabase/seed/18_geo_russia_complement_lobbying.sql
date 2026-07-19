-- =============================================================================
-- Seed 18 : bétonnage GEO — complément Russie (groupes manquants) + lobbying US.
-- =============================================================================

-- Complément « position Russie » sur les groupes qui n'avaient pas de statut.
insert into evidence
  (entity_id, indicator_id, source_id, value_type, value_text, normalized_value,
   nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, 'category'::value_type, v.value_text, v.normalized_value,
       'result'::evidence_nature, v.observed_on::date, v.confidence, 'approved'::review_status, 'curation-v1', v.source_url, v.excerpt
from (values
  ('lvmh','YALE_RUSSIA','suspension',0.70,'2022-03-01',0.78,'https://www.yalerussianbusinessretreat.com','Fermeture des boutiques en Russie (mars 2022), maintien des salariés.'),
  ('richemont','YALE_RUSSIA','suspension',0.70,'2022-03-01',0.75,'https://www.yalerussianbusinessretreat.com','Suspension des activités commerciales en Russie (2022).'),
  ('chanel','YALE_RUSSIA','suspension',0.70,'2022-03-01',0.75,'https://www.yalerussianbusinessretreat.com','Fermeture des boutiques en Russie (2022).'),
  ('shein','YALE_RUSSIA','buying time',0.20,'2023-01-01',0.72,'https://www.yalerussianbusinessretreat.com','Continue d''opérer en Russie (livraisons maintenues).'),
  ('bnp-paribas','YALE_RUSSIA','reduction',0.30,'2023-01-01',0.72,'https://www.yalerussianbusinessretreat.com','Maintien d''une présence bancaire réduite en Russie.'),
  ('amazon','PRESS','non présent',0.50,'2022-03-01',0.55,'https://www.yalerussianbusinessretreat.com','Pas d''activité de vente au détail en Russie ; services numériques suspendus (2022).'),
  ('carrefour','PRESS','non présent',0.50,'2022-01-01',0.55,'https://www.yalerussianbusinessretreat.com','N''exploite pas de magasins en Russie.'),
  ('tesla','PRESS','non présent',0.50,'2022-01-01',0.55,'https://www.yalerussianbusinessretreat.com','Pas de présence commerciale officielle en Russie.'),
  ('schwarz-gruppe','PRESS','non présent',0.50,'2022-01-01',0.55,'https://www.yalerussianbusinessretreat.com','Lidl / Kaufland n''ont jamais opéré en Russie.')
) as v(entity_slug, source_code, value_text, normalized_value, observed_on, confidence, source_url, excerpt)
join entities e on e.slug=v.entity_slug
join indicators i on i.code='GEO_RUSSIA_EXIT'
join sources s on s.code=v.source_code
on conflict do nothing;

-- Lobbying US (OpenSecrets) : transparence (déclaration LDA) + dépenses (contextuel).
insert into evidence
  (entity_id, indicator_id, source_id, value_type, value_boolean, value_numeric, value_text, normalized_value,
   nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, v.vt::value_type, v.vb, v.vn, v.vtx, v.nv,
       'result'::evidence_nature, v.d::date, v.conf, 'approved'::review_status, 'curation-v1', v.url, v.ex
from (values
  ('meta','GEO_LOBBYING_TRANSP','OPENSECRETS','boolean',true,null::numeric,null,0.80,'2024-01-01',0.80,'https://www.opensecrets.org/federal-lobbying/clients/summary?id=D000033563','Lobbying fédéral déclaré (LDA) ; profil public OpenSecrets.'),
  ('amazon','GEO_LOBBYING_TRANSP','OPENSECRETS','boolean',true,null,null,0.80,'2024-01-01',0.80,'https://www.opensecrets.org/orgs/amazon-com/summary','Lobbying fédéral déclaré (LDA) ; profil public OpenSecrets.'),
  ('google','GEO_LOBBYING_TRANSP','OPENSECRETS','boolean',true,null,null,0.80,'2024-01-01',0.80,'https://www.opensecrets.org/orgs/alphabet-inc/summary','Lobbying fédéral déclaré (LDA) ; profil public OpenSecrets.'),
  ('microsoft','GEO_LOBBYING_TRANSP','OPENSECRETS','boolean',true,null,null,0.80,'2024-01-01',0.80,'https://www.opensecrets.org/orgs/microsoft-corp/summary','Lobbying fédéral déclaré (LDA) ; profil public OpenSecrets.'),
  ('apple','GEO_LOBBYING_TRANSP','OPENSECRETS','boolean',true,null,null,0.80,'2024-01-01',0.80,'https://www.opensecrets.org/orgs/apple-inc/summary','Lobbying fédéral déclaré (LDA) ; profil public OpenSecrets.'),
  ('meta','GEO_LOBBYING_SPEND','OPENSECRETS','numeric',null,19300000,null,0.50,'2023-12-31',0.85,'https://time.com/6972134/ai-lobbying-tech-policy-surge/','19,3 M$ de lobbying fédéral (2023) — parmi les 5 premiers lobbyistes US.'),
  ('amazon','GEO_LOBBYING_SPEND','OPENSECRETS','category',null,null,'> 10 M$',0.50,'2023-12-31',0.75,'https://www.opensecrets.org/news/2023/05/federal-lobbying-spending-tops-1-billion-in-first-quarter-2023/','Plus de 10 M$ de lobbying fédéral (2023) — top 5 des dépenses US.'),
  ('google','GEO_LOBBYING_SPEND','OPENSECRETS','category',null,null,'> 10 M$',0.50,'2023-12-31',0.75,'https://www.opensecrets.org/news/2023/01/google-continued-to-ramp-up-federal-lobbying-spending-before-doj-filed-second-antitrust-lawsuit/','Plus de 10 M$ de lobbying fédéral (2023).'),
  ('microsoft','GEO_LOBBYING_SPEND','OPENSECRETS','category',null,null,'> 10 M$',0.50,'2023-12-31',0.75,'https://www.opensecrets.org/news/2025/02/federal-lobbying-set-new-record-in-2024/','Plus de 10 M$ de lobbying fédéral (2023).')
) as v(entity_slug, indicator_code, source_code, vt, vb, vn, vtx, nv, d, conf, url, ex)
join entities e on e.slug=v.entity_slug
join indicators i on i.code=v.indicator_code
join sources s on s.code=v.source_code
on conflict do nothing;
