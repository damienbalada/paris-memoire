import { createClient } from "@supabase/supabase-js";

// Valeurs publiques par défaut. L'URL et la clé `anon` NE SONT PAS secrètes :
// elles sont conçues pour être exposées côté client, et la RLS garantit que
// seules les données publiées (evidence approuvée + tables de référence) sont
// lisibles. Les variables d'env, si présentes, ont la priorité.
const DEFAULT_URL = "https://wvqbvmjsqihqzmygrkwq.supabase.co";
const DEFAULT_ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2cWJ2bWpzcWlocXpteWdya3dxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI2NDU3NjUsImV4cCI6MjA5ODIyMTc2NX0.pQLmM3RTpESOafmK39LfQk_fDACGxPBzNkN3Bikuj3k";

export function getSupabase() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL || DEFAULT_URL;
  const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || DEFAULT_ANON_KEY;
  return createClient(url, key);
}
