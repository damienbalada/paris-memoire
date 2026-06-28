-- =============================================================================
-- Migration 0002 : configuration de la méthodologie (versionnée, en base)
-- -----------------------------------------------------------------------------
-- On stocke les règles de scoring EN BASE (pas en dur dans l'Edge Function)
-- pour qu'elles soient datées, auditables et modifiables sans redéploiement.
-- Trois règles, tranchées avec le porteur du projet :
--   (1) Donnée manquante => score 0 (pénalisant) + confiance basse.
--   (2) Solidité des sources => le tier pondère ET plafonne l'impact ;
--       une source peu fiable (presse/crowd) ne peut pas, seule, faire
--       chuter une note sous un plancher tant qu'aucune source fiable
--       ne confirme.
--   (3) Promesse vs preuve => une evidence 'commitment'/'policy' plafonne
--       le score d'un indicateur ; seule une 'result' débloque le haut.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Poids et plafonds par tier de source (règle 2)
-- ---------------------------------------------------------------------------
create table source_tier_config (
  tier                 source_tier primary key,
  -- Poids multiplicatif de l'evidence selon la solidité de la source.
  evidence_weight      numeric(4,3) not null check (evidence_weight >= 0 and evidence_weight <= 1),
  -- Plafond de confiance qu'une evidence de ce tier peut apporter à un indicateur.
  max_confidence       numeric(4,3) not null check (max_confidence >= 0 and max_confidence <= 1),
  -- Une evidence de ce tier peut-elle, SEULE, faire chuter un score sous le
  -- plancher défini par min_score_floor_when_alone ?
  can_penalize_alone   boolean not null default true,
  -- Plancher de score qu'une evidence de ce tier ne peut pas franchir seule
  -- (ex: presse seule ne descend pas un indicateur sous 0.30).
  min_score_floor_alone numeric(4,3) not null default 0
                         check (min_score_floor_alone >= 0 and min_score_floor_alone <= 1),
  notes                text
);

comment on table source_tier_config is
  'Règle 2 (solidité des sources) : pondération et plafonds par tier. Tier 1 (regulatory) poids plein ; tier 3 (press/crowd) bridé et plafonné.';

insert into source_tier_config
  (tier, evidence_weight, max_confidence, can_penalize_alone, min_score_floor_alone, notes) values
  ('regulatory',  1.000, 1.000, true,  0.000,
    'Obligation légale (CSRD, devoir de vigilance, AMF, CbCR). Poids plein, aucun plancher.'),
  ('audited_ngo', 0.800, 0.850, true,  0.000,
    'Index/ONG audité (FTI, KnowTheChain, BBFAW, Textile Exchange). Très fiable mais non régalien.'),
  ('press',       0.350, 0.450, false, 0.300,
    'Presse / allégations. Compte un peu, plafonné ; ne peut pas seule descendre un indicateur sous 0.30.'),
  ('crowd',       0.200, 0.300, false, 0.400,
    'Contributif / militant non audité (ex: PETA). Compte faiblement, plafond bas, plancher haut.');

-- ---------------------------------------------------------------------------
-- Multiplicateurs et plafonds par nature d'evidence (règle 3, anti-greenwashing)
-- ---------------------------------------------------------------------------
create table evidence_nature_config (
  nature                  evidence_nature primary key,
  -- Multiplicateur appliqué à la valeur normalisée de l'evidence.
  score_multiplier        numeric(4,3) not null check (score_multiplier >= 0 and score_multiplier <= 1),
  -- Score maximal qu'un indicateur peut atteindre s'il n'est alimenté QUE
  -- par des evidence de cette nature (null = pas de plafond).
  max_score_without_result numeric(4,3)
                            check (max_score_without_result is null
                                   or (max_score_without_result >= 0 and max_score_without_result <= 1)),
  notes                   text
);

comment on table evidence_nature_config is
  'Règle 3 (anti-greenwashing) : une promesse rapporte peu, une preuve rapporte plein. Tant qu''aucune evidence "result" n''existe, l''indicateur est plafonné.';

insert into evidence_nature_config
  (nature, score_multiplier, max_score_without_result, notes) values
  ('result',      1.000, null,
    'Résultat mesuré et vérifiable. Poids plein, aucun plafond.'),
  ('policy',      0.700, 0.600,
    'Politique formalisée sans résultat prouvé. Plafonnée à 0.60 sans "result".'),
  ('commitment',  0.400, 0.500,
    'Promesse / engagement futur. Plafonnée à 0.50 sans "result".'),
  ('controversy', 1.000, null,
    'Controverse : traitée comme un signal négatif à part entière (le plafond ne s''applique pas, c''est une pénalité).');

-- ---------------------------------------------------------------------------
-- Paramètres globaux de scoring (règle 1 + divers)
-- ---------------------------------------------------------------------------
create table scoring_params (
  key         text primary key,
  value       numeric not null,
  description text
);

insert into scoring_params (key, value, description) values
  ('missing_data_score',        0.000, 'Règle 1 : score d''une dimension sans evidence active (pénalisant).'),
  ('missing_data_confidence',   0.000, 'Confiance d''une dimension sans evidence active.'),
  ('evidence_horizon_years',    5,     'Décroissance : une evidence n''est plus active au-delà de N ans.'),
  ('min_confidence_to_publish', 0.300, 'Confiance minimale d''une fiche pour affichage public.');

comment on table scoring_params is
  'Paramètres globaux du moteur de score, datés et auditables (règle "donnée manquante = 0" notamment).';
