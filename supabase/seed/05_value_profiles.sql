-- =============================================================================
-- Seed 05 : profils de valeurs + pondérations
-- Les faits sont neutres ; le jugement (poids par dimension) vit ici.
-- L'utilisateur choisira un profil (ou le personnalisera via les sliders).
-- =============================================================================

insert into value_profiles (code, name, description, is_default) values
  ('equilibre',    'Équilibré',            'Toutes les dimensions comptent de façon comparable.', true),
  ('ecolo',        'Écologie d''abord',    'Priorité à l''impact environnemental.', false),
  ('vivant',       'Bien-être du vivant',  'Priorité aux animaux (humains et non-humains) : travail, chaîne d''appro, bien-être animal.', false),
  ('transparence', 'Transparence & probité','Priorité à la fiscalité, la gouvernance et les prises de position.', false)
on conflict (code) do nothing;

insert into profile_weights (profile_id, dimension_id, weight)
select p.id, d.id, w.weight
from (values
  -- profil       dim     poids
  ('equilibre',   'ENV', 0.15), ('equilibre',   'LAB', 0.15), ('equilibre',   'SUP', 0.15),
  ('equilibre',   'ANI', 0.15), ('equilibre',   'GEO', 0.10), ('equilibre',   'TAX', 0.15),
  ('equilibre',   'GOV', 0.15),

  ('ecolo',       'ENV', 0.35), ('ecolo',       'LAB', 0.10), ('ecolo',       'SUP', 0.15),
  ('ecolo',       'ANI', 0.15), ('ecolo',       'GEO', 0.05), ('ecolo',       'TAX', 0.10),
  ('ecolo',       'GOV', 0.10),

  ('vivant',      'ENV', 0.10), ('vivant',      'LAB', 0.25), ('vivant',      'SUP', 0.25),
  ('vivant',      'ANI', 0.25), ('vivant',      'GEO', 0.05), ('vivant',      'TAX', 0.05),
  ('vivant',      'GOV', 0.05),

  ('transparence','ENV', 0.08), ('transparence','LAB', 0.07), ('transparence','SUP', 0.15),
  ('transparence','ANI', 0.05), ('transparence','GEO', 0.15), ('transparence','TAX', 0.25),
  ('transparence','GOV', 0.25)
) as w(profile_code, dim_code, weight)
join value_profiles p on p.code = w.profile_code
join dimensions     d on d.code = w.dim_code
on conflict (profile_id, dimension_id) do nothing;
