-- =============================================================================
-- Seed 04 : résolution d'entités — groupes de luxe + marques
-- -----------------------------------------------------------------------------
-- SOCLE du projet : marque -> filiale -> groupe, avec % de détention.
-- NB INTÉGRITÉ : les identifiants LEI/SIREN sont laissés à NULL. Ils seront
-- renseignés par le connecteur GLEIF/SIRENE (Palier 3) depuis la source
-- officielle. On ne renseigne JAMAIS un identifiant non vérifié.
-- Les ownership_pct à 100 correspondent à des filiales détenues à 100 % ;
-- les valeurs partielles sont marquées "à vérifier".
-- =============================================================================

-- 1) Groupes / holdings (parent_id = NULL) -----------------------------------
insert into entities (slug, legal_name, display_name, country, sector_id, is_brand)
select v.slug, v.legal_name, v.display_name, v.country, s.id, false
from (values
  ('lvmh',      'LVMH Moët Hennessy Louis Vuitton SE', 'LVMH',      'FR'),
  ('kering',    'Kering SA',                           'Kering',    'FR'),
  ('richemont', 'Compagnie Financière Richemont SA',   'Richemont', 'CH'),
  ('hermes',    'Hermès International SCA',             'Hermès',    'FR'),
  ('chanel',    'Chanel Limited',                      'Chanel',    'GB')
) as v(slug, legal_name, display_name, country)
cross join lateral (select id from sectors where code = 'luxury_group') s
on conflict (slug) do nothing;

-- 2) Marques (parent_id résolu par slug du groupe) ---------------------------
insert into entities (slug, legal_name, display_name, parent_id, ownership_pct, country, sector_id, is_brand)
select
  v.slug, v.legal_name, v.display_name,
  p.id, v.ownership_pct, v.country, s.id, true
from (values
  -- LVMH ------------------------------------------------------------------
  ('louis-vuitton',  'Louis Vuitton Malletier',        'Louis Vuitton',  'lvmh',      100.0, 'FR', 'fashion_leather'),
  ('dior',           'Christian Dior Couture',         'Dior',           'lvmh',      100.0, 'FR', 'fashion_leather'),
  ('fendi',          'Fendi Srl',                      'Fendi',          'lvmh',      100.0, 'IT', 'fashion_leather'),
  ('celine',         'Céline SA',                      'Celine',         'lvmh',      100.0, 'FR', 'fashion_leather'),
  ('loewe',          'Loewe SA',                       'Loewe',          'lvmh',      100.0, 'ES', 'fashion_leather'),
  ('loro-piana',     'Loro Piana SpA',                 'Loro Piana',     'lvmh',       80.0, 'IT', 'fashion_leather'), -- ~80% LVMH, à vérifier
  ('bulgari',        'Bulgari SpA',                    'Bulgari',        'lvmh',      100.0, 'IT', 'watches_jewelry'),
  ('tiffany',        'Tiffany & Co.',                  'Tiffany & Co.',  'lvmh',      100.0, 'US', 'watches_jewelry'),
  ('sephora',        'Sephora SAS',                    'Sephora',        'lvmh',      100.0, 'FR', 'beauty_fragrance'),
  -- Kering ----------------------------------------------------------------
  ('gucci',          'Guccio Gucci SpA',               'Gucci',          'kering',    100.0, 'IT', 'fashion_leather'),
  ('saint-laurent',  'Yves Saint Laurent SAS',         'Saint Laurent',  'kering',    100.0, 'FR', 'fashion_leather'),
  ('bottega-veneta', 'Bottega Veneta Srl',             'Bottega Veneta', 'kering',    100.0, 'IT', 'fashion_leather'),
  ('balenciaga',     'Balenciaga SA',                  'Balenciaga',     'kering',    100.0, 'FR', 'fashion_leather'),
  ('alexander-mcqueen','Alexander McQueen Trading Ltd','Alexander McQueen','kering',  100.0, 'GB', 'fashion_leather'),
  ('boucheron',      'Boucheron SAS',                  'Boucheron',      'kering',    100.0, 'FR', 'watches_jewelry'),
  ('pomellato',      'Pomellato SpA',                  'Pomellato',      'kering',    100.0, 'IT', 'watches_jewelry'),
  -- Richemont -------------------------------------------------------------
  ('cartier',        'Cartier International SNC',       'Cartier',        'richemont', 100.0, 'FR', 'watches_jewelry'),
  ('van-cleef-arpels','Van Cleef & Arpels SA',         'Van Cleef & Arpels','richemont',100.0,'FR', 'watches_jewelry'),
  ('montblanc',      'Montblanc International GmbH',    'Montblanc',      'richemont', 100.0, 'DE', 'watches_jewelry'),
  ('jaeger-lecoultre','Manufacture Jaeger-LeCoultre SA','Jaeger-LeCoultre','richemont',100.0,'CH', 'watches_jewelry'),
  ('chloe',          'Chloé SAS',                      'Chloé',          'richemont', 100.0, 'FR', 'fashion_leather'),
  -- Hermès (marque ~ groupe) ----------------------------------------------
  ('hermes-maison',  'Hermès Sellier SAS',             'Hermès',         'hermes',    100.0, 'FR', 'fashion_leather'),
  -- Chanel ----------------------------------------------------------------
  ('chanel-mode',    'Chanel SAS',                     'Chanel',         'chanel',    100.0, 'FR', 'fashion_leather')
) as v(slug, legal_name, display_name, parent_slug, ownership_pct, country, sector_code)
join entities p on p.slug = v.parent_slug
join sectors  s on s.code = v.sector_code
on conflict (slug) do nothing;
