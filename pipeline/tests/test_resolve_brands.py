from paris_memoire.resolve_brands import resolve
from paris_memoire.connectors.openfoodfacts import map_sector, brands_from_products

ENTITIES = [
    {"slug": "danone", "name": "Danone", "is_brand": False, "aliases": []},
    {"slug": "nestle", "name": "Nestlé", "is_brand": False, "aliases": ["Nestle S.A."]},
    {"slug": "coca-cola", "name": "The Coca-Cola Company", "is_brand": False, "aliases": ["Coca-Cola"]},
    {"slug": "alpro", "name": "Alpro", "is_brand": True, "aliases": []},
]


def test_off_owner_match():
    r = resolve(brand_name="Activia", owner_raw="Danone", entities=ENTITIES)
    assert r.group_slug == "danone"
    assert r.method == "off_owner"
    assert r.confidence >= 0.8


def test_wikidata_fallback():
    r = resolve(brand_name="Alpro", owner_raw=None, entities=ENTITIES, wikidata_owner="Danone")
    assert r.group_slug == "danone"
    assert r.method == "wikidata"


def test_name_group_eponym():
    # « Nestlé » (via alias) éponyme du groupe
    r = resolve(brand_name="Nestle S.A.", owner_raw=None, entities=ENTITIES)
    assert r.group_slug == "nestle"
    assert r.method == "name_group"


def test_no_guess_when_unknown():
    r = resolve(brand_name="Marque Inconnue", owner_raw="Fabricant X", entities=ENTITIES)
    assert r.group_slug is None
    assert r.method == "none"
    assert r.confidence == 0.0


def test_owner_priority_over_name():
    # Un propriétaire explicite prime sur une éventuelle éponymie.
    r = resolve(brand_name="Coca-Cola", owner_raw="Danone", entities=ENTITIES)
    assert r.group_slug == "danone"
    assert r.method == "off_owner"


def test_map_sector():
    assert map_sector(["en:beverages", "en:sodas"]) == "beverages"
    assert map_sector(["en:pet-food"]) == "pet_care"
    assert map_sector(["en:snacks"]) == "food"   # défaut alimentaire
    assert map_sector([]) is None


def test_brands_from_products_aggregates():
    products = [
        {"brands_tags": ["danone"], "brands": "Danone", "brand_owner": "Danone",
         "categories_tags": ["en:dairies"], "countries_tags": ["en:france"]},
        {"brands_tags": ["danone"], "brands": "Danone", "brand_owner": "Danone",
         "categories_tags": ["en:yogurts"], "countries_tags": ["en:france"]},
        {"brands_tags": ["evian"], "brands": "Evian", "brand_owner": "Danone",
         "categories_tags": ["en:beverages", "en:waters"], "countries_tags": ["en:france"]},
    ]
    brands = brands_from_products(products)
    by_ref = {b.source_ref: b for b in brands}
    assert by_ref["danone"].product_count == 2
    assert by_ref["danone"].owner_raw == "Danone"
    assert by_ref["evian"].sector_guess == "beverages"
    assert brands[0].source_ref == "danone"  # trié par popularité
