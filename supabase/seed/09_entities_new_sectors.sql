-- =============================================================================
-- Seed 09 : entités des nouveaux secteurs (tech, auto, fast fashion, resto,
--           énergie, banque). LEI/SIREN laissés au pipeline.
-- =============================================================================

-- Groupes / sociétés (tête d'entité)
insert into entities (slug, legal_name, display_name, country, sector_id, is_brand)
select v.slug, v.legal_name, v.display_name, v.country, s.id, false
from (values
  -- Habillement grand public : rattaché au secteur fashion_leather (mêmes
  -- indicateurs animaux : fourrure, cuir, laine, exploitation).
  ('inditex',       'Industria de Diseño Textil, S.A.', 'Inditex',        'ES', 'fashion_leather'),
  ('hm-group',      'H & M Hennes & Mauritz AB',        'H&M Group',      'SE', 'fashion_leather'),
  ('fast-retailing','Fast Retailing Co., Ltd.',         'Fast Retailing', 'JP', 'fashion_leather'),
  ('shein',         'Roadget Business Pte. Ltd. (Shein)','Shein',         'SG', 'fashion_leather'),
  ('apple',         'Apple Inc.',                       'Apple',          'US', 'tech_electronics'),
  ('samsung',       'Samsung Electronics Co., Ltd.',    'Samsung',        'KR', 'tech_electronics'),
  ('tesla',         'Tesla, Inc.',                      'Tesla',          'US', 'automotive'),
  ('volkswagen',    'Volkswagen AG',                    'Volkswagen',     'DE', 'automotive'),
  ('toyota',        'Toyota Motor Corporation',         'Toyota',         'JP', 'automotive'),
  ('mcdonalds',     'McDonald''s Corporation',          'McDonald''s',    'US', 'restaurant'),
  ('starbucks',     'Starbucks Corporation',            'Starbucks',      'US', 'restaurant'),
  ('totalenergies', 'TotalEnergies SE',                 'TotalEnergies',  'FR', 'energy'),
  ('bnp-paribas',   'BNP Paribas S.A.',                 'BNP Paribas',    'FR', 'banking_finance')
) as v(slug, legal_name, display_name, country, sector_code)
join sectors s on s.code = v.sector_code
on conflict (slug) do nothing;

-- Marques rattachées à un groupe
insert into entities (slug, legal_name, display_name, parent_id, ownership_pct, country, sector_id, is_brand)
select v.slug, v.legal_name, v.display_name, p.id, v.ownership_pct, v.country, s.id, true
from (values
  ('zara',   'Zara España, S.A.', 'Zara',   'inditex',        100.0, 'ES', 'fashion_leather'),
  ('h-et-m', 'H&M',               'H&M',    'hm-group',       100.0, 'SE', 'fashion_leather'),
  ('uniqlo', 'UNIQLO Co., Ltd.',  'Uniqlo', 'fast-retailing', 100.0, 'JP', 'fashion_leather')
) as v(slug, legal_name, display_name, parent_slug, ownership_pct, country, sector_code)
join entities p on p.slug = v.parent_slug
join sectors  s on s.code = v.sector_code
on conflict (slug) do nothing;
