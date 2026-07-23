-- =============================================================================
-- Seed 35 : enrichissement manuel sourcé, par ordre alphabétique (curation-v1).
-- Faits publics, attribuables, datés. Idempotent (not exists + on conflict).
-- Reflète l'état appliqué en base. Lots :
--   1-3 : CDP/SBTi (AB InBev, adidas, Amazon, Apple, AXA, Beiersdorf, BMW, BNP).
--   4   : CDP (Chanel, Google, Mercedes-Benz, Volkswagen, Nike, Pernod Ricard,
--         Henkel) + eaux Triple A (L'Oréal, Danone).
--   5   : Colgate (Double A), H&M (climat A), McDonald's (SBTi validé).
--   6   : faits NÉGATIFS documentés (Nestlé/Mars/Mondelez cacao, Shein Xinjiang).
-- Écartés (pas de source récente vérifiable) : Barilla, Bonduelle, Carrefour,
--   Microsoft, Meta, Renault, Stellantis, Starbucks, Heineken, Inditex, Samsung.
-- =============================================================================

-- Notes CDP (climat + eau), barème canonique A..D-/F.
insert into evidence (entity_id, indicator_id, source_id, value_type, value_text, normalized_value,
   nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, 'ordinal'::value_type, v.grade, v.nv,
       'result'::evidence_nature, v.d::date, v.conf, 'approved'::review_status, 'curation-v1', v.url, v.ex
from (values
  ('ab-inbev','ENV_CDP_CLIMATE','A',1.00,'2022-12-01',0.75,'https://www.ab-inbev.com/climate','Double A CDP (climat + eau) — cycle CDP 2022.'),
  ('ab-inbev','WAT_CDP','A',1.00,'2022-12-01',0.75,'https://www.ab-inbev.com/climate','Double A CDP : note A en sécurité de l''eau (cycle 2022).'),
  ('adidas','ENV_CDP_CLIMATE','A',1.00,'2023-01-01',0.80,'https://www.cdp.net/en/data/scores','CDP Climate A List (top 4 % mondial).'),
  ('amazon','ENV_CDP_CLIMATE','B',0.75,'2023-01-01',0.72,'https://www.asyousow.org/resolutions/2023/12/14-amazon-net-zero-target-scope-3','CDP Climat 2023 : note B (« Management ») — sous A/A-.'),
  ('apple','ENV_CDP_CLIMATE','A-',0.88,'2023-01-01',0.82,'https://www.apple.com/environment/pdf/Apple_CDP-Climate-Change-Questionnaire_2023.pdf','CDP Climat 2023 : note A- (Leadership).'),
  ('beiersdorf','ENV_CDP_CLIMATE','A',1.00,'2023-01-01',0.82,'https://www.beiersdorf.com/newsroom/press-information/all-press-releases/2024/02/06-beiersdorf-achieves-cdp-triple-a-and-maintains-top-rating-for-leadership-in-sustainability','CDP « Triple A » (climat A, segment Consumer).'),
  ('beiersdorf','WAT_CDP','A',1.00,'2023-01-01',0.80,'https://www.beiersdorf.com/newsroom/press-information/all-press-releases/2024/02/06-beiersdorf-achieves-cdp-triple-a-and-maintains-top-rating-for-leadership-in-sustainability','CDP « Triple A » : note A en sécurité de l''eau.'),
  ('bmw','ENV_CDP_CLIMATE','A',1.00,'2023-01-01',0.85,'https://www.bmwgroup.com/content/dam/grpw/websites/bmwgroup_com/ir/downloads/en/2024/bericht/BMW_Group_CDP_Climate_Change_Questionnaire_2023.pdf','CDP Climat 2023 : note A (99/100, sector leader).'),
  ('bnp-paribas','ENV_CDP_CLIMATE','A',1.00,'2023-01-01',0.82,'https://cdn-group.bnpparibas.com/uploads/file/bnpparibas_cdp_climate_change_questionnaire_2023.pdf','CDP Climat 2023 : note A (transparence climat ; distincte du financement fossile réel).'),
  ('chanel','ENV_CDP_CLIMATE','A-',0.88,'2023-01-01',0.70,'https://ditchcarbon.com/organizations/chanel','CDP Climat : note A- (score le plus récent rapporté).'),
  ('google','ENV_CDP_CLIMATE','A',1.00,'2022-01-01',0.72,'https://www.cdp.net/en/data/scores','CDP Climat 2022 : note A (Alphabet).'),
  ('mercedes-benz','ENV_CDP_CLIMATE','A-',0.88,'2024-01-01',0.82,'https://group.mercedes-benz.com/investors/share/esg/','CDP Climat 2024 : note A-.'),
  ('mercedes-benz','WAT_CDP','A-',0.88,'2024-01-01',0.80,'https://group.mercedes-benz.com/investors/share/esg/','CDP Eau 2024 : note A-.'),
  ('volkswagen','ENV_CDP_CLIMATE','A-',0.88,'2023-01-01',0.80,'https://annualreport2023.volkswagen-group.com/group-management-report/shares-and-bonds/esg-ratings.html','CDP Climat 2023 : note A- (maintenue).'),
  ('nike','ENV_CDP_CLIMATE','A-',0.88,'2023-01-01',0.72,'https://ditchcarbon.com/organizations/nike','CDP Climat 2023 : note A-.'),
  ('pernod-ricard','ENV_CDP_CLIMATE','A',1.00,'2023-01-01',0.80,'https://www.pernod-ricard.com/en/sustainability-responsibility/esg-ratings-reporting','CDP Climat 2023 : note A.'),
  ('henkel','ENV_CDP_CLIMATE','A-',0.88,'2023-01-01',0.78,'https://eco-act.com/blog/cdp-scores/','CDP Climat 2023 : note A-.'),
  ('loreal','WAT_CDP','A',1.00,'2023-01-01',0.82,'https://www.loreal-finance.com/eng/news-event/loreal-recognized-eighth-year-row-triple-score-environmental-achievements-climate-change','CDP « Triple A » 2023 : note A en sécurité de l''eau.'),
  ('danone','WAT_CDP','A',1.00,'2023-01-01',0.82,'https://www.danone.com/newsroom/press-releases/danone-recognized-for-the-fifth-year-in-a-row-as-global-environm.html','CDP « Triple A » 2023 : note A en sécurité de l''eau.'),
  ('colgate-palmolive','ENV_CDP_CLIMATE','A',1.00,'2023-01-01',0.82,'https://investor.colgatepalmolive.com/news-releases/news-release-details/colgate-palmolive-recognized-sp-dow-jones-indices-cdp-its','CDP Double A (climat + eau) — 3e année consécutive.'),
  ('colgate-palmolive','WAT_CDP','A',1.00,'2023-01-01',0.80,'https://investor.colgatepalmolive.com/news-releases/news-release-details/colgate-palmolive-recognized-sp-dow-jones-indices-cdp-its','CDP Double A : note A en sécurité de l''eau.'),
  ('hm-group','ENV_CDP_CLIMATE','A',1.00,'2023-01-01',0.80,'https://hmgroup.com/news/hm-group-scores-a-in-climate-leadership-in-new-cdp-ranking/','CDP Climat : note A (leadership).')
) as v(slug, ind, grade, nv, d, conf, url, ex)
join entities e on e.slug=v.slug
join indicators i on i.code=v.ind
join sources s on s.code='CDP'
where not exists (select 1 from evidence x where x.entity_id=e.id and x.indicator_id=i.id)
on conflict do nothing;

-- Objectifs climat validés SBTi (résultat).
insert into evidence (entity_id, indicator_id, source_id, value_type, value_text, normalized_value,
   nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, 'category'::value_type, 'validated', 1.00,
       'result'::evidence_nature, v.d::date, v.conf, 'approved'::review_status, 'curation-v1', v.url, v.ex
from (values
  ('ab-inbev','2021-01-01',0.82,'https://www.esgtoday.com/beer-giant-ab-inbev-commits-to-net-zero-emissions-across-value-chain-by-2040/','Net-zéro 2040 validé SBTi (1,5°C) — un des 100 premiers validés.'),
  ('mcdonalds','2023-01-01',0.82,'https://corporate.mcdonalds.com/corpmcd/our-purpose-and-impact/our-planet/climate-action.html','Objectif net-zéro 2050 (+ 2030 ajusté) validé SBTi, trajectoire 1,5°C (2023).')
) as v(slug, d, conf, url, ex)
join entities e on e.slug=v.slug
join indicators i on i.code='ENV_SBTI_VALIDATED' join sources s on s.code='SBTI'
where not exists (select 1 from evidence x where x.entity_id=e.id and x.indicator_id=i.id)
on conflict do nothing;

-- AXA : engagement SBTi (near-term) NON validé -> nature commitment (plafonné par le moteur).
insert into evidence (entity_id, indicator_id, source_id, value_type, value_text, normalized_value,
   nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, 'category'::value_type, 'committed', 1.00,
       'commitment'::evidence_nature, '2023-01-01'::date, 0.75, 'approved'::review_status, 'curation-v1',
       'https://sciencebasedtargets.org/target-dashboard',
       'Engagement SBTi (near-term) pris mais pas encore validé (traité comme promesse).'
from entities e join indicators i on i.code='ENV_SBTI_VALIDATED' join sources s on s.code='SBTI'
where e.slug='axa' and not exists (select 1 from evidence x where x.entity_id=e.id and x.indicator_id=i.id)
on conflict do nothing;

-- Lot 6 : faits NÉGATIFS documentés (équilibrage). Controverses sourcées, nuancées.
insert into evidence (entity_id, indicator_id, source_id, value_type, value_text, normalized_value,
   nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, 'category'::value_type, v.txt, v.nv,
       'controversy'::evidence_nature, v.d::date, v.conf, 'approved'::review_status, 'curation-v1', v.url, v.ex
from (values
  ('nestle','allégation travail des enfants (cacao)',0.50,'2021-02-01',0.72,'https://www.business-humanrights.org/en/latest-news/usa-victims-of-child-trafficking-slavery-sue-major-chocolate-brands-incl-nestle-cargill-hershey-mars-alleging-they-knowingly-profited-from-the-forced-labor-of-children-harvesting-their-cocoa-beans/','Plainte TVPRA (2021) pour travail forcé d''enfants dans le cacao ivoirien ; déboutée en appel (pas de lien causal retenu), mais exposition au risque reconnue (engagements 2025).'),
  ('mars','allégation travail des enfants (cacao)',0.50,'2021-02-01',0.70,'https://www.business-humanrights.org/en/latest-news/usa-victims-of-child-trafficking-slavery-sue-major-chocolate-brands-incl-nestle-cargill-hershey-mars-alleging-they-knowingly-profited-from-the-forced-labor-of-children-harvesting-their-cocoa-beans/','Plainte TVPRA (2021) pour travail forcé d''enfants dans le cacao ; déboutée en appel, exposition au risque reconnue.'),
  ('mondelez','allégation travail des enfants (cacao)',0.50,'2021-02-01',0.70,'https://www.business-humanrights.org/en/latest-news/usa-victims-of-child-trafficking-slavery-sue-major-chocolate-brands-incl-nestle-cargill-hershey-mars-alleging-they-knowingly-profited-from-the-forced-labor-of-children-harvesting-their-cocoa-beans/','Plainte TVPRA (2021) pour travail forcé d''enfants dans le cacao ; déboutée en appel, exposition au risque reconnue.'),
  ('shein','coton Xinjiang / travail forcé',0.70,'2024-01-01',0.78,'https://www.business-humanrights.org/documents/40793/2024_Shein_briefing.pdf','Coton du Xinjiang détecté (tests indépendants Bloomberg 2022), enquête BBC sur les conditions de travail, 2 cas de travail d''enfants reconnus par Shein (rapport 2023).')
) as v(slug, txt, nv, d, conf, url, ex)
join entities e on e.slug=v.slug
join indicators i on i.code='SUP_BHRRC_ALLEG'
join sources s on s.code='BHRRC'
where not exists (select 1 from evidence x where x.entity_id=e.id and x.indicator_id=i.id)
on conflict do nothing;
