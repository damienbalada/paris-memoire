-- =============================================================================
-- Seed 24 : marque française automobile — Peugeot (héritant de Stellantis).
-- -----------------------------------------------------------------------------
-- Peugeot (marque, FR) existe déjà sous le groupe Stellantis (multinational).
-- Les données ESG de l'automobile sont publiées au niveau GROUPE : on enrichit
-- donc Stellantis avec des faits réels et sourcés, dont Peugeot hérite via la
-- chaîne de propriété. C'est aussi l'illustration du cas « marque vs groupe » :
-- la marque française bénéficie (et dépend) des choix du groupe.
-- Détail : Robert Peugeot (famille fondatrice) siège au conseil de Stellantis.
-- =============================================================================

insert into evidence
  (entity_id, indicator_id, source_id, value_type, value_boolean, value_numeric, normalized_value,
   nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, v.vt::value_type, v.vb, v.vn, v.nv,
       'result'::evidence_nature, v.d::date, v.conf, 'approved'::review_status, 'curation-v1', v.url, v.ex
from (values
  ('ENV_SCOPE3_DISCLOSED','CSRD_ESRS','boolean',true,null::numeric,1.00,'2024-12-31',0.85,
   'https://www.stellantis.com/content/dam/stellantis-corporate/sustainability/esg-disclosures/Stellantis-Expanded-Sustainability-Statement-2024.pdf',
   'Émissions Scope 3 publiées (≈ 389 Mt CO2e), déclaration de durabilité CSRD 2024.'),
  ('ENV_SBTI_VALIDATED','SBTI','boolean',false,null,0.00,'2024-06-01',0.80,
   'https://sciencebasedtargets.org/companies-taking-action',
   'Objectifs net-zéro 2038 NON validés par la SBTi (méthodologie secteur automobile suspendue).'),
  ('GOV_BOARD_GENDER','CSRD_ESRS','numeric',null,0.40,0.80,'2024-04-16',0.85,
   'https://www.stellantis.com/en/company/governance/board-of-directors',
   'Conseil d''administration 2024 : 4 femmes sur 10 administrateurs (40 %).')
) as v(icode, scode, vt, vb, vn, nv, d, conf, url, ex)
join entities e on e.slug='stellantis'
join indicators i on i.code=v.icode
join sources s on s.code=v.scode
where not exists (select 1 from evidence x where x.entity_id=e.id and x.indicator_id=i.id)
on conflict do nothing;
