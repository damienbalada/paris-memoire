"""Vérifie la confiance graduée par tier (cf. REVIEW_MODEL.md).

Ce qui est publié SANS revue humaine est une décision sensible : ces tests
verrouillent la règle pour qu'un changement accidentel ne puisse pas ouvrir la
publication automatique à la presse ou au contributif.
"""
from paris_memoire.load import AUTO_PUBLISH_TIERS, review_status_for


def test_tiers_autorite_publies_automatiquement():
    # Sources structurées, ingérées par des connecteurs déterministes.
    assert review_status_for("regulatory") == "approved"
    assert review_status_for("audited_ngo") == "approved"


def test_presse_et_contributif_passent_en_revue():
    assert review_status_for("press") == "pending"
    assert review_status_for("crowd") == "pending"


def test_tier_inconnu_ou_absent_reste_prudent():
    # Défaut sûr : en cas de doute, revue humaine.
    assert review_status_for(None) == "pending"
    assert review_status_for("") == "pending"
    assert review_status_for("nouveau_tier_inconnu") == "pending"


def test_liste_auto_publication_est_bien_restreinte():
    # Garde-fou explicite : seuls ces deux tiers échappent à la revue.
    assert AUTO_PUBLISH_TIERS == {"regulatory", "audited_ngo"}
