-- =============================================================================
-- Seed 11 : marques du quotidien (grandes conso FR/international).
-- =============================================================================

-- Groupes / sociétés
insert into entities (slug, legal_name, display_name, country, sector_id, is_brand)
select v.slug, v.legal_name, v.display_name, v.country, s.id, false
from (values
  ('mars',            'Mars, Incorporated',            'Mars',            'US', 'fmcg_group'),
  ('ferrero',         'Ferrero International S.A.',     'Ferrero',         'LU', 'fmcg_group'),
  ('lactalis',        'Groupe Lactalis',               'Lactalis',        'FR', 'fmcg_group'),
  ('groupe-bel',      'Groupe Bel',                    'Groupe Bel',      'FR', 'fmcg_group'),
  ('carrefour',       'Carrefour S.A.',                'Carrefour',       'FR', 'retail_distribution'),
  ('nike',            'Nike, Inc.',                    'Nike',            'US', 'fashion_leather'),
  ('adidas',          'adidas AG',                     'adidas',          'DE', 'fashion_leather'),
  ('decathlon',       'Decathlon S.A.',                'Decathlon',       'FR', 'fashion_leather'),
  ('renault',         'Renault Group',                 'Renault',         'FR', 'automotive'),
  ('engie',           'Engie S.A.',                    'Engie',           'FR', 'energy'),
  ('credit-agricole', 'Crédit Agricole S.A.',          'Crédit Agricole', 'FR', 'banking_finance'),
  ('google',          'Alphabet Inc. (Google)',        'Google',          'US', 'tech_electronics'),
  ('microsoft',       'Microsoft Corporation',         'Microsoft',       'US', 'tech_electronics'),
  ('amazon',          'Amazon.com, Inc.',              'Amazon',          'US', 'retail_distribution')
) as v(slug, legal_name, display_name, country, sector_code)
join sectors s on s.code = v.sector_code
on conflict (slug) do nothing;

-- Marques rattachées
insert into entities (slug, legal_name, display_name, parent_id, ownership_pct, country, sector_id, is_brand)
select v.slug, v.legal_name, v.display_name, p.id, v.ownership_pct, v.country, s.id, true
from (values
  ('royal-canin',   'Royal Canin',        'Royal Canin',       'mars',       100.0, 'FR', 'pet_care'),
  ('mms',           'M&M''s',             'M&M''s',            'mars',       100.0, 'US', 'food'),
  ('snickers',      'Snickers',           'Snickers',          'mars',       100.0, 'US', 'food'),
  ('nutella',       'Nutella',            'Nutella',           'ferrero',    100.0, 'IT', 'food'),
  ('kinder',        'Kinder',             'Kinder',            'ferrero',    100.0, 'IT', 'food'),
  ('president',     'Président',          'Président',         'lactalis',   100.0, 'FR', 'food'),
  ('babybel',       'Mini Babybel',       'Babybel',           'groupe-bel', 100.0, 'FR', 'food'),
  ('vache-qui-rit', 'La vache qui rit',   'La vache qui rit',  'groupe-bel', 100.0, 'FR', 'food')
) as v(slug, legal_name, display_name, parent_slug, ownership_pct, country, sector_code)
join entities p on p.slug = v.parent_slug
join sectors  s on s.code = v.sector_code
on conflict (slug) do nothing;
