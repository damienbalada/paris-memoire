-- =============================================================================
-- Seed 25 : portefeuilles de marques non-food (auto, luxe, tech).
-- -----------------------------------------------------------------------------
-- Rattachement marque -> groupe pour des secteurs concentrés où la propriété est
-- stable et publique (bien plus fiable qu'une ingestion de masse). Les marques
-- HÉRITENT des preuves ESG de leur groupe (cf. Peugeot -> Stellantis).
-- Source de propriété : sites corporate / Wikidata (faits notoires).
-- =============================================================================

insert into entities (slug, legal_name, display_name, is_brand, parent_id, sector_id, country)
select v.slug, v.name, v.name, true,
       (select id from entities g where g.slug = v.parent),
       (select id from sectors s where s.code = v.sector),
       v.country
from (values
  -- ===== AUTOMOBILE =====
  ('audi','Audi','volkswagen','automotive','DE'),
  ('porsche','Porsche','volkswagen','automotive','DE'),
  ('skoda','Škoda','volkswagen','automotive','CZ'),
  ('seat-cupra','SEAT / Cupra','volkswagen','automotive','ES'),
  ('lamborghini','Lamborghini','volkswagen','automotive','IT'),
  ('bentley','Bentley','volkswagen','automotive','GB'),
  ('citroen','Citroën','stellantis','automotive','FR'),
  ('ds-automobiles','DS Automobiles','stellantis','automotive','FR'),
  ('fiat','Fiat','stellantis','automotive','IT'),
  ('opel','Opel','stellantis','automotive','DE'),
  ('jeep','Jeep','stellantis','automotive','US'),
  ('alfa-romeo','Alfa Romeo','stellantis','automotive','IT'),
  ('maserati','Maserati','stellantis','automotive','IT'),
  ('dacia','Dacia','renault','automotive','RO'),
  ('alpine','Alpine','renault','automotive','FR'),
  ('mini','MINI','bmw','automotive','GB'),
  ('rolls-royce-cars','Rolls-Royce Motor Cars','bmw','automotive','GB'),
  ('lexus','Lexus','toyota','automotive','JP'),
  -- ===== LUXE =====
  ('louis-vuitton','Louis Vuitton','lvmh','fashion_leather','FR'),
  ('dior','Dior','lvmh','fashion_leather','FR'),
  ('fendi','Fendi','lvmh','fashion_leather','IT'),
  ('celine','Celine','lvmh','fashion_leather','FR'),
  ('givenchy','Givenchy','lvmh','fashion_leather','FR'),
  ('sephora','Sephora','lvmh','beauty_fragrance','FR'),
  ('guerlain','Guerlain','lvmh','beauty_fragrance','FR'),
  ('moet-chandon','Moët & Chandon','lvmh','wines_spirits','FR'),
  ('hennessy','Hennessy','lvmh','wines_spirits','FR'),
  ('tag-heuer','TAG Heuer','lvmh','watches_jewelry','CH'),
  ('bulgari','Bulgari','lvmh','watches_jewelry','IT'),
  ('tiffany','Tiffany & Co.','lvmh','watches_jewelry','US'),
  ('gucci','Gucci','kering','fashion_leather','IT'),
  ('saint-laurent','Saint Laurent','kering','fashion_leather','FR'),
  ('bottega-veneta','Bottega Veneta','kering','fashion_leather','IT'),
  ('balenciaga','Balenciaga','kering','fashion_leather','ES'),
  ('alexander-mcqueen','Alexander McQueen','kering','fashion_leather','GB'),
  ('boucheron','Boucheron','kering','watches_jewelry','FR'),
  ('cartier','Cartier','richemont','watches_jewelry','FR'),
  ('van-cleef-arpels','Van Cleef & Arpels','richemont','watches_jewelry','FR'),
  ('montblanc','Montblanc','richemont','watches_jewelry','DE'),
  ('iwc','IWC Schaffhausen','richemont','watches_jewelry','CH'),
  ('jaeger-lecoultre','Jaeger-LeCoultre','richemont','watches_jewelry','CH'),
  ('piaget','Piaget','richemont','watches_jewelry','CH'),
  -- ===== TECH =====
  ('youtube','YouTube','google','tech_electronics','US'),
  ('android','Android','google','tech_electronics','US'),
  ('nest','Google Nest','google','tech_electronics','US'),
  ('waze','Waze','google','tech_electronics','US'),
  ('fitbit','Fitbit','google','tech_electronics','US'),
  ('xbox','Xbox','microsoft','tech_electronics','US'),
  ('linkedin','LinkedIn','microsoft','tech_electronics','US'),
  ('github','GitHub','microsoft','tech_electronics','US'),
  ('facebook','Facebook','meta','tech_electronics','US'),
  ('instagram','Instagram','meta','tech_electronics','US'),
  ('whatsapp','WhatsApp','meta','tech_electronics','US'),
  ('oculus','Meta Quest (Oculus)','meta','tech_electronics','US'),
  ('aws','Amazon Web Services','amazon','tech_electronics','US'),
  ('twitch','Twitch','amazon','tech_electronics','US'),
  ('audible','Audible','amazon','tech_electronics','US'),
  ('ring','Ring','amazon','tech_electronics','US'),
  ('prime-video','Prime Video','amazon','tech_electronics','US'),
  ('playstation','PlayStation','sony','tech_electronics','JP')
) as v(slug, name, parent, sector, country)
where exists (select 1 from entities g where g.slug = v.parent)
on conflict (slug) do nothing;
