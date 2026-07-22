"""Valide que chaque CSV d'exemple (examples/) est compris par son connecteur.

Double rôle : documentation exécutable du format attendu, et garde-fou — si un
connecteur change ses colonnes sans mettre à jour l'exemple, ce test casse.
Les données sont fictives (ExempleCorp / DemoGroup) : aucun fait réel.
"""
from pathlib import Path

from paris_memoire.connectors import (
    benchmarks,
    bffp,
    cdp,
    egapro,
    governance,
    investments,
    sbti,
    tax,
)

EXAMPLES = Path(__file__).resolve().parents[1] / "examples"


def test_example_cdp():
    recs = cdp.parse_csv(str(EXAMPLES / "cdp.csv"))
    assert len(recs) == 2
    assert recs[0].climate == ("A-", 0.88)
    assert recs[0].water == ("B", 0.75)


def test_example_sbti():
    recs = sbti.parse_csv(str(EXAMPLES / "sbti.csv"))
    assert len(recs) == 2
    assert recs[0].nature == "result"


def test_example_bffp():
    recs = bffp.parse_csv(str(EXAMPLES / "bffp.csv"))
    assert len(recs) == 2
    assert recs[0].severity == 0.90  # rang 1


def test_example_egapro():
    recs = egapro.parse_csv(str(EXAMPLES / "egapro.csv"))
    assert len(recs) == 1
    assert recs[0].note == 88.0


def test_example_benchmarks():
    assert len(benchmarks.parse_csv(str(EXAMPLES / "benchmarks_bbfaw.csv"), "bbfaw")) == 2
    assert len(benchmarks.parse_csv(str(EXAMPLES / "benchmarks_knowthechain.csv"), "knowthechain")) == 2
    assert len(benchmarks.parse_csv(str(EXAMPLES / "benchmarks_fti.csv"), "fti")) == 2


def test_example_tax():
    recs = tax.parse_csv(str(EXAMPLES / "tax.csv"))
    assert len(recs) == 2
    assert recs[0].cbcr_published is True
    assert recs[0].effective_rate == 17.4


def test_example_governance():
    recs = governance.parse_csv(str(EXAMPLES / "governance.csv"))
    assert len(recs) == 2
    assert recs[0].women_share == 0.46
    assert recs[1].women_share == 0.385  # décimale française "38,5"


def test_example_investments():
    recs = investments.parse_csv(str(EXAMPLES / "investments.csv"))
    assert len(recs) == 2
    assert recs[0].responsible_policy == ("signataire UN PRI", 1.0, "result")
    assert recs[0].fossil_financing == 55.0
