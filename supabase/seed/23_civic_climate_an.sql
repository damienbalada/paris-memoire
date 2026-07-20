-- =============================================================================
-- Seed 23 : DIAMS Civique — pilote France (Assemblée nationale, pilier Climat).
-- 16e législature (2022-2024). Données sourcées via analyses de scrutin publiques.
-- Décomptes exacts par groupe partiels (scrutins nominatifs non encore ingérés) ;
-- position (stance) attribuable + décomptes réels là où connus (GDR nucléaire,
-- PS abstention). Le vote est un FAIT : voter « contre » ne vaut pas jugement
-- d'intention (ex : la gauche a voté contre la loi EnR en la jugeant insuffisante).
-- =============================================================================

insert into political_groups (code, name, short_name, chamber, ordinal) values
  ('AN_LFI', 'La France insoumise — NUPES',                 'LFI',   'AN', 11),
  ('AN_ECO', 'Écologistes — NUPES',                         'Écolo', 'AN', 12),
  ('AN_GDR', 'Gauche démocrate et républicaine — NUPES',    'GDR',   'AN', 13),
  ('AN_SOC', 'Socialistes et apparentés',                   'PS',    'AN', 14),
  ('AN_RE',  'Renaissance',                                 'RE',    'AN', 15),
  ('AN_DEM', 'Démocrate (MoDem et Indépendants)',           'MoDem', 'AN', 16),
  ('AN_HOR', 'Horizons et apparentés',                      'Horiz.','AN', 17),
  ('AN_LIOT','Libertés, Indépendants, Outre-mer, Territoires','LIOT','AN', 18),
  ('AN_LR',  'Les Républicains',                            'LR',    'AN', 19),
  ('AN_RN',  'Rassemblement national',                      'RN',    'AN', 20)
on conflict (code) do nothing;

insert into civic_votes (code, title, vote_date, pillar_code, chamber, source_url, alignment_note,
  total_for, total_against, total_abstain) values
  ('AN_ENR_2023',
   'Loi accélération de la production d''énergies renouvelables',
   '2023-01-10', 'ENV', 'AN',
   'https://www.assemblee-nationale.fr/dyn/16/scrutins/823',
   'Voter POUR = soutien à ce texte d''accélération des renouvelables. Attention : plusieurs groupes de gauche ont voté CONTRE en le jugeant insuffisant — le vote est un fait, pas un jugement d''intention.',
   286, 238, 38),
  ('AN_NUCLEAIRE_2023',
   'Loi accélération du nucléaire',
   '2023-03-21', 'ENV', 'AN',
   'https://www.assemblee-nationale.fr/dyn/16/scrutins/1243',
   'Relance du nucléaire (énergie bas-carbone, mais contestée sur sûreté/déchets). Le sens du vote recouvre des motifs variés — on affiche le fait, pas une intention.',
   402, 130, 8)
on conflict (code) do nothing;

-- Positions — Loi EnR (scrutin 823).
insert into civic_positions (vote_id, group_id, stance, note)
select v.id, g.id, x.stance, x.note
from (values
  ('AN_RE','for',    'Majorité présidentielle : pour.'),
  ('AN_DEM','for',   'Pour.'),
  ('AN_HOR','for',   'Pour.'),
  ('AN_SOC','for',   'Soutien des socialistes.'),
  ('AN_LFI','against','Contre — texte jugé insuffisant.'),
  ('AN_ECO','against','Contre — texte jugé insuffisant.'),
  ('AN_GDR','against','Contre.'),
  ('AN_LR','against','Contre.'),
  ('AN_RN','against','Contre.')
) as x(gcode, stance, note)
join civic_votes v on v.code='AN_ENR_2023'
join political_groups g on g.code=x.gcode
on conflict (vote_id, group_id) do nothing;

-- Positions — Loi nucléaire (scrutin 1243). Décomptes réels connus pour GDR.
insert into civic_positions (vote_id, group_id, stance, n_for, n_against, n_abstain, note)
select v.id, g.id, x.stance, x.nf, x.na, x.nab, x.note
from (values
  ('AN_RE','for',     null::int, null::int, null::int, 'Pour.'),
  ('AN_DEM','for',    null, null, null, 'Pour.'),
  ('AN_HOR','for',    null, null, null, 'Pour.'),
  ('AN_LR','for',     null, null, null, 'Pour.'),
  ('AN_RN','for',     null, null, null, 'Pour.'),
  ('AN_LIOT','for',   null, null, null, 'Pour.'),
  ('AN_LFI','against',null, null, null, 'Contre.'),
  ('AN_ECO','against',null, null, null, 'Contre.'),
  ('AN_SOC','abstain',null, null, null, 'Abstention du groupe.'),
  ('AN_GDR','split',  10,   4,    4,    'Groupe divisé : 10 pour, 4 contre, 4 abstentions.')
) as x(gcode, stance, nf, na, nab, note)
join civic_votes v on v.code='AN_NUCLEAIRE_2023'
join political_groups g on g.code=x.gcode
on conflict (vote_id, group_id) do nothing;
