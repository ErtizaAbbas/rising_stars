// Rising Stars staff portal — connection settings.
// Paste the two values from Supabase: Project Settings -> API.
// The "anon public" key is designed to be public; security comes from the
// Row Level Security rules in supabase/schema.sql. NEVER paste the
// "service_role" key here.
window.RS_CONFIG = {
  SUPABASE_URL: 'https://YOUR-PROJECT-ID.supabase.co',
  SUPABASE_ANON_KEY: 'YOUR-ANON-PUBLIC-KEY'
};
