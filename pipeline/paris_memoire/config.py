"""Configuration : variables d'environnement (voir .env.example)."""
from __future__ import annotations

import os

from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_SERVICE_ROLE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")


def require_supabase() -> None:
    """Vérifie que la config Supabase est présente (écriture en base)."""
    if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
        raise SystemExit(
            "SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY doivent être définis "
            "(voir pipeline/.env.example). La service_role est secrète : ne la committez jamais."
        )
