-- =============================================================================
-- Migration 0010 : dédoublonnage de l'evidence
-- -----------------------------------------------------------------------------
-- Les imports du pipeline doivent être idempotents : relancer un connecteur ne
-- doit jamais créer de doublon. Un même fait = même entité + même indicateur +
-- même source + même date d'observation.
-- =============================================================================

create unique index if not exists evidence_dedupe_idx
  on evidence (entity_id, indicator_id, source_id, observed_on);
