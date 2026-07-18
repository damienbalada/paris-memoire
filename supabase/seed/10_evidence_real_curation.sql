-- =============================================================================
-- Seed 10 : EVIDENCE RÉELLE CURÉE (v1) pour les nouveaux secteurs + compléments.
-- -----------------------------------------------------------------------------
-- Faits publics, datés et sourcés (URL). Curation experte (reviewer=curation-v1)
-- en attendant l'automatisation par connecteurs. On privilégie les faits bien
-- documentés (position Russie via liste Yale, adhésion Fur Free Retailer,
-- statut SBTi, controverses avérées). Confiance modérée (0,70–0,90).
-- =============================================================================

insert into evidence
  (entity_id, indicator_id, source_id, value_type, value_numeric, value_boolean,
   value_text, normalized_value, nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, v.value_type::value_type, v.value_numeric, v.value_boolean,
       v.value_text, v.normalized_value, v.nature::evidence_nature, v.observed_on::date,
       v.confidence, 'approved'::review_status, 'curation-v1', v.source_url, v.excerpt
from (values
  -- INDITEX (Zara)
  ('inditex','ENV_SBTI_VALIDATED','SBTI','category',null::numeric,null::boolean,'validated',1.00,'result','2022-06-01',0.85,'https://sciencebasedtargets.org/companies-taking-action','Objectifs climat validés par la SBTi.'),
  ('inditex','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'withdrawal',1.00,'result','2022-10-01',0.85,'https://www.yalerussianbusinessretreat.com','Fermeture puis cession des activités russes (2022).'),
  ('inditex','ANI_FUR_FREE','FUR_FREE','boolean',null,true,null,1.00,'result','2023-01-01',0.80,'https://furfreeretailer.com','Membre Fur Free Retailer (politique sans fourrure).'),
  -- H&M GROUP
  ('hm-group','ENV_SBTI_VALIDATED','SBTI','category',null,null,'validated',1.00,'result','2022-06-01',0.85,'https://sciencebasedtargets.org/companies-taking-action','Objectifs SBTi validés.'),
  ('hm-group','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'withdrawal',1.00,'result','2022-07-01',0.85,'https://www.yalerussianbusinessretreat.com','Retrait de Russie (2022).'),
  ('hm-group','ANI_FUR_FREE','FUR_FREE','boolean',null,true,null,1.00,'result','2023-01-01',0.80,'https://furfreeretailer.com','Membre Fur Free Retailer.'),
  ('hm-group','SUP_SUPPLIER_LIST','KNOWTHECHAIN','boolean',null,true,null,1.00,'result','2023-01-01',0.80,'https://hmgroup.com/sustainability/leading-the-change/supplier-list/','Publication publique de la liste des fournisseurs.'),
  -- FAST RETAILING (Uniqlo)
  ('fast-retailing','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'suspension',0.70,'result','2022-03-01',0.80,'https://www.yalerussianbusinessretreat.com','Uniqlo a suspendu ses opérations en Russie (mars 2022).'),
  ('fast-retailing','ENV_SBTI_VALIDATED','SBTI','category',null,null,'validated',1.00,'result','2022-09-01',0.75,'https://sciencebasedtargets.org/companies-taking-action','Objectifs SBTi validés.'),
  ('fast-retailing','SUP_BHRRC_ALLEG','BHRRC','numeric',null,null,null,0.70,'controversy','2021-04-01',0.70,'https://www.business-humanrights.org','Enquête (France) liée au coton du Xinjiang dans la chaîne d''approvisionnement (2021).'),
  -- SHEIN
  ('shein','SUP_BHRRC_ALLEG','BHRRC','numeric',null,null,null,0.85,'controversy','2022-11-01',0.80,'https://www.business-humanrights.org','Coton du Xinjiang détecté dans des produits (tests indépendants, 2022).'),
  ('shein','LAB_LIVING_WAGE','PRESS','category',null,null,null,0.80,'controversy','2022-10-01',0.75,'https://www.publiceye.ch/en/topics/fashion/shein','Journées de travail jusqu''à ~75 h/semaine documentées (enquêtes ONG/presse).'),
  ('shein','ENV_SBTI_VALIDATED','SBTI','category',null,null,'none',0.00,'result','2024-01-01',0.70,'https://sciencebasedtargets.org/companies-taking-action','Aucun objectif climat validé par la SBTi à date.'),
  -- APPLE
  ('apple','ENV_SBTI_VALIDATED','SBTI','category',null,null,'validated',1.00,'result','2023-01-01',0.85,'https://sciencebasedtargets.org/companies-taking-action','Objectifs climat validés (trajectoire 1,5°C).'),
  ('apple','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'withdrawal',1.00,'result','2022-03-01',0.85,'https://www.yalerussianbusinessretreat.com','Ventes suspendues en Russie (mars 2022).'),
  ('apple','SUP_BHRRC_ALLEG','BHRRC','numeric',null,null,null,0.55,'controversy','2022-06-01',0.65,'https://www.business-humanrights.org','Conditions de travail chez des sous-traitants (assemblage) régulièrement pointées.'),
  -- SAMSUNG
  ('samsung','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'suspension',0.70,'result','2022-03-01',0.80,'https://www.yalerussianbusinessretreat.com','Expéditions vers la Russie suspendues (mars 2022).'),
  ('samsung','ENV_SBTI_VALIDATED','SBTI','category',null,null,'committed',1.00,'commitment','2022-09-01',0.72,'https://sciencebasedtargets.org/companies-taking-action','Engagement net zéro 2050 / RE100 (SBTi non validée à date).'),
  -- TESLA
  ('tesla','LAB_LITIGATION_RATE','BHRRC','numeric',null,null,null,0.70,'controversy','2022-04-01',0.72,'https://www.business-humanrights.org','Discrimination raciale (verdict Owens v. Tesla) et entraves syndicales constatées.'),
  -- VOLKSWAGEN
  ('volkswagen','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'withdrawal',1.00,'result','2023-05-01',0.85,'https://www.yalerussianbusinessretreat.com','Arrêt de la production puis cession des actifs russes (2023).'),
  ('volkswagen','ENV_SBTI_VALIDATED','SBTI','category',null,null,'committed',1.00,'commitment','2022-01-01',0.70,'https://sciencebasedtargets.org/companies-taking-action','Objectifs climat annoncés (validation SBTi en cours).'),
  -- TOYOTA
  ('toyota','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'withdrawal',1.00,'result','2022-09-01',0.85,'https://www.yalerussianbusinessretreat.com','Arrêt de la production en Russie (usine de Saint-Pétersbourg, 2022).'),
  ('toyota','GEO_LOBBYING_TRANSP','PRESS','boolean',null,false,null,0.60,'controversy','2022-05-01',0.70,'https://influencemap.org/company/Toyota','Classé parmi les acteurs les plus actifs contre les politiques climat (InfluenceMap).'),
  -- MCDONALD'S
  ('mcdonalds','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'withdrawal',1.00,'result','2022-05-01',0.90,'https://www.yalerussianbusinessretreat.com','Sortie de Russie, cession à un opérateur local (2022).'),
  ('mcdonalds','ENV_SBTI_VALIDATED','SBTI','category',null,null,'validated',1.00,'result','2021-03-01',0.80,'https://sciencebasedtargets.org/companies-taking-action','Objectifs SBTi validés.'),
  ('mcdonalds','ANI_BBFAW_TIER','BBFAW','ordinal',null,null,'tier 3',0.60,'result','2023-11-01',0.80,'https://www.bbfaw.com','BBFAW tier 3 (bien-être des animaux d''élevage).'),
  -- STARBUCKS
  ('starbucks','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'withdrawal',1.00,'result','2022-05-01',0.85,'https://www.yalerussianbusinessretreat.com','Sortie de Russie (2022).'),
  ('starbucks','LAB_LITIGATION_RATE','BHRRC','numeric',null,null,null,0.70,'controversy','2023-01-01',0.78,'https://www.business-humanrights.org','Nombreuses infractions au droit du travail constatées lors des campagnes syndicales (NLRB).'),
  ('starbucks','ENV_SBTI_VALIDATED','SBTI','category',null,null,'committed',1.00,'commitment','2021-01-01',0.70,'https://sciencebasedtargets.org/companies-taking-action','Engagements climat (SBTi).'),
  -- TOTALENERGIES
  ('totalenergies','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'buying time',0.20,'result','2022-12-01',0.85,'https://www.yalerussianbusinessretreat.com','Maintien de participations (Novatek/Yamal LNG) malgré la guerre, fortement critiqué.'),
  ('totalenergies','ENV_CDP_CLIMATE','RECLAIM_FINANCE','ordinal',null,null,null,0.70,'controversy','2023-01-01',0.75,'https://reclaimfinance.org','Nouveaux projets fossiles majeurs (EACOP, GNL) jugés incompatibles avec 1,5°C.'),
  -- BNP PARIBAS
  ('bnp-paribas','INV_FOSSIL_FINANCING','RECLAIM_FINANCE','numeric',null,null,null,0.20,'result','2023-01-01',0.80,'https://reclaimfinance.org','Parmi les plus grands financeurs européens des énergies fossiles (Banking on Climate Chaos).')
) as v(entity_slug, indicator_code, source_code, value_type, value_numeric, value_boolean, value_text, normalized_value, nature, observed_on, confidence, source_url, excerpt)
join entities e   on e.slug = v.entity_slug
join indicators i on i.code = v.indicator_code
join sources s    on s.code = v.source_code
on conflict do nothing;
