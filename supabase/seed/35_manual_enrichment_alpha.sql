-- =============================================================================
-- Seed 35 : enrichissement manuel sourcé, par ordre alphabétique (curation-v1).
-- Faits publics, attribuables, datés. Idempotent (not exists + on conflict).
-- Lot 1 : AB InBev, adidas, Amazon.
-- Lot 2 : Apple (CDP A-), AXA (SBTi engagé, non validé).
-- Lot 3 : Beiersdorf (CDP Triple A → climat+eau A), BMW (CDP climat A), BNP Paribas (CDP climat A).
-- Barilla examiné mais écarté : Tier BBFAW 2023 ambigu (refonte des critères,
--   confusion Tier/Impact Rating) et pas de score CDP fiable -> on n'invente pas.
-- =============================================================================

-- Notes CDP (climat + eau) et note lettre — barème canonique A..D-/F.
insert into evidence (entity_id, indicator_id, source_id, value_type, value_text, normalized_value,
   nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, 'ordinal'::value_type, v.grade, v.nv,
       'result'::evidence_nature, v.d::date, v.conf, 'approved'::review_status, 'curation-v1', v.url, v.ex
from (values
  ('ab-inbev','ENV_CDP_CLIMATE','A',1.00,'2022-12-01',0.75,'https://www.ab-inbev.com/climate','Double A CDP (climat + eau) — leadership transparence climat/eau (cycle CDP 2022).'),
  ('ab-inbev','WAT_CDP','A',1.00,'2022-12-01',0.75,'https://www.ab-inbev.com/climate','Double A CDP : note A en sécurité de l''eau (cycle CDP 2022).'),
  ('adidas','ENV_CDP_CLIMATE','A',1.00,'2023-01-01',0.80,'https://www.cdp.net/en/data/scores','CDP Climate A List (top 4 % mondial) — première note A climat pour adidas.'),
  ('amazon','ENV_CDP_CLIMATE','B',0.75,'2023-01-01',0.72,'https://www.asyousow.org/resolutions/2023/12/14-amazon-net-zero-target-scope-3','CDP Climat 2023 : note B (« Management ») — sous le niveau A/A- de Google/Microsoft.'),
  ('apple','ENV_CDP_CLIMATE','A-',0.88,'2023-01-01',0.82,'https://www.apple.com/environment/pdf/Apple_CDP-Climate-Change-Questionnaire_2023.pdf','CDP Climat 2023 : note A- (bande « Leadership »).'),
  ('beiersdorf','ENV_CDP_CLIMATE','A',1.00,'2023-01-01',0.82,'https://www.beiersdorf.com/newsroom/press-information/all-press-releases/2024/02/06-beiersdorf-achieves-cdp-triple-a-and-maintains-top-rating-for-leadership-in-sustainability','CDP « Triple A » (climat A, segment Consumer) — un des ~10 « Triple A » mondiaux.'),
  ('beiersdorf','WAT_CDP','A',1.00,'2023-01-01',0.80,'https://www.beiersdorf.com/newsroom/press-information/all-press-releases/2024/02/06-beiersdorf-achieves-cdp-triple-a-and-maintains-top-rating-for-leadership-in-sustainability','CDP « Triple A » : note A en sécurité de l''eau.'),
  ('bmw','ENV_CDP_CLIMATE','A',1.00,'2023-01-01',0.85,'https://www.bmwgroup.com/content/dam/grpw/websites/bmwgroup_com/ir/downloads/en/2024/bericht/BMW_Group_CDP_Climate_Change_Questionnaire_2023.pdf','CDP Climat 2023 : note A (99/100, sector leader) — 8e année consécutive.'),
  ('bnp-paribas','ENV_CDP_CLIMATE','A',1.00,'2023-01-01',0.82,'https://cdn-group.bnpparibas.com/uploads/file/bnpparibas_cdp_climate_change_questionnaire_2023.pdf','CDP Climat 2023 : note A — en tête des grandes banques (transparence climat ; distincte du financement fossile réel).')
) as v(slug, ind, grade, nv, d, conf, url, ex)
join entities e on e.slug=v.slug
join indicators i on i.code=v.ind
join sources s on s.code='CDP'
where not exists (select 1 from evidence x where x.entity_id=e.id and x.indicator_id=i.id)
on conflict do nothing;

-- Objectifs climat validés SBTi.
insert into evidence (entity_id, indicator_id, source_id, value_type, value_text, normalized_value,
   nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, 'category'::value_type, 'validated', 1.00,
       'result'::evidence_nature, '2021-01-01'::date, 0.82, 'approved'::review_status, 'curation-v1',
       'https://www.esgtoday.com/beer-giant-ab-inbev-commits-to-net-zero-emissions-across-value-chain-by-2040/',
       'Net-zéro 2040 sur toute la chaîne de valeur, validé SBTi (trajectoire 1,5°C) — un des 100 premiers validés.'
from entities e join indicators i on i.code='ENV_SBTI_VALIDATED' join sources s on s.code='SBTI'
where e.slug='ab-inbev' and not exists (select 1 from evidence x where x.entity_id=e.id and x.indicator_id=i.id)
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
