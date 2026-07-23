-- =============================================================================
-- Migration : indicateur-gate GEO_LOBBYING_ALIGN (alignement du lobbying climat).
-- -----------------------------------------------------------------------------
-- DIAMS mesurait la TRANSPARENCE du lobbying (inscription au registre : oui/non)
-- mais pas son ALIGNEMENT avec l'Accord de Paris. Résultat paradoxal : une major
-- pétrolière « transparente » (inscrite) était bien notée alors qu'elle fait du
-- lobbying documenté CONTRE des politiques climat.
--
-- Mécanisme : indicateur-GATE (comme PLA_POLLUTER). Il ne pèse PAS dans la
-- moyenne (poids 0) ; sa valeur sert de PLAFOND au pilier GEO. Absent -> plafond
-- neutre 1.0 (aucune pénalité pour les entités non évaluées par InfluenceMap) ;
-- présent (lobbying désaligné, saisi comme controverse) -> plafonne la note GEO.
-- On évite ainsi de pénaliser à tort les dizaines d'entités sans donnée.
-- =============================================================================

insert into sources (code, name, tier, publisher, url, description) values
  ('INFLUENCEMAP', 'InfluenceMap / LobbyMap', 'audited_ngo', 'InfluenceMap', 'https://lobbymap.org',
   'Évaluation de l''alignement du lobbying des entreprises avec l''Accord de Paris.')
on conflict (code) do nothing;

-- Poids 0 : le gate ne pèse pas dans la moyenne (il plafonne).
insert into indicators (code, dimension_id, name, kind, direction, sector_specific, weight, unit, methodology)
select 'GEO_LOBBYING_ALIGN', d.id, 'Alignement du lobbying climat', 'categorical'::indicator_kind,
       'higher_better'::indicator_direction, false, 0.0, 'score',
       'Alignement du lobbying avec l''Accord de Paris (InfluenceMap/LobbyMap). Indicateur-gate : plafonne la note GEO en cas de lobbying désaligné ; sans effet si non évalué. Distinct de la transparence de l''inscription.'
from dimensions d where d.code = 'GEO'
on conflict (code) do nothing;

insert into dimension_gates (dimension_id, gate_indicator_id, default_ceiling, notes)
select d.id, i.id, 1.0, 'Lobbying climat désaligné (InfluenceMap) : plafonne la note GEO. Absent = pas d''effet.'
from dimensions d, indicators i
where d.code = 'GEO' and i.code = 'GEO_LOBBYING_ALIGN'
on conflict do nothing;
