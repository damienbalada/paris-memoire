-- =============================================================================
-- Seed 06 : EVIDENCE DE DÉMONSTRATION (Palier 2)
-- -----------------------------------------------------------------------------
-- ⚠️ DONNÉES ILLUSTRATIVES, non vérifiées par la curation humaine. Sert
-- uniquement à tester le moteur de scoring de bout en bout. À remplacer par de
-- l'evidence réelle issue du pipeline (Palier 3). review_status='approved' pour
-- apparaître dans evidence_active.
-- Démontre : héritage groupe→marque, règle 1 (donnée manquante), règle 3
-- (greenwashing : engagement/politique plafonnés), controverse PETA (crowd) avec
-- plancher, et percentile intra-secteur (GOV_BOARD_INDEP entre groupes).
-- =============================================================================

insert into evidence
  (entity_id, indicator_id, source_id, value_type, value_numeric, value_boolean,
   value_text, normalized_value, nature, observed_on, confidence, review_status, reviewer, excerpt)
select
  e.id, i.id, s.id, v.value_type::value_type, v.value_numeric, v.value_boolean,
  v.value_text, v.normalized_value, v.nature::evidence_nature, v.observed_on::date,
  v.confidence, 'approved'::review_status, 'seed-demo', v.excerpt
from (values
  -- KERING (groupe) -------------------------------------------------------
  ('kering','ENV_CDP_CLIMATE','CDP','ordinal',null,null,'A-',0.90,'result','2024-01-15',0.85,'Note CDP Climate A- (démo).'),
  ('kering','ENV_SBTI_VALIDATED','SBTI','category',null,null,'validated_1.5C',1.00,'result','2023-06-01',0.85,'Objectifs validés 1.5°C (démo).'),
  ('kering','SUP_VIGILANCE_PLAN','VIGILANCE_PLAN','ordinal',null,null,'complet',1.00,'result','2024-03-01',0.95,'Plan de vigilance complet (démo).'),
  ('kering','SUP_KNOWTHECHAIN','KNOWTHECHAIN','numeric',55,null,null,0.55,'result','2023-09-01',0.80,'Score KnowTheChain 55/100 (démo).'),
  ('kering','GOV_BOARD_INDEP','AMF','numeric',54,null,null,null,'result','2024-05-01',0.95,'54% administrateurs indépendants (démo).'),
  ('kering','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'suspension',0.70,'result','2023-04-01',0.85,'Suspension des activités en Russie (démo).'),
  ('kering','TAX_CBCR_PUBLISHED','CBCR','boolean',null,true,null,1.00,'result','2024-04-01',0.95,'Reporting pays-par-pays publié (démo).'),
  ('kering','ANI_FUR_FREE','FUR_FREE','boolean',null,true,null,1.00,'result','2022-09-01',0.85,'Politique sans fourrure groupe (démo).'),

  -- HERMÈS (groupe) -------------------------------------------------------
  ('hermes','ENV_CDP_CLIMATE','CDP','ordinal',null,null,'B',0.70,'result','2024-01-20',0.85,'Note CDP Climate B (démo).'),
  ('hermes','ENV_SBTI_VALIDATED','SBTI','category',null,null,'committed',1.00,'commitment','2023-07-01',0.85,'Engagement SBTi (promesse, non validé) (démo).'),
  ('hermes','SUP_VIGILANCE_PLAN','VIGILANCE_PLAN','ordinal',null,null,'complet',1.00,'result','2024-03-15',0.95,'Plan de vigilance complet (démo).'),
  ('hermes','GOV_BOARD_INDEP','AMF','numeric',33,null,null,null,'result','2024-05-01',0.95,'33% administrateurs indépendants (démo).'),
  ('hermes','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'suspension',0.70,'result','2023-04-01',0.85,'Suspension des activités en Russie (démo).'),
  ('hermes','TAX_CBCR_PUBLISHED','CBCR','boolean',null,true,null,1.00,'result','2024-04-01',0.95,'Reporting pays-par-pays publié (démo).'),
  ('hermes','ANI_FUR_FREE','FUR_FREE','boolean',null,true,null,1.00,'result','2022-09-01',0.85,'Pas de fourrure (démo).'),
  ('hermes','ANI_EXOTIC_SKINS','VIGILANCE_PLAN','category',null,null,'none',0.00,'policy','2024-03-15',0.90,'Usage important de peaux exotiques, politique faible (démo).'),
  ('hermes','ANI_EXOTIC_SKINS','PETA','category',null,null,'controversy',1.00,'controversy','2023-05-01',0.60,'Enquête PETA sur élevages de crocodiles (démo, source militante).'),

  -- Autres groupes : distribution pour le percentile GOV_BOARD_INDEP ------
  ('lvmh','GOV_BOARD_INDEP','AMF','numeric',60,null,null,null,'result','2024-05-01',0.95,'60% administrateurs indépendants (démo).'),
  ('richemont','GOV_BOARD_INDEP','AMF','numeric',50,null,null,null,'result','2024-05-01',0.95,'50% administrateurs indépendants (démo).'),
  ('chanel','GOV_BOARD_INDEP','AMF','numeric',40,null,null,null,'result','2024-05-01',0.95,'40% administrateurs indépendants (démo).'),

  -- GUCCI (marque) : evidence propre -------------------------------------
  ('gucci','SUP_FTI_SCORE','FTI','numeric',155,null,null,0.62,'result','2024-02-01',0.80,'Fashion Transparency Index ~155/250 (démo).'),
  ('gucci','ANI_EXOTIC_SKINS','VIGILANCE_PLAN','category',null,null,'policy',0.50,'policy','2023-11-01',0.85,'Réduction progressive des peaux exotiques (démo).'),
  ('gucci','ENV_MATERIAL_CHANGE','TEXTILE_EXCHANGE','ordinal',null,null,'top_tier',0.60,'result','2023-10-01',0.80,'Bon rang Material Change Index (démo).')
) as v(entity_slug, indicator_code, source_code, value_type, value_numeric, value_boolean, value_text, normalized_value, nature, observed_on, confidence, excerpt)
join entities e   on e.slug = v.entity_slug
join indicators i on i.code = v.indicator_code
join sources s    on s.code = v.source_code;