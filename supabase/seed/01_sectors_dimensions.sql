-- =============================================================================
-- Seed 01 : secteurs, dimensions, méta-groupes
-- Périmètre de départ : LUXE / MODE (France + UE).
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Secteurs (base de la normalisation intra-secteur)
-- ---------------------------------------------------------------------------
insert into sectors (code, name, description) values
  ('luxury_group',     'Groupe de luxe (holding)', 'Conglomérat multi-marques de luxe.'),
  ('fashion_leather',  'Mode & Maroquinerie',      'Prêt-à-porter, maroquinerie, chaussures, cuir.'),
  ('watches_jewelry',  'Horlogerie & Joaillerie',  'Montres, joaillerie, haute joaillerie.'),
  ('beauty_fragrance', 'Beauté & Parfums',         'Cosmétiques, parfums, soins.'),
  ('wines_spirits',    'Vins & Spiritueux',        'Champagnes, vins, spiritueux.')
on conflict (code) do nothing;

-- ---------------------------------------------------------------------------
-- Dimensions (7 axes). default_weight ~ équilibré ; les vrais poids viennent
-- des value_profiles.
-- ---------------------------------------------------------------------------
insert into dimensions (code, name, description, default_weight, display_order) values
  ('ENV', 'Environnement',
   'Climat, émissions, matières, biodiversité.', 0.1500, 1),
  ('LAB', 'Travail & Rémunération',
   'Conditions de travail, équité salariale, dialogue social (bien-être des animaux humains, en interne).', 0.1500, 2),
  ('SUP', 'Chaîne d''appro & Droits humains',
   'Devoir de vigilance, transparence fournisseurs, droits humains (bien-être des animaux humains, en amont).', 0.1500, 3),
  ('ANI', 'Bien-être animal (non-humain)',
   'Élevage, cuirs, laine, duvet, fourrure, tests, abattage et transport des animaux non-humains.', 0.1500, 4),
  ('GEO', 'Géopolitique & Prises de position',
   'Lobbying, financement politique, positionnements (ex: retrait de Russie).', 0.1000, 5),
  ('TAX', 'Fiscalité',
   'Transparence pays-par-pays, présence en juridictions à faible imposition.', 0.1500, 6),
  ('GOV', 'Gouvernance',
   'Indépendance du conseil, sanctions réglementaires, contrôle.', 0.1000, 7)
on conflict (code) do nothing;

-- ---------------------------------------------------------------------------
-- Méta-groupes (méta-scores affichés au-dessus du détail)
-- "Bien-être du vivant" = animal non-humain + travail + chaîne d'appro humaine.
-- Philosophie : les humains sont des animaux ; on couvre tout le vivant.
-- ---------------------------------------------------------------------------
insert into dimension_groups (code, name, description, display_order) values
  ('LIVING', 'Bien-être du vivant',
   'Méta-score agrégeant le bien-être animal non-humain et le bien-être humain (travail interne + chaîne d''approvisionnement).', 1)
on conflict (code) do nothing;

insert into dimension_group_members (group_id, dimension_id, weight)
select g.id, d.id, w.weight
from (values
  ('LIVING', 'ANI', 1.0),
  ('LIVING', 'LAB', 1.0),
  ('LIVING', 'SUP', 1.0)
) as w(group_code, dim_code, weight)
join dimension_groups g on g.code = w.group_code
join dimensions d       on d.code = w.dim_code
on conflict (group_id, dimension_id) do nothing;
