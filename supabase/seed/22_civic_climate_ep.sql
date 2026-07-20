-- =============================================================================
-- Seed 22 : DIAMS Civique — pilote pilier Climat (Parlement européen).
-- Données vérifiées : résultat global + position majoritaire de chaque groupe,
-- sourcées (communiqués officiels du PE / presse). Les décomptes exacts par
-- groupe (n_for/n_against) seront enrichis quand la base de scrutins nominatifs
-- sera accessible ; ici on renseigne la position (stance) attribuable.
-- =============================================================================

insert into political_groups (code, name, short_name, chamber, ordinal) values
  ('GUE',    'La Gauche au Parlement européen — GUE/NGL', 'La Gauche', 'EP', 1),
  ('GREENS', 'Verts/Alliance libre européenne',           'Verts/ALE', 'EP', 2),
  ('SD',     'Alliance progressiste des socialistes et démocrates', 'S&D', 'EP', 3),
  ('RENEW',  'Renew Europe',                               'Renew',     'EP', 4),
  ('EPP',    'Parti populaire européen',                   'PPE',       'EP', 5),
  ('ECR',    'Conservateurs et réformistes européens',     'CRE',       'EP', 6),
  ('ID',     'Identité et démocratie',                     'ID',        'EP', 7),
  ('NI',     'Non-inscrits',                               'NI',        'EP', 8)
on conflict (code) do nothing;

-- Vote 1 : Loi sur la restauration de la nature (adoptée le 27/02/2024).
insert into civic_votes (code, title, vote_date, pillar_code, chamber, source_url, alignment_note,
  total_for, total_against, total_abstain) values
  ('EP_NATURE_RESTORATION_2024',
   'Loi sur la restauration de la nature',
   '2024-02-27', 'ENV', 'EP',
   'https://www.europarl.europa.eu/news/en/press-room/20240223IPR18078/',
   'Voter POUR = soutien à une contrainte forte de restauration des écosystèmes (sens du pilier Environnement de DIAMS).',
   329, 275, 24)
on conflict (code) do nothing;

-- Vote 2 : Fin des voitures thermiques neuves en 2035 (adoptée le 14/02/2023).
insert into civic_votes (code, title, vote_date, pillar_code, chamber, source_url, alignment_note,
  total_for, total_against, total_abstain) values
  ('EP_CARS_ZEV_2035_2023',
   'Fin des voitures thermiques neuves en 2035 (normes CO₂)',
   '2023-02-14', 'ENV', 'EP',
   'https://www.europarl.europa.eu/news/en/press-room/20230210IPR74715/fit-for-55-zero-co2-emissions-for-new-cars-and-vans-in-2035',
   'Voter POUR = soutien à une contrainte climatique forte sur l''automobile (sens du pilier Environnement de DIAMS).',
   340, 279, 21)
on conflict (code) do nothing;

-- Positions par groupe — Restauration de la nature (2024).
insert into civic_positions (vote_id, group_id, stance, n_for, note)
select v.id, g.id, x.stance, x.n_for, x.note
from (values
  ('GUE','for',    null::int, 'Soutien du groupe.'),
  ('GREENS','for', null,      'Soutien du groupe.'),
  ('SD','for',     null,      'Soutien du groupe.'),
  ('RENEW','for',  null,      'Majoritairement pour (quelques défections).'),
  ('EPP','split',  25,        'Groupe divisé : 25 élus pour sur ~177, majorité contre.'),
  ('ECR','against',null,      'Opposition du groupe.'),
  ('ID','against', null,      'Opposition du groupe.'),
  ('NI','split',   null,      'Position partagée.')
) as x(gcode, stance, n_for, note)
join civic_votes v on v.code='EP_NATURE_RESTORATION_2024'
join political_groups g on g.code=x.gcode
on conflict (vote_id, group_id) do nothing;

-- Positions par groupe — Fin du thermique 2035 (2023).
insert into civic_positions (vote_id, group_id, stance, note)
select v.id, g.id, x.stance, x.note
from (values
  ('GUE','for',    'Soutien du groupe.'),
  ('GREENS','for', 'Soutien du groupe.'),
  ('SD','for',     'Soutien du groupe.'),
  ('RENEW','for',  'Majoritairement pour.'),
  ('EPP','against','Opposition majoritaire du groupe.'),
  ('ECR','against','Opposition du groupe.'),
  ('ID','against', 'Opposition du groupe.'),
  ('NI','split',   'Position partagée.')
) as x(gcode, stance, note)
join civic_votes v on v.code='EP_CARS_ZEV_2035_2023'
join political_groups g on g.code=x.gcode
on conflict (vote_id, group_id) do nothing;
