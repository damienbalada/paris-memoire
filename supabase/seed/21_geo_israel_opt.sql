-- =============================================================================
-- Seed 21 : GEO — Israël / Territoires palestiniens occupés (TPO).
-- -----------------------------------------------------------------------------
-- Deux sources ONU de STATUT DIFFÉRENT, traitées différemment :
--
--  1) Base OHCHR « consensus » (A/HRC/60/19, 2025, 158 entreprises) — mandatée
--     par le Conseil des droits de l'homme, critère prudent. C'est la référence
--     la plus solide. CROISEMENT effectué sur nos 60 entités => 0 correspondance
--     (les noms internationaux : Airbnb, Booking, Expedia, TripAdvisor, Motorola
--     Solutions, Egis Rail, JCB — aucun n'est dans notre base). Rien à insérer :
--     on ne fabrique pas de fait.
--
--  2) Rapport de la Rapporteuse spéciale ONU (A/HRC/59/23, 2025) — document
--     officiel ONU mais d'UNE experte mandatée, périmètre plus large et plus
--     CONTESTÉ. Les entités de notre base qui y sont citées sont insérées en
--     nature='controversy', review_status='pending' (n'affectent PAS le score
--     tant qu'un humain ne les valide pas dans /admin/revue), source attribuée.
-- =============================================================================

insert into sources (code, name, tier, url) values
  ('UN_SR_OPT','ONU — Rapporteuse spéciale TPO (A/HRC/59/23)','audited_ngo','https://www.un.org/unispal/document/a-hrc-59-23-from-economy-of-occupation-to-economy-of-genocide-report-special-rapporteur-francesca-albanese-palestine-2025/')
on conflict (code) do nothing;

-- Faits cités par la Rapporteuse spéciale (en attente de revue humaine).
insert into evidence
  (entity_id, indicator_id, source_id, value_type, value_text, normalized_value,
   nature, observed_on, confidence, review_status, reviewer, source_url, excerpt)
select e.id, i.id, s.id, 'category'::value_type, v.vtext, v.nv,
       'controversy'::evidence_nature, '2025-07-01'::date, v.conf, 'pending'::review_status, 'curation-v1',
       'https://www.un.org/unispal/document/a-hrc-59-23-from-economy-of-occupation-to-economy-of-genocide-report-special-rapporteur-francesca-albanese-palestine-2025/',
       v.ex
from (values
  ('amazon','cité (Rapporteuse spéciale ONU)',0.40,0.60,
   'Cité par la Rapporteuse spéciale ONU (A/HRC/59/23, 2025) pour ses services cloud/logistiques (Project Nimbus). Rapport officiel ONU mais contesté — à valider.'),
  ('google','cité (Rapporteuse spéciale ONU)',0.40,0.60,
   'Cité par la Rapporteuse spéciale ONU (A/HRC/59/23, 2025) pour ses services cloud (Project Nimbus). Rapport officiel ONU mais contesté — à valider.'),
  ('microsoft','cité (Rapporteuse spéciale ONU)',0.40,0.60,
   'Cité par la Rapporteuse spéciale ONU (A/HRC/59/23, 2025) pour ses services cloud/IA. Rapport officiel ONU mais contesté — à valider.'),
  ('bnp-paribas','cité (Rapporteuse spéciale ONU)',0.40,0.60,
   'Cité par la Rapporteuse spéciale ONU (A/HRC/59/23, 2025) au titre du financement. Rapport officiel ONU mais contesté — à valider.')
) as v(slug, vtext, nv, conf, ex)
join entities e on e.slug=v.slug
join indicators i on i.code='GEO_CONFLICT_TIES'
join sources s on s.code='UN_SR_OPT'
where not exists (select 1 from evidence x where x.entity_id=e.id and x.indicator_id=i.id and x.source_id=s.id)
on conflict do nothing;
