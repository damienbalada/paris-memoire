-- =============================================================================
-- Seed 02 : indicateurs
-- Chaque indicateur : code, dimension, kind, direction, spécificité sectorielle,
-- unité, méthodo de normalisation (texte court). Normalisation = INTRA-SECTEUR.
-- =============================================================================

insert into indicators
  (code, dimension_id, name, kind, direction, sector_specific, applies_to_sector_id, weight, unit, methodology)
select
  v.code, d.id, v.name, v.kind::indicator_kind, v.direction::indicator_direction,
  v.sector_specific, s.id, v.weight, v.unit, v.methodology
from (values
  -- ENVIRONNEMENT -----------------------------------------------------------
  ('ENV_CDP_CLIMATE',     'ENV', 'Note climat CDP',                       'ordinal',      'higher_better', false, null,              1.0, 'grade',      'Lettre CDP A..D- mappée sur [0,1], puis percentile intra-secteur.'),
  ('ENV_SBTI_VALIDATED',  'ENV', 'Objectifs SBTi validés',                'categorical',  'higher_better', false, null,              1.0, 'status',     'none/committed/near-term/1.5C-validated -> 0/0.3/0.6/1. Engagement vs résultat.'),
  ('ENV_SCOPE3_DISCLOSED','ENV', 'Émissions Scope 3 publiées',            'binary',       'higher_better', false, null,              0.8, 'bool',       'Publication + couverture % des postes Scope 3 (CSRD ESRS E1).'),
  ('ENV_GHG_INTENSITY',   'ENV', 'Intensité carbone',                     'quantitative', 'lower_better',  false, null,              1.0, 'tCO2e/M€',   'Émissions / chiffre d''affaires, percentile inversé intra-secteur.'),
  ('ENV_MATERIAL_CHANGE', 'ENV', 'Matières durables (Textile Exchange)',  'ordinal',      'higher_better', true,  'fashion_leather', 1.0, 'rank',       'Material Change Index : rang -> percentile.'),

  -- TRAVAIL & RÉMUNÉRATION (bien-être humain interne) -----------------------
  ('LAB_CEO_PAY_RATIO',   'LAB', 'Ratio rému dirigeant / médian',         'quantitative', 'lower_better',  false, null,              1.0, 'ratio',      'Ratio DPEF/CSRD S1, percentile inversé intra-secteur.'),
  ('LAB_EGAPRO_INDEX',    'LAB', 'Index égalité F/H (Égapro)',            'quantitative', 'higher_better', false, null,              1.0, 'score/100',  'Index Égapro FR /100 -> [0,1].'),
  ('LAB_GENDER_PAYGAP',   'LAB', 'Écart salarial F/H',                    'quantitative', 'lower_better',  false, null,              0.8, '%',          'Écart % CSRD S1, percentile inversé.'),
  ('LAB_LIVING_WAGE',     'LAB', 'Salaire décent interne',                'categorical',  'higher_better', false, null,              0.8, 'status',     'none/policy/verified -> 0/0.5/1.'),
  ('LAB_LITIGATION_RATE', 'LAB', 'Contentieux prud''homaux',              'quantitative', 'lower_better',  false, null,              0.6, 'count/1000', 'Nb contentieux normalisé par effectif, percentile inversé.'),

  -- CHAÎNE D''APPRO & DROITS HUMAINS (bien-être humain en amont) ------------
  ('SUP_VIGILANCE_PLAN',  'SUP', 'Plan de vigilance (complétude)',        'ordinal',      'higher_better', false, null,              1.0, 'level',      'Loi FR 2017 : absent/partiel/cartographie+suivi -> 0/0.5/1.'),
  ('SUP_FTI_SCORE',       'SUP', 'Fashion Transparency Index',            'quantitative', 'higher_better', true,  'fashion_leather', 1.0, 'score/250',  'Score FTI /250 -> [0,1].'),
  ('SUP_KNOWTHECHAIN',    'SUP', 'KnowTheChain (travail forcé)',          'quantitative', 'higher_better', false, null,              1.0, 'score/100',  'Score KnowTheChain /100 -> [0,1].'),
  ('SUP_SUPPLIER_LIST',   'SUP', 'Publication liste fournisseurs',        'binary',       'higher_better', false, null,              0.7, 'bool',       'Liste des sites de production publiée (oui/non).'),
  ('SUP_LIVING_WAGE',     'SUP', 'Salaire décent fournisseurs',           'categorical',  'higher_better', false, null,              0.9, 'status',     'Fair Wear / engagement : none/policy/verified -> 0/0.5/1.'),
  ('SUP_BHRRC_ALLEG',     'SUP', 'Allégations droits humains',            'quantitative', 'lower_better',  false, null,              0.6, 'count',      'Nb allégations BHRRC sur 5 ans (source presse, poids bas), percentile inversé.'),

  -- BIEN-ÊTRE ANIMAL (non-humain) — périmètre élargi ------------------------
  ('ANI_FUR_FREE',        'ANI', 'Politique sans fourrure',               'binary',       'higher_better', true,  'fashion_leather', 1.0, 'bool',       'Listé Fur Free Retailer / engagement public sans fourrure.'),
  ('ANI_EXOTIC_SKINS',    'ANI', 'Peaux exotiques',                       'categorical',  'higher_better', true,  'fashion_leather', 0.8, 'policy',     'none/policy/ban -> 0/0.5/1.'),
  ('ANI_LEATHER_TRACE',   'ANI', 'Traçabilité & tannage du cuir',         'ordinal',      'higher_better', true,  'fashion_leather', 0.9, 'level',      'Leather Working Group + traçabilité origine : aucun/certifié/traçé+certifié -> 0/0.5/1.'),
  ('ANI_WOOL_MULESING',   'ANI', 'Laine sans mulesing',                   'categorical',  'higher_better', true,  'fashion_leather', 0.8, 'policy',     'none/policy/certified (RWS/mulesing-free) -> 0/0.5/1.'),
  ('ANI_DOWN_RDS',        'ANI', 'Duvet responsable (sans plumage à vif)','categorical',  'higher_better', true,  'fashion_leather', 0.7, 'policy',     'none/policy/RDS certifié -> 0/0.5/1.'),
  ('ANI_ANGORA_MOHAIR',   'ANI', 'Angora & mohair',                       'categorical',  'higher_better', true,  'fashion_leather', 0.6, 'policy',     'Ban angora / mohair certifié RMS : none/policy/ban-or-RMS -> 0/0.5/1.'),
  ('ANI_TESTING',         'ANI', 'Tests sur animaux',                     'categorical',  'higher_better', true,  'beauty_fragrance',0.9, 'policy',     'Politique cosmétique : tests/aucun engagement/cruelty-free certifié -> 0/0.5/1.'),
  ('ANI_BBFAW_TIER',      'ANI', 'Tier BBFAW',                            'ordinal',      'higher_better', false, null,              0.8, 'tier',       'Benchmark BBFAW tier 6..1 -> [0,1].'),
  ('ANI_SLAUGHTER',       'ANI', 'Standards abattage & transport',        'ordinal',      'higher_better', true,  'fashion_leather', 0.7, 'level',      'Standards de bien-être à l''abattage/transport : aucun/engagement/audité -> 0/0.5/1.'),

  -- GÉOPOLITIQUE & PRISES DE POSITION ---------------------------------------
  ('GEO_RUSSIA_EXIT',     'GEO', 'Position Russie (liste Yale)',          'categorical',  'higher_better', false, null,              1.0, 'status',     'maintien/réduction/suspension/retrait -> 0/0.4/0.7/1 (liste Yale CELI).'),
  ('GEO_LOBBYING_TRANSP', 'GEO', 'Transparence lobbying',                 'binary',       'higher_better', false, null,              0.7, 'bool',       'Inscription HATVP / registre transparence UE (oui/non).'),
  ('GEO_LOBBYING_SPEND',  'GEO', 'Dépenses de lobbying déclarées',        'quantitative', 'contextual',    false, null,              0.4, '€',          'Montant déclaré HATVP/UE. Contextuel : affiché, non pénalisant en soi.'),
  ('GEO_POL_FINANCING',   'GEO', 'Financement politique',                 'quantitative', 'contextual',    false, null,              0.4, '€',          'Données CNCCFP (structurellement pauvres en FR). Contextuel.'),

  -- FISCALITÉ ----------------------------------------------------------------
  ('TAX_CBCR_PUBLISHED',  'TAX', 'Reporting pays-par-pays publié',        'binary',       'higher_better', false, null,              1.0, 'bool',       'Déclaration CbCR publique (oui/non).'),
  ('TAX_HAVEN_PRESENCE',  'TAX', 'Présence en juridictions à faible imposition', 'quantitative', 'lower_better', false, null,        1.0, 'count',      'Nb d''entités en juridictions listées (Tax Justice Network), percentile inversé.'),
  ('TAX_EFFECTIVE_RATE',  'TAX', 'Taux effectif d''imposition',           'quantitative', 'higher_better', false, null,              0.8, '%',          'Taux effectif vs taux statutaire, percentile intra-secteur.'),

  -- GOUVERNANCE --------------------------------------------------------------
  ('GOV_BOARD_INDEP',     'GOV', 'Administrateurs indépendants',          'quantitative', 'higher_better', false, null,              1.0, '%',          '% d''administrateurs indépendants (doc AMF/URD), percentile intra-secteur.'),
  ('GOV_BOARD_GENDER',    'GOV', 'Mixité du conseil',                     'quantitative', 'higher_better', false, null,              0.7, '%',          '% de femmes au conseil.'),
  ('GOV_SANCTIONS',       'GOV', 'Sanctions réglementaires',              'quantitative', 'lower_better',  false, null,              0.9, 'count',      'Nb/gravité de sanctions (AMF, etc.) sur 5 ans, percentile inversé.')
) as v(code, dim_code, name, kind, direction, sector_specific, sector_code, weight, unit, methodology)
join dimensions d on d.code = v.dim_code
left join sectors s on s.code = v.sector_code
on conflict (code) do nothing;
