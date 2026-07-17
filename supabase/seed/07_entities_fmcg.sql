-- =============================================================================
-- Seed 07 : élargissement hors luxe — agroalimentaire, boissons, hygiène/beauté
-- -----------------------------------------------------------------------------
-- Grands groupes de grande consommation + marques connues. LEI/SIREN laissés
-- NULL (renseignés par le pipeline GLEIF/SIRENE). ownership_pct à 100 = filiale
-- détenue à 100 % ; valeurs partielles marquées.
-- =============================================================================

-- Secteurs supplémentaires
insert into sectors (code, name, description) values
  ('fmcg_group',    'Grande consommation (holding)', 'Conglomérat de biens de grande consommation.'),
  ('food',          'Agroalimentaire',               'Produits alimentaires transformés, épicerie.'),
  ('beverages',     'Boissons',                      'Eaux, sodas, jus, café, boissons.'),
  ('personal_care', 'Hygiène & Soin grand public',   'Hygiène, soins, cosmétique de grande distribution.')
on conflict (code) do nothing;

-- Groupes (holdings)
insert into entities (slug, legal_name, display_name, country, sector_id, is_brand)
select v.slug, v.legal_name, v.display_name, v.country, s.id, false
from (values
  ('nestle',         'Nestlé S.A.',                'Nestlé',           'CH'),
  ('danone',         'Danone S.A.',                'Danone',           'FR'),
  ('unilever',       'Unilever PLC',               'Unilever',         'GB'),
  ('loreal',         'L''Oréal S.A.',              'L''Oréal',         'FR'),
  ('coca-cola',      'The Coca-Cola Company',      'Coca-Cola (groupe)','US'),
  ('pepsico',        'PepsiCo, Inc.',              'PepsiCo',          'US'),
  ('mondelez',       'Mondelez International, Inc.','Mondelez',         'US'),
  ('procter-gamble', 'The Procter & Gamble Company','Procter & Gamble','US')
) as v(slug, legal_name, display_name, country)
cross join lateral (select id from sectors where code = 'fmcg_group') s
on conflict (slug) do nothing;

-- Marques (parent résolu par slug)
insert into entities (slug, legal_name, display_name, parent_id, ownership_pct, country, sector_id, is_brand)
select v.slug, v.legal_name, v.display_name, p.id, v.ownership_pct, v.country, s.id, true
from (values
  -- Nestlé
  ('nespresso',    'Nestlé Nespresso S.A.',     'Nespresso',   'nestle',   100.0, 'CH', 'beverages'),
  ('perrier',      'Perrier',                   'Perrier',     'nestle',   100.0, 'FR', 'beverages'),
  ('vittel',       'Vittel',                    'Vittel',      'nestle',   100.0, 'FR', 'beverages'),
  ('kitkat',       'KitKat',                    'KitKat',      'nestle',   100.0, 'GB', 'food'),
  ('maggi',        'Maggi',                     'Maggi',       'nestle',   100.0, 'CH', 'food'),
  ('purina',       'Nestlé Purina PetCare',     'Purina',      'nestle',   100.0, 'US', 'food'),
  ('nesquik',      'Nesquik',                   'Nesquik',     'nestle',   100.0, 'CH', 'beverages'),
  -- Danone
  ('evian',        'Evian',                     'Evian',       'danone',   100.0, 'FR', 'beverages'),
  ('volvic',       'Volvic',                    'Volvic',      'danone',   100.0, 'FR', 'beverages'),
  ('activia',      'Activia',                   'Activia',     'danone',   100.0, 'FR', 'food'),
  ('alpro',        'Alpro',                     'Alpro',       'danone',   100.0, 'BE', 'food'),
  ('actimel',      'Actimel',                   'Actimel',     'danone',   100.0, 'FR', 'food'),
  -- Unilever
  ('dove',         'Dove',                      'Dove',        'unilever', 100.0, 'GB', 'personal_care'),
  ('knorr',        'Knorr',                     'Knorr',       'unilever', 100.0, 'DE', 'food'),
  ('hellmanns',    'Hellmann''s',               'Hellmann''s', 'unilever', 100.0, 'US', 'food'),
  ('ben-jerrys',   'Ben & Jerry''s',            'Ben & Jerry''s','unilever',100.0,'US', 'food'),
  ('magnum-ice',   'Magnum (glaces)',           'Magnum',      'unilever', 100.0, 'GB', 'food'),
  ('rexona',       'Rexona',                    'Rexona',      'unilever', 100.0, 'GB', 'personal_care'),
  -- L'Oréal
  ('lancome',      'Lancôme',                   'Lancôme',     'loreal',   100.0, 'FR', 'beauty_fragrance'),
  ('garnier',      'Garnier',                   'Garnier',     'loreal',   100.0, 'FR', 'personal_care'),
  ('maybelline',   'Maybelline New York',       'Maybelline',  'loreal',   100.0, 'US', 'beauty_fragrance'),
  ('la-roche-posay','La Roche-Posay',           'La Roche-Posay','loreal', 100.0, 'FR', 'personal_care'),
  -- Coca-Cola
  ('coca-cola-classic','Coca-Cola',             'Coca-Cola',   'coca-cola',100.0, 'US', 'beverages'),
  ('fanta',        'Fanta',                     'Fanta',       'coca-cola',100.0, 'US', 'beverages'),
  ('sprite',       'Sprite',                    'Sprite',      'coca-cola',100.0, 'US', 'beverages'),
  ('innocent',     'Innocent Drinks',           'Innocent',    'coca-cola', 90.0, 'GB', 'beverages'),
  -- PepsiCo
  ('pepsi',        'Pepsi',                     'Pepsi',       'pepsico',  100.0, 'US', 'beverages'),
  ('lays',         'Lay''s',                    'Lay''s',      'pepsico',  100.0, 'US', 'food'),
  ('quaker',       'Quaker Oats',               'Quaker',      'pepsico',  100.0, 'US', 'food'),
  -- Mondelez
  ('milka',        'Milka',                     'Milka',       'mondelez', 100.0, 'DE', 'food'),
  ('oreo',         'Oreo',                      'Oreo',        'mondelez', 100.0, 'US', 'food'),
  ('toblerone',    'Toblerone',                 'Toblerone',   'mondelez', 100.0, 'CH', 'food'),
  ('lu',           'LU',                        'LU',          'mondelez', 100.0, 'FR', 'food'),
  -- Procter & Gamble
  ('pampers',      'Pampers',                   'Pampers',     'procter-gamble', 100.0, 'US', 'personal_care'),
  ('gillette',     'Gillette',                  'Gillette',    'procter-gamble', 100.0, 'US', 'personal_care'),
  ('ariel',        'Ariel',                     'Ariel',       'procter-gamble', 100.0, 'DE', 'personal_care'),
  ('head-shoulders','Head & Shoulders',         'Head & Shoulders','procter-gamble', 100.0, 'US', 'personal_care')
) as v(slug, legal_name, display_name, parent_slug, ownership_pct, country, sector_code)
join entities p on p.slug = v.parent_slug
join sectors  s on s.code = v.sector_code
on conflict (slug) do nothing;
