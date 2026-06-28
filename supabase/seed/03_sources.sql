-- =============================================================================
-- Seed 03 : sources et leur tier de fiabilité
-- tier regulatory  = obligation légale (poids plein)
-- tier audited_ngo = index/ONG audité (poids fort)
-- tier press       = presse / allégations (poids bridé, plafonné)
-- tier crowd       = contributif / militant non audité (poids bas)
-- =============================================================================

insert into sources (code, name, tier, publisher, url, description) values
  -- ENTITÉ (regulatory) ----------------------------------------------------
  ('INPI_SIRENE',     'INPI / SIRENE',                      'regulatory',  'INPI / INSEE',          'https://data.inpi.fr',                 'Registre national des entreprises (France).'),
  ('GLEIF',           'GLEIF (LEI)',                        'regulatory',  'GLEIF',                 'https://www.gleif.org',                'Legal Entity Identifier mondial.'),
  ('OPENCORPORATES',  'OpenCorporates',                     'audited_ngo', 'OpenCorporates',        'https://opencorporates.com',           'Base ouverte des structures juridiques et filiales.'),

  -- ENVIRONNEMENT ----------------------------------------------------------
  ('CSRD_ESRS',       'Rapports CSRD-ESRS',                 'regulatory',  'Émetteur (URD/CSRD)',   null,                                   'Reporting de durabilité obligatoire UE (ESRS).'),
  ('CDP',             'CDP (Carbon Disclosure Project)',    'audited_ngo', 'CDP',                   'https://www.cdp.net',                  'Notation climat A..D-.'),
  ('SBTI',            'Science Based Targets initiative',   'audited_ngo', 'SBTi',                  'https://sciencebasedtargets.org',      'Validation des objectifs de réduction.'),
  ('TEXTILE_EXCHANGE','Textile Exchange Material Change',   'audited_ngo', 'Textile Exchange',      'https://textileexchange.org',          'Material Change Index (matières durables).'),
  ('HIGG',            'Higg Index',                         'audited_ngo', 'Cascale (ex-SAC)',      'https://howtohigg.org',                'Évaluation environnementale produits/installations.'),

  -- TRAVAIL & RÉMUNÉRATION -------------------------------------------------
  ('DPEF',            'DPEF (volet social)',                'regulatory',  'Émetteur',              null,                                   'Déclaration de performance extra-financière (social).'),
  ('EGAPRO',          'Index Égapro',                       'regulatory',  'Ministère du Travail',  'https://egapro.travail.gouv.fr',       'Index égalité professionnelle F/H (France).'),
  ('PRUDHOMMES',      'Contentieux prud''homaux',           'regulatory',  'Ministère de la Justice', null,                                 'Données contentieux du travail.'),
  ('EU_PAY_TRANSP',   'Directive UE transparence salariale','regulatory',  'Union européenne',      null,                                   'Transparence salariale (applicable 2026+).'),

  -- CHAÎNE D''APPRO & DROITS HUMAINS ---------------------------------------
  ('VIGILANCE_PLAN',  'Plan de vigilance (loi FR 2017)',    'regulatory',  'Émetteur',              null,                                   'Plan de vigilance public (devoir de vigilance).'),
  ('FTI',             'Fashion Transparency Index',         'audited_ngo', 'Fashion Revolution',    'https://www.fashionrevolution.org',    'Indice de transparence de la mode (/250).'),
  ('KNOWTHECHAIN',    'KnowTheChain',                       'audited_ngo', 'KnowTheChain',          'https://knowthechain.org',             'Benchmark travail forcé dans les chaînes d''appro.'),
  ('FAIR_WEAR',       'Fair Wear Foundation',               'audited_ngo', 'Fair Wear Foundation',  'https://www.fairwear.org',             'Conditions de travail / salaire décent fournisseurs.'),
  ('BHRRC',           'Business & Human Rights Resource Centre', 'press',  'BHRRC',                 'https://www.business-humanrights.org', 'Allégations et controverses droits humains (à pondérer bas).'),

  -- BIEN-ÊTRE ANIMAL (non-humain) ------------------------------------------
  ('BBFAW',           'Business Benchmark on Farm Animal Welfare', 'audited_ngo', 'BBFAW',          'https://www.bbfaw.com',                'Benchmark bien-être des animaux d''élevage.'),
  ('FUR_FREE',        'Fur Free Retailer',                  'audited_ngo', 'Fur Free Alliance',     'https://furfreeretailer.com',          'Programme sans fourrure.'),
  ('LWG',             'Leather Working Group',              'audited_ngo', 'Leather Working Group', 'https://www.leatherworkinggroup.com',  'Certification environnementale et traçabilité des tanneries.'),
  ('TE_STANDARDS',    'Textile Exchange (RDS/RWS/RMS)',     'audited_ngo', 'Textile Exchange',      'https://textileexchange.org',          'Standards duvet (RDS), laine (RWS), mohair (RMS).'),
  ('PETA',            'PETA',                               'crowd',       'PETA',                  'https://www.peta.org',                 'Source militante non auditée (tier bas, plafonné).'),

  -- GÉOPOLITIQUE -----------------------------------------------------------
  ('HATVP',           'HATVP (lobbying France)',            'regulatory',  'HATVP',                 'https://www.hatvp.fr',                 'Répertoire des représentants d''intérêts (open data).'),
  ('EU_TRANSPARENCY', 'Registre transparence UE',           'regulatory',  'Union européenne',      'https://transparency-register.europa.eu', 'Registre de transparence de l''UE.'),
  ('YALE_RUSSIA',     'Liste Yale (Russie)',                'audited_ngo', 'Yale CELI',             'https://www.yalerussianbusinessretreat.org', 'Suivi retrait/maintien des entreprises en Russie.'),
  ('CNCCFP',          'CNCCFP (financement politique)',     'regulatory',  'CNCCFP',                'https://www.cnccfp.fr',                'Financement de la vie politique (France).'),

  -- FISCALITÉ --------------------------------------------------------------
  ('CBCR',            'Déclaration pays-par-pays (CbCR)',   'regulatory',  'Émetteur / DGFiP',      null,                                   'Country-by-Country Reporting.'),
  ('TAX_JUSTICE',     'Tax Justice Network',                'audited_ngo', 'Tax Justice Network',   'https://taxjustice.net',               'Analyse des juridictions à faible imposition.'),

  -- GOUVERNANCE ------------------------------------------------------------
  ('AMF',             'Documents AMF',                      'regulatory',  'AMF',                   'https://www.amf-france.org',           'Documents d''enregistrement universel, sanctions.'),

  -- DIVERS -----------------------------------------------------------------
  ('PRESS',           'Presse générale',                    'press',       'Divers',                null,                                   'Articles de presse (tier presse, pondéré bas).')
on conflict (code) do nothing;
