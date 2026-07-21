-- =============================================================================
-- Check d'intégrité des données DIAMS.
-- -----------------------------------------------------------------------------
-- À rejouer avant chaque déploiement. Ne renvoie QUE les violations :
-- résultat vide = tout est vert. Une ligne = un problème à corriger.
--   psql "$DATABASE_URL" -f supabase/checks/integrity.sql
-- (ou via l'éditeur SQL Supabase / le MCP)
-- =============================================================================

select verif, n from (
  -- Valeurs de score/confiance hors de l'intervalle [0,1]
  select 'normalized_hors_[0,1]' as verif, count(*) n
    from evidence where normalized_value is not null and (normalized_value < 0 or normalized_value > 1)
  union all
  select 'confidence_hors_[0,1]', count(*)
    from evidence where confidence is not null and (confidence < 0 or confidence > 1)
  -- Traçabilité : une preuve doit avoir une source, et une preuve approuvée une URL
  union all
  select 'evidence_sans_source', count(*)
    from evidence where source_id is null
  union all
  select 'evidence_approuvee_sans_url', count(*)
    from evidence ev join sources s on s.id = ev.source_id
    where ev.review_status = 'approved' and coalesce(ev.source_url, s.url) is null
  -- Cohérence du graphe d'entités
  union all
  select 'marque_sans_parent', count(*)
    from entities where is_brand = true and parent_id is null
  union all
  select 'entite_sans_secteur', count(*)
    from entities where sector_id is null
  union all
  select 'indicateur_sans_dimension', count(*)
    from indicators where dimension_id is null
  -- Fraîcheur : pas de date d'observation dans le futur
  union all
  select 'evidence_observed_on_futur', count(*)
    from evidence where observed_on > current_date
  -- Pipeline marques : un rattachement doit viser un groupe existant
  union all
  select 'brand_resolution_groupe_inexistant', count(*)
    from brand_resolutions br
    where br.group_slug is not null
      and not exists (select 1 from entities e where e.slug = br.group_slug)
  union all
  select 'alias_norme_vide', count(*)
    from entity_aliases where coalesce(norm, '') = ''
) t
where n > 0
order by verif;
