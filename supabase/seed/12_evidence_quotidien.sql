-- =============================================================================
-- Seed 12 : evidence réelle curée (v1) pour les marques du quotidien + compléments.
-- Faits publics datés et sourcés. reviewer=curation-v1. Confiance 0,70–0,90.
-- =============================================================================

insert into evidence
  (entity_id, indicator_id, source_id, value_type, value_numeric, value_boolean,
   value_text, normalized_value, nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, v.value_type::value_type, v.value_numeric, v.value_boolean,
       v.value_text, v.normalized_value, v.nature::evidence_nature, v.observed_on::date,
       v.confidence, 'approved'::review_status, 'curation-v1', v.source_url, v.excerpt
from (values
  -- MARS
  ('mars','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null::numeric,null::boolean,'buying time',0.20,'result','2023-01-01',0.80,'https://www.yalerussianbusinessretreat.com','Maintien des activités en Russie malgré la guerre (fortement critiqué).'),
  ('mars','ANI_BBFAW_TIER','BBFAW','ordinal',null,null,'tier 3',0.60,'result','2023-11-01',0.75,'https://www.bbfaw.com','BBFAW tier 3 (bien-être des animaux d''élevage).'),
  -- FERRERO
  ('ferrero','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'buying time',0.20,'result','2023-01-01',0.80,'https://www.yalerussianbusinessretreat.com','Maintien des activités en Russie (critiqué).'),
  ('ferrero','SUP_BHRRC_ALLEG','BHRRC','numeric',null,null,null,0.55,'controversy','2022-01-01',0.65,'https://www.business-humanrights.org','Allégations récurrentes de travail des enfants dans la filière cacao.'),
  -- LACTALIS
  ('lactalis','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'buying time',0.20,'result','2023-01-01',0.78,'https://www.yalerussianbusinessretreat.com','Maintien des activités en Russie.'),
  -- GROUPE BEL
  ('groupe-bel','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'withdrawal',1.00,'result','2022-10-01',0.70,'https://www.yalerussianbusinessretreat.com','Cession des activités russes (2022).'),
  -- CARREFOUR
  ('carrefour','ENV_SBTI_VALIDATED','SBTI','category',null,null,'validated',1.00,'result','2023-01-01',0.80,'https://sciencebasedtargets.org/companies-taking-action','Objectifs climat validés par la SBTi.'),
  ('carrefour','SUP_VIGILANCE_PLAN','VIGILANCE_PLAN','ordinal',null,null,'complet',1.00,'result','2024-03-01',0.85,'https://plan-vigilance.org','Plan de vigilance publié (loi française de 2017).'),
  -- NIKE
  ('nike','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'withdrawal',1.00,'result','2022-06-01',0.85,'https://www.yalerussianbusinessretreat.com','Retrait du marché russe (2022).'),
  ('nike','ENV_SBTI_VALIDATED','SBTI','category',null,null,'validated',1.00,'result','2022-06-01',0.80,'https://sciencebasedtargets.org/companies-taking-action','Objectifs SBTi validés.'),
  ('nike','ANI_FUR_FREE','FUR_FREE','boolean',null,true,null,1.00,'result','2023-01-01',0.75,'https://furfreeretailer.com','Politique sans fourrure.'),
  ('nike','SUP_BHRRC_ALLEG','BHRRC','numeric',null,null,null,0.70,'controversy','2021-04-01',0.72,'https://www.business-humanrights.org','Allégations de travail forcé (coton du Xinjiang) dans la chaîne d''approvisionnement.'),
  -- ADIDAS
  ('adidas','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'withdrawal',1.00,'result','2022-06-01',0.85,'https://www.yalerussianbusinessretreat.com','Suspension puis retrait de Russie (2022).'),
  ('adidas','ENV_SBTI_VALIDATED','SBTI','category',null,null,'validated',1.00,'result','2022-06-01',0.80,'https://sciencebasedtargets.org/companies-taking-action','Objectifs SBTi validés.'),
  ('adidas','ANI_FUR_FREE','FUR_FREE','boolean',null,true,null,1.00,'result','2023-01-01',0.75,'https://furfreeretailer.com','Politique sans fourrure.'),
  ('adidas','SUP_BHRRC_ALLEG','BHRRC','numeric',null,null,null,0.70,'controversy','2021-04-01',0.72,'https://www.business-humanrights.org','Allégations de travail forcé (coton du Xinjiang) dans la chaîne d''approvisionnement.'),
  -- DECATHLON
  ('decathlon','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'withdrawal',1.00,'result','2022-06-01',0.78,'https://www.yalerussianbusinessretreat.com','Fermeture puis cession des activités russes (2022).'),
  ('decathlon','SUP_VIGILANCE_PLAN','VIGILANCE_PLAN','ordinal',null,null,'complet',1.00,'result','2024-03-01',0.80,'https://plan-vigilance.org','Plan de vigilance publié (loi française de 2017).'),
  -- RENAULT
  ('renault','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'withdrawal',1.00,'result','2022-05-01',0.85,'https://www.yalerussianbusinessretreat.com','Cession de ses actifs russes, dont AvtoVAZ/Lada (2022).'),
  -- ENGIE
  ('engie','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'reduction',0.40,'result','2022-12-01',0.75,'https://www.yalerussianbusinessretreat.com','Réduction de sa dépendance au gaz russe.'),
  ('engie','ENV_CDP_CLIMATE','RECLAIM_FINANCE','ordinal',null,null,null,0.60,'controversy','2023-01-01',0.70,'https://reclaimfinance.org','Poids persistant du gaz fossile dans le mix, jugé insuffisamment aligné avec 1,5°C.'),
  -- CRÉDIT AGRICOLE
  ('credit-agricole','INV_FOSSIL_FINANCING','RECLAIM_FINANCE','numeric',null,null,null,0.25,'result','2023-01-01',0.80,'https://reclaimfinance.org','Parmi les grands financeurs des énergies fossiles (Banking on Climate Chaos).'),
  ('credit-agricole','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'buying time',0.20,'result','2023-01-01',0.72,'https://www.yalerussianbusinessretreat.com','Maintien d''activités en Russie (critiqué).'),
  -- GOOGLE / ALPHABET
  ('google','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'withdrawal',1.00,'result','2022-03-01',0.82,'https://www.yalerussianbusinessretreat.com','Suspension des ventes et services publicitaires en Russie (2022).'),
  ('google','ENV_SBTI_VALIDATED','SBTI','category',null,null,'committed',1.00,'commitment','2022-01-01',0.70,'https://sciencebasedtargets.org/companies-taking-action','Objectif zéro net 2030 annoncé (validation SBTi en cours).'),
  -- MICROSOFT
  ('microsoft','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'withdrawal',1.00,'result','2022-03-01',0.85,'https://www.yalerussianbusinessretreat.com','Suspension des ventes en Russie (2022).'),
  ('microsoft','ENV_SBTI_VALIDATED','SBTI','category',null,null,'validated',1.00,'result','2022-06-01',0.82,'https://sciencebasedtargets.org/companies-taking-action','Objectifs SBTi validés.'),
  -- AMAZON
  ('amazon','ENV_SBTI_VALIDATED','SBTI','category',null,null,'committed',1.00,'commitment','2022-01-01',0.72,'https://sciencebasedtargets.org/companies-taking-action','« Climate Pledge » (net zéro 2040) non validé par la SBTi.'),
  ('amazon','LAB_LITIGATION_RATE','BHRRC','numeric',null,null,null,0.65,'controversy','2023-01-01',0.72,'https://www.business-humanrights.org','Conditions de travail en entrepôts et entraves syndicales régulièrement pointées.'),
  -- COMPLÉMENTS marques existantes
  ('kering','ANI_FUR_FREE','FUR_FREE','boolean',null,true,null,1.00,'result','2021-09-01',0.85,'https://furfreeretailer.com','Kering a banni la fourrure de toutes ses maisons (2021).'),
  ('gucci','ANI_FUR_FREE','FUR_FREE','boolean',null,true,null,1.00,'result','2018-01-01',0.85,'https://furfreeretailer.com','Gucci sans fourrure depuis 2018.')
) as v(entity_slug, indicator_code, source_code, value_type, value_numeric, value_boolean, value_text, normalized_value, nature, observed_on, confidence, source_url, excerpt)
join entities e   on e.slug = v.entity_slug
join indicators i on i.code = v.indicator_code
join sources s    on s.code = v.source_code
on conflict do nothing;
