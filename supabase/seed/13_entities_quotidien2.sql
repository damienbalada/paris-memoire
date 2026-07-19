-- =============================================================================
-- Seed 13 : 2e vague de marques du quotidien (agro, boissons, hygiène, distri,
--           resto, tech/média, auto, énergie, banque/assurance).
-- =============================================================================

insert into entities (slug, legal_name, display_name, country, sector_id, is_brand)
select v.slug, v.legal_name, v.display_name, v.country, s.id, false
from (values
  ('kraft-heinz',      'The Kraft Heinz Company',      'Kraft Heinz',      'US', 'fmcg_group'),
  ('kellanova',        'Kellanova (Kellogg''s)',       'Kellanova',        'US', 'fmcg_group'),
  ('barilla',          'Barilla G. e R. Fratelli',     'Barilla',          'IT', 'fmcg_group'),
  ('bonduelle',        'Bonduelle SA',                 'Bonduelle',        'FR', 'food'),
  ('pernod-ricard',    'Pernod Ricard SA',             'Pernod Ricard',    'FR', 'wines_spirits'),
  ('heineken',         'Heineken N.V.',                'Heineken',         'NL', 'wines_spirits'),
  ('ab-inbev',         'Anheuser-Busch InBev',         'AB InBev',         'BE', 'wines_spirits'),
  ('colgate-palmolive','Colgate-Palmolive Company',    'Colgate-Palmolive','US', 'personal_care'),
  ('beiersdorf',       'Beiersdorf AG',                'Beiersdorf',       'DE', 'personal_care'),
  ('henkel',           'Henkel AG & Co. KGaA',         'Henkel',           'DE', 'personal_care'),
  ('kenvue',           'Kenvue Inc.',                  'Kenvue',           'US', 'personal_care'),
  ('schwarz-gruppe',   'Schwarz Gruppe',               'Schwarz (Lidl)',   'DE', 'retail_distribution'),
  ('ikea',             'Ingka Group (IKEA)',           'IKEA',             'NL', 'retail_distribution'),
  ('rbi',              'Restaurant Brands International','RBI',             'CA', 'restaurant'),
  ('yum-brands',       'Yum! Brands, Inc.',            'Yum! Brands',      'US', 'restaurant'),
  ('meta',             'Meta Platforms, Inc.',         'Meta',             'US', 'tech_electronics'),
  ('netflix',          'Netflix, Inc.',                'Netflix',          'US', 'tech_electronics'),
  ('sony',             'Sony Group Corporation',       'Sony',             'JP', 'tech_electronics'),
  ('stellantis',       'Stellantis N.V.',              'Stellantis',       'NL', 'automotive'),
  ('bmw',              'Bayerische Motoren Werke AG',  'BMW',              'DE', 'automotive'),
  ('mercedes-benz',    'Mercedes-Benz Group AG',       'Mercedes-Benz',    'DE', 'automotive'),
  ('shell',            'Shell plc',                    'Shell',            'GB', 'energy'),
  ('societe-generale', 'Société Générale S.A.',        'Société Générale', 'FR', 'banking_finance'),
  ('axa',              'AXA S.A.',                     'AXA',              'FR', 'banking_finance')
) as v(slug, legal_name, display_name, country, sector_code)
join sectors s on s.code = v.sector_code
on conflict (slug) do nothing;

insert into entities (slug, legal_name, display_name, parent_id, ownership_pct, country, sector_id, is_brand)
select v.slug, v.legal_name, v.display_name, p.id, v.ownership_pct, v.country, s.id, true
from (values
  ('heinz',        'Heinz',            'Heinz',         'kraft-heinz',      100.0, 'US', 'food'),
  ('kelloggs',     'Kellogg''s',       'Kellogg''s',    'kellanova',        100.0, 'US', 'food'),
  ('harrys',       'Harry''s',         'Harry''s',      'barilla',          100.0, 'FR', 'food'),
  ('ricard',       'Ricard',           'Ricard',        'pernod-ricard',    100.0, 'FR', 'wines_spirits'),
  ('absolut',      'Absolut Vodka',    'Absolut',       'pernod-ricard',    100.0, 'SE', 'wines_spirits'),
  ('leffe',        'Leffe',            'Leffe',         'ab-inbev',         100.0, 'BE', 'wines_spirits'),
  ('stella-artois','Stella Artois',    'Stella Artois', 'ab-inbev',         100.0, 'BE', 'wines_spirits'),
  ('colgate',      'Colgate',          'Colgate',       'colgate-palmolive',100.0, 'US', 'personal_care'),
  ('palmolive',    'Palmolive',        'Palmolive',     'colgate-palmolive',100.0, 'US', 'personal_care'),
  ('nivea',        'Nivea',            'Nivea',         'beiersdorf',       100.0, 'DE', 'personal_care'),
  ('schwarzkopf',  'Schwarzkopf',      'Schwarzkopf',   'henkel',           100.0, 'DE', 'personal_care'),
  ('neutrogena',   'Neutrogena',       'Neutrogena',    'kenvue',           100.0, 'US', 'personal_care'),
  ('lidl',         'Lidl',             'Lidl',          'schwarz-gruppe',   100.0, 'DE', 'retail_distribution'),
  ('burger-king',  'Burger King',      'Burger King',   'rbi',              100.0, 'US', 'restaurant'),
  ('kfc',          'KFC',              'KFC',           'yum-brands',       100.0, 'US', 'restaurant'),
  ('peugeot',      'Peugeot',          'Peugeot',       'stellantis',       100.0, 'FR', 'automotive'),
  ('citroen',      'Citroën',          'Citroën',       'stellantis',       100.0, 'FR', 'automotive')
) as v(slug, legal_name, display_name, parent_slug, ownership_pct, country, sector_code)
join entities p on p.slug = v.parent_slug
join sectors  s on s.code = v.sector_code
on conflict (slug) do nothing;
