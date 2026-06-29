import { createClient } from "@supabase/supabase-js";

// Client Supabase (clé anon). La RLS garantit que seules les données publiées
// (evidence approuvée + tables de référence) sont lisibles.
export function getSupabase() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !key) {
    throw new Error(
      "NEXT_PUBLIC_SUPABASE_URL et NEXT_PUBLIC_SUPABASE_ANON_KEY doivent être définis (voir .env.example).",
    );
  }
  return createClient(url, key);
}
