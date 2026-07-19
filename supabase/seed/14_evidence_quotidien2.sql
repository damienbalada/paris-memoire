-- =============================================================================
-- Seed 14 : evidence réelle curée (v1) pour la 2e vague de marques.
-- Faits publics datés et sourcés. reviewer=curation-v1. Confiance 0,65–0,90.
-- =============================================================================

insert into evidence
  (entity_id, indicator_id, source_id, value_type, value_numeric, value_boolean,
   value_text, normalized_value, nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, v.value_type::value_type, v.value_numeric, v.value_boolean,
       v.value_text, v.normalized_value, v.nature::evidence_nature, v.observed_on::date,
       v.confidence, 'approved'::review_status, 'curation-v1', v.source_url, v.excerpt
from (values
  -- KRAFT HEINZ
  ('kraft-heinz','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null::numeric,null::boolean,'reduction',0.40,'result','2023-01-01',0.75,'https://www.yalerussianbusinessretreat.com','Réduction des activités en Russie (essentiels seulement).'),
  ('kraft-heinz','ANI_BBFAW_TIER','BBFAW','ordinal',null,null,'tier 4',0.40,'result','2023-11-01',0.72,'https://www.bbfaw.com','BBFAW tier 4 (bien-être animal faible).'),
  -- KELLANOVA
  ('kellanova','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'reduction',0.40,'result','2023-01-01',0.72,'https://www.yalerussianbusinessretreat.com','Réduction des activités en Russie.'),
  -- BARILLA
  ('barilla','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'buying time',0.20,'result','2023-01-01',0.75,'https://www.yalerussianbusinessretreat.com','Maintien des activités en Russie (critiqué).'),
  -- BONDUELLE
  ('bonduelle','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'buying time',0.20,'result','2023-01-01',0.78,'https://www.yalerussianbusinessretreat.com','Maintien d''une forte présence en Russie (polémique 2022).'),
  -- PERNOD RICARD
  ('pernod-ricard','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'buying time',0.20,'result','2023-06-01',0.78,'https://www.yalerussianbusinessretreat.com','Reprise critiquée des exportations vers la Russie (2023).'),
  -- HEINEKEN
  ('heineken','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'withdrawal',1.00,'result','2023-08-01',0.80,'https://www.yalerussianbusinessretreat.com','Départ de Russie finalisé en 2023 (tardif, vendu pour 1 €).'),
  -- AB INBEV
  ('ab-inbev','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'withdrawal',1.00,'result','2022-04-01',0.78,'https://www.yalerussianbusinessretreat.com','Cession de sa participation dans la coentreprise russe (2022).'),
  -- COLGATE-PALMOLIVE
  ('colgate-palmolive','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'reduction',0.40,'result','2023-01-01',0.75,'https://www.yalerussianbusinessretreat.com','Activités réduites aux produits d''hygiène essentiels.'),
  ('colgate-palmolive','ENV_SBTI_VALIDATED','SBTI','category',null,null,'validated',1.00,'result','2023-01-01',0.80,'https://sciencebasedtargets.org/companies-taking-action','Objectifs SBTi validés.'),
  -- BEIERSDORF
  ('beiersdorf','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'reduction',0.40,'result','2023-01-01',0.72,'https://www.yalerussianbusinessretreat.com','Arrêt des investissements, maintien des produits essentiels.'),
  ('beiersdorf','ENV_SBTI_VALIDATED','SBTI','category',null,null,'validated',1.00,'result','2023-01-01',0.80,'https://sciencebasedtargets.org/companies-taking-action','Objectifs SBTi validés.'),
  -- HENKEL
  ('henkel','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'withdrawal',1.00,'result','2023-04-01',0.80,'https://www.yalerussianbusinessretreat.com','Vente de ses activités russes (2023).'),
  ('henkel','ENV_SBTI_VALIDATED','SBTI','category',null,null,'validated',1.00,'result','2023-01-01',0.80,'https://sciencebasedtargets.org/companies-taking-action','Objectifs SBTi validés.'),
  -- KENVUE
  ('kenvue','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'reduction',0.40,'result','2023-01-01',0.70,'https://www.yalerussianbusinessretreat.com','Activités réduites aux produits de santé essentiels.'),
  -- IKEA
  ('ikea','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'withdrawal',1.00,'result','2022-06-01',0.82,'https://www.yalerussianbusinessretreat.com','Fermeture et cession des activités russes (2022).'),
  ('ikea','ENV_SBTI_VALIDATED','SBTI','category',null,null,'validated',1.00,'result','2023-01-01',0.78,'https://sciencebasedtargets.org/companies-taking-action','Objectifs SBTi validés (groupe Ingka).'),
  -- RBI (Burger King)
  ('rbi','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'buying time',0.20,'result','2023-01-01',0.75,'https://www.yalerussianbusinessretreat.com','Restaurants russes restés ouverts (franchise), fermeture non aboutie.'),
  -- YUM BRANDS (KFC)
  ('yum-brands','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'withdrawal',1.00,'result','2023-04-01',0.78,'https://www.yalerussianbusinessretreat.com','Vente des restaurants KFC russes (2023).'),
  -- META
  ('meta','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'withdrawal',1.00,'result','2022-03-01',0.80,'https://www.yalerussianbusinessretreat.com','Services suspendus / interdits en Russie (2022).'),
  ('meta','ENV_SBTI_VALIDATED','SBTI','category',null,null,'committed',1.00,'commitment','2022-01-01',0.70,'https://sciencebasedtargets.org/companies-taking-action','Objectifs climat annoncés (net zéro 2030).'),
  -- NETFLIX
  ('netflix','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'withdrawal',1.00,'result','2022-03-01',0.82,'https://www.yalerussianbusinessretreat.com','Suspension du service en Russie (2022).'),
  -- SONY
  ('sony','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'withdrawal',1.00,'result','2022-03-01',0.80,'https://www.yalerussianbusinessretreat.com','Suspension des activités en Russie (2022).'),
  ('sony','ENV_SBTI_VALIDATED','SBTI','category',null,null,'validated',1.00,'result','2023-01-01',0.78,'https://sciencebasedtargets.org/companies-taking-action','Objectifs SBTi validés.'),
  -- STELLANTIS
  ('stellantis','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'suspension',0.70,'result','2022-04-01',0.78,'https://www.yalerussianbusinessretreat.com','Suspension de la production (usine de Kalouga, 2022).'),
  -- BMW
  ('bmw','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'withdrawal',1.00,'result','2022-03-01',0.80,'https://www.yalerussianbusinessretreat.com','Arrêt des exportations et de la production locale (2022).'),
  ('bmw','ENV_SBTI_VALIDATED','SBTI','category',null,null,'validated',1.00,'result','2023-01-01',0.80,'https://sciencebasedtargets.org/companies-taking-action','Objectifs SBTi validés.'),
  -- MERCEDES-BENZ
  ('mercedes-benz','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'withdrawal',1.00,'result','2022-10-01',0.80,'https://www.yalerussianbusinessretreat.com','Cession des activités russes (2022).'),
  ('mercedes-benz','ENV_SBTI_VALIDATED','SBTI','category',null,null,'validated',1.00,'result','2023-01-01',0.80,'https://sciencebasedtargets.org/companies-taking-action','Objectifs SBTi validés.'),
  -- SHELL
  ('shell','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'withdrawal',1.00,'result','2022-05-01',0.80,'https://www.yalerussianbusinessretreat.com','Sortie de Russie, dont le projet Sakhaline (2022).'),
  ('shell','ENV_CDP_CLIMATE','RECLAIM_FINANCE','ordinal',null,null,null,0.70,'controversy','2023-01-01',0.78,'https://reclaimfinance.org','Nouveaux projets pétro-gaziers jugés incompatibles avec 1,5°C.'),
  -- SOCIÉTÉ GÉNÉRALE
  ('societe-generale','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'withdrawal',1.00,'result','2022-05-01',0.82,'https://www.yalerussianbusinessretreat.com','Vente de Rosbank et sortie de Russie (2022).'),
  ('societe-generale','INV_FOSSIL_FINANCING','RECLAIM_FINANCE','numeric',null,null,null,0.30,'result','2023-01-01',0.78,'https://reclaimfinance.org','Financements fossiles importants (Banking on Climate Chaos).'),
  -- AXA
  ('axa','GEO_RUSSIA_EXIT','YALE_RUSSIA','category',null,null,'reduction',0.40,'result','2022-06-01',0.70,'https://www.yalerussianbusinessretreat.com','Cession de participations russes.'),
  ('axa','INV_RESPONSIBLE_POLICY','UN_PRI','category',null,null,'politique désinvestissement charbon',0.70,'policy','2023-01-01',0.72,'https://www.unpri.org','Politique de sortie du charbon et d''investissement responsable.')
) as v(entity_slug, indicator_code, source_code, value_type, value_numeric, value_boolean, value_text, normalized_value, nature, observed_on, confidence, source_url, excerpt)
join entities e   on e.slug = v.entity_slug
join indicators i on i.code = v.indicator_code
join sources s    on s.code = v.source_code
on conflict do nothing;
