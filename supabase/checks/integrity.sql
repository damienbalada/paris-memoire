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
  -- Cohérence des indicateurs-gate : la sémantique de `normalized_value` dépend de
  -- la nature (result -> plafond direct ; controversy -> sévérité convertie en
  -- plafond). Un gate qui mélange les natures casse cette interprétation.
  union all
  select 'gate_natures_incoherentes', count(*) from (
    select dg.gate_indicator_id
      from dimension_gates dg
      join evidence ev on ev.indicator_id = dg.gate_indicator_id and ev.review_status = 'approved'
     group by dg.gate_indicator_id
    having count(distinct ev.nature) > 1
  ) g
  -- Valeur exploitable : une preuve approuvée sans normalized/numeric/boolean
  -- retombe silencieusement sur 0.5 dans le moteur (ni bon ni mauvais signal).
  union all
  select 'evidence_approuvee_sans_valeur', count(*)
    from evidence
   where review_status = 'approved'
     and normalized_value is null and value_numeric is null and value_boolean is null
  -- ANTI-RÉCIDIVE : aucune donnée de démonstration ne doit être publiée. Une note
  -- adossée à une preuve inventée ruine la promesse du produit (audit 07/2026 :
  -- 70 lignes `seed-demo` comptaient dans les scores des plus grandes marques).
  union all
  select 'evidence_demo_publiee', count(*)
    from evidence
   where review_status = 'approved'
     and (reviewer ilike '%demo%' or excerpt ilike '%(démo)%' or excerpt ilike '%(demo)%')
  -- Traçabilité : une preuve publiée doit TOUJOURS être remontable à une source.
  union all
  select 'evidence_publiee_sans_url_propre', count(*)
    from evidence ev join sources s on s.id = ev.source_id
   where ev.review_status = 'approved' and ev.source_url is null and s.url is null
) t
where n > 0
order by verif;
