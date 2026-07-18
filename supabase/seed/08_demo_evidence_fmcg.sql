-- =============================================================================
-- Seed 08 : EVIDENCE DE DÉMONSTRATION pour les groupes agro/FMCG
-- -----------------------------------------------------------------------------
-- ⚠️ DONNÉES ILLUSTRATIVES, non vérifiées par la curation. Sert à peupler les
-- fiches et le classement. review_status='approved' pour affichage immédiat.
-- BBFAW (bien-être des animaux d'élevage) est particulièrement pertinent ici.
-- =============================================================================

insert into evidence
  (entity_id, indicator_id, source_id, value_type, value_numeric, value_boolean,
   value_text, normalized_value, nature, observed_on, confidence, review_status, reviewer, excerpt)
select e.id, i.id, s.id, v.value_type::value_type, v.value_numeric, v.value_boolean,
       v.value_text, v.normalized_value, v.nature::evidence_nature, v.observed_on::date,
       v.confidence, 'approved'::review_status, 'seed-demo', v.excerpt
from (values
  -- NESTLÉ
  ('nestle','ENV_CDP_CLIMATE','CDP','ordinal',null::numeric,null::boolean,'A-',0.90,'result','2024-01-15',0.85,'CDP Climate A- (démo).'),
  ('nestle','ENV_SBTI_VALIDATED','SBTI','category',null,null,'validated',1.00,'result','2023-06-01',0.85,'Objectifs SBTi validés (démo).'),
  ('nestle','SUP_KNOWTHECHAIN','KNOWTHECHAIN','numeric',45,null,null,0.45,'result','2023-09-01',0.80,'KnowTheChain 45/100 (démo).'),
  ('nestle','TAX_CBCR_PUBLISHED','CBCR','boolean',null,true,null,1.00,'result','2024-04-01',0.90,'CbCR publié (démo).'),
  ('nestle','GOV_BOARD_INDEP','CSRD_ESRS','numeric',62,null,null,null,'result','2024-05-01',0.90,'62% administrateurs indépendants (démo).'),
  ('nestle','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'reduction',0.40,'result','2023-04-01',0.85,'Réduction des activités en Russie (démo).'),
  ('nestle','ANI_BBFAW_TIER','BBFAW','ordinal',null,null,'tier 3',0.60,'result','2023-11-01',0.80,'BBFAW tier 3 (démo).'),
  -- DANONE
  ('danone','ENV_CDP_CLIMATE','CDP','ordinal',null,null,'A-',0.90,'result','2024-01-15',0.85,'CDP Climate A- (démo).'),
  ('danone','ENV_SBTI_VALIDATED','SBTI','category',null,null,'validated',1.00,'result','2023-06-01',0.85,'Objectifs SBTi validés (démo).'),
  ('danone','SUP_VIGILANCE_PLAN','VIGILANCE_PLAN','ordinal',null,null,'complet',1.00,'result','2024-03-01',0.95,'Plan de vigilance complet (démo).'),
  ('danone','SUP_KNOWTHECHAIN','KNOWTHECHAIN','numeric',50,null,null,0.50,'result','2023-09-01',0.80,'KnowTheChain 50/100 (démo).'),
  ('danone','TAX_CBCR_PUBLISHED','CBCR','boolean',null,true,null,1.00,'result','2024-04-01',0.90,'CbCR publié (démo).'),
  ('danone','GOV_BOARD_INDEP','CSRD_ESRS','numeric',58,null,null,null,'result','2024-05-01',0.90,'58% administrateurs indépendants (démo).'),
  ('danone','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'reduction',0.40,'result','2023-04-01',0.85,'Réduction puis cession en Russie (démo).'),
  ('danone','ANI_BBFAW_TIER','BBFAW','ordinal',null,null,'tier 2',0.80,'result','2023-11-01',0.80,'BBFAW tier 2 (démo).'),
  ('danone','LAB_EGAPRO_INDEX','EGAPRO','numeric',88,null,null,0.88,'result','2024-03-01',0.95,'Index Égapro 88/100 (démo).'),
  ('danone','INV_RESPONSIBLE_POLICY','UN_PRI','category',null,null,'entreprise à mission',1.00,'result','2023-01-01',0.85,'Société à mission, politique d''investissement responsable (démo).'),
  -- UNILEVER
  ('unilever','ENV_CDP_CLIMATE','CDP','ordinal',null,null,'A',1.00,'result','2024-01-15',0.85,'CDP Climate A (démo).'),
  ('unilever','ENV_SBTI_VALIDATED','SBTI','category',null,null,'validated',1.00,'result','2023-06-01',0.85,'Objectifs SBTi validés (démo).'),
  ('unilever','SUP_KNOWTHECHAIN','KNOWTHECHAIN','numeric',63,null,null,0.63,'result','2023-09-01',0.80,'KnowTheChain 63/100 (démo).'),
  ('unilever','TAX_CBCR_PUBLISHED','CBCR','boolean',null,true,null,1.00,'result','2024-04-01',0.90,'CbCR publié (démo).'),
  ('unilever','GOV_BOARD_INDEP','CSRD_ESRS','numeric',71,null,null,null,'result','2024-05-01',0.90,'71% administrateurs indépendants (démo).'),
  ('unilever','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'buying time',0.20,'result','2023-04-01',0.85,'Maintien partiel critiqué (démo).'),
  ('unilever','ANI_BBFAW_TIER','BBFAW','ordinal',null,null,'tier 2',0.80,'result','2023-11-01',0.80,'BBFAW tier 2 (démo).'),
  -- L'ORÉAL
  ('loreal','ENV_CDP_CLIMATE','CDP','ordinal',null,null,'A',1.00,'result','2024-01-15',0.85,'CDP Climate A (démo).'),
  ('loreal','ENV_SBTI_VALIDATED','SBTI','category',null,null,'validated',1.00,'result','2023-06-01',0.85,'Objectifs SBTi validés (démo).'),
  ('loreal','SUP_VIGILANCE_PLAN','VIGILANCE_PLAN','ordinal',null,null,'complet',1.00,'result','2024-03-01',0.95,'Plan de vigilance complet (démo).'),
  ('loreal','TAX_CBCR_PUBLISHED','CBCR','boolean',null,true,null,1.00,'result','2024-04-01',0.90,'CbCR publié (démo).'),
  ('loreal','GOV_BOARD_INDEP','CSRD_ESRS','numeric',46,null,null,null,'result','2024-05-01',0.90,'46% administrateurs indépendants, contrôle familial (démo).'),
  ('loreal','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'suspension',0.70,'result','2023-04-01',0.85,'Suspension partielle (démo).'),
  ('loreal','LAB_EGAPRO_INDEX','EGAPRO','numeric',90,null,null,0.90,'result','2024-03-01',0.95,'Index Égapro 90/100 (démo).'),
  ('loreal','ANI_TESTING','PETA','category',null,null,'policy',0.50,'policy','2023-05-01',0.60,'Position tests animaux partielle (démo, source militante).'),
  -- COCA-COLA
  ('coca-cola','ENV_CDP_CLIMATE','CDP','ordinal',null,null,'B',0.70,'result','2024-01-15',0.85,'CDP Climate B (démo).'),
  ('coca-cola','ENV_SBTI_VALIDATED','SBTI','category',null,null,'committed',1.00,'commitment','2023-07-01',0.85,'Engagement SBTi non validé (démo).'),
  ('coca-cola','SUP_KNOWTHECHAIN','KNOWTHECHAIN','numeric',35,null,null,0.35,'result','2023-09-01',0.80,'KnowTheChain 35/100 (démo).'),
  ('coca-cola','TAX_CBCR_PUBLISHED','CBCR','boolean',null,false,null,0.00,'result','2024-04-01',0.85,'Pas de CbCR public (démo).'),
  ('coca-cola','GOV_BOARD_INDEP','CSRD_ESRS','numeric',83,null,null,null,'result','2024-05-01',0.90,'83% administrateurs indépendants (démo).'),
  ('coca-cola','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'withdrawal',1.00,'result','2023-04-01',0.85,'Retrait de Russie (démo).'),
  -- PEPSICO
  ('pepsico','ENV_CDP_CLIMATE','CDP','ordinal',null,null,'B',0.70,'result','2024-01-15',0.85,'CDP Climate B (démo).'),
  ('pepsico','ENV_SBTI_VALIDATED','SBTI','category',null,null,'validated',1.00,'result','2023-06-01',0.85,'Objectifs SBTi validés (démo).'),
  ('pepsico','SUP_KNOWTHECHAIN','KNOWTHECHAIN','numeric',38,null,null,0.38,'result','2023-09-01',0.80,'KnowTheChain 38/100 (démo).'),
  ('pepsico','TAX_CBCR_PUBLISHED','CBCR','boolean',null,false,null,0.00,'result','2024-04-01',0.85,'Pas de CbCR public (démo).'),
  ('pepsico','GOV_BOARD_INDEP','CSRD_ESRS','numeric',80,null,null,null,'result','2024-05-01',0.90,'80% administrateurs indépendants (démo).'),
  ('pepsico','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'reduction',0.40,'result','2023-04-01',0.85,'Réduction des activités (démo).'),
  -- MONDELEZ
  ('mondelez','ENV_CDP_CLIMATE','CDP','ordinal',null,null,'C',0.50,'result','2024-01-15',0.85,'CDP Climate C (démo).'),
  ('mondelez','ENV_SBTI_VALIDATED','SBTI','category',null,null,'committed',1.00,'commitment','2023-07-01',0.85,'Engagement SBTi non validé (démo).'),
  ('mondelez','SUP_KNOWTHECHAIN','KNOWTHECHAIN','numeric',42,null,null,0.42,'result','2023-09-01',0.80,'KnowTheChain 42/100 (démo).'),
  ('mondelez','GOV_BOARD_INDEP','CSRD_ESRS','numeric',82,null,null,null,'result','2024-05-01',0.90,'82% administrateurs indépendants (démo).'),
  ('mondelez','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'buying time',0.20,'result','2023-04-01',0.85,'Maintien critiqué (démo).'),
  ('mondelez','ANI_BBFAW_TIER','BBFAW','ordinal',null,null,'tier 3',0.60,'result','2023-11-01',0.80,'BBFAW tier 3 (démo).'),
  -- PROCTER & GAMBLE
  ('procter-gamble','ENV_CDP_CLIMATE','CDP','ordinal',null,null,'B',0.70,'result','2024-01-15',0.85,'CDP Climate B (démo).'),
  ('procter-gamble','ENV_SBTI_VALIDATED','SBTI','category',null,null,'validated',1.00,'result','2023-06-01',0.85,'Objectifs SBTi validés (démo).'),
  ('procter-gamble','SUP_KNOWTHECHAIN','KNOWTHECHAIN','numeric',55,null,null,0.55,'result','2023-09-01',0.80,'KnowTheChain 55/100 (démo).'),
  ('procter-gamble','TAX_CBCR_PUBLISHED','CBCR','boolean',null,false,null,0.00,'result','2024-04-01',0.85,'Pas de CbCR public (démo).'),
  ('procter-gamble','GOV_BOARD_INDEP','CSRD_ESRS','numeric',89,null,null,null,'result','2024-05-01',0.90,'89% administrateurs indépendants (démo).'),
  ('procter-gamble','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'reduction',0.40,'result','2023-04-01',0.85,'Réduction des activités (démo).')
) as v(entity_slug, indicator_code, source_code, value_type, value_numeric, value_boolean, value_text, normalized_value, nature, observed_on, confidence, excerpt)
join entities e   on e.slug = v.entity_slug
join indicators i on i.code = v.indicator_code
join sources s    on s.code = v.source_code;
