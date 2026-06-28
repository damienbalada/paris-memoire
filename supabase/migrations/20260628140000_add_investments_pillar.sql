-- =============================================================================
-- Migration 0008 : 8e pilier « Investissements & Finance éthique »
-- -----------------------------------------------------------------------------
-- Où la société place et finance son argent : finance durable, désinvestissement
-- fossile, relations bancaires, participations dans des secteurs controversés.
-- Distinct de Fiscalité (qui traite paradis fiscaux / CbCR).
-- =============================================================================

insert into dimensions (code, name, description, default_weight, display_order) values
  ('INV', 'Investissements & Finance éthique',
   'Où la société place et finance son argent : finance durable, désinvestissement fossile, relations bancaires, participations dans des secteurs controversés.',
   0.1000, 8)
on conflict (code) do nothing;

insert into sources (code, name, tier, publisher, url, description) values
  ('UN_PRI',          'UN Principles for Responsible Investment', 'audited_ngo', 'UN PRI',           'https://www.unpri.org',     'Signataires des principes pour l''investissement responsable.'),
  ('RECLAIM_FINANCE', 'Reclaim Finance',                          'audited_ngo', 'Reclaim Finance',  'https://reclaimfinance.org','Suivi du financement des énergies fossiles.'),
  ('URD_FINANCE',     'URD (volet financier)',                    'regulatory',  'Émetteur / AMF',    null,                        'Instruments de finance durable, participations (doc enregistrement universel).')
on conflict (code) do nothing;

insert into indicators (code, dimension_id, name, kind, direction, sector_specific, weight, unit, methodology)
select v.code, d.id, v.name, v.kind::indicator_kind, v.direction::indicator_direction, false, v.weight, v.unit, v.methodology
from (values
  ('INV_RESPONSIBLE_POLICY',    'INV', 'Politique d''investissement responsable',            'categorical',  'higher_better', 0.9, 'status', 'Absente/politique/signataire UN PRI vérifié -> 0/0.5/1.'),
  ('INV_SUSTAINABLE_FINANCE',   'INV', 'Finance durable (green / sustainability-linked bonds)','categorical', 'higher_better', 0.8, 'status', 'Aucun/émissions ponctuelles/cadre structuré -> 0/0.5/1.'),
  ('INV_FOSSIL_FINANCING',      'INV', 'Liens financiers avec les énergies fossiles',         'quantitative', 'lower_better',  1.0, 'score',  'Exposition/financement fossile (Reclaim Finance), percentile inversé intra-secteur.'),
  ('INV_CONTROVERSIAL_HOLDINGS','INV', 'Participations dans des secteurs controversés',       'quantitative', 'lower_better',  0.8, 'count',  'Nb de participations dans des secteurs controversés (armes, fossile...), percentile inversé.')
) as v(code, dim_code, name, kind, direction, weight, unit, methodology)
join dimensions d on d.code = v.dim_code
on conflict (code) do nothing;

-- Intégration aux profils (les poids sont relatifs ; l'agrégation renormalise).
insert into profile_weights (profile_id, dimension_id, weight)
select p.id, d.id, w.weight
from (values
  ('equilibre',   'INV', 0.10),
  ('ecolo',       'INV', 0.15),
  ('vivant',      'INV', 0.05),
  ('transparence','INV', 0.20)
) as w(profile_code, dim_code, weight)
join value_profiles p on p.code = w.profile_code
join dimensions     d on d.code = w.dim_code
on conflict (profile_id, dimension_id) do nothing;
