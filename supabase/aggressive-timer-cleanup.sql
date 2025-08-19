-- AGGRESSIVE TIMER_SETTINGS CLEANUP
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/kwpptrhywkyuzadwxgdl/editor

-- Step 1: Find ALL functions that might reference timer_settings
SELECT 
    n.nspname || '.' || p.proname AS function_full_name,
    p.proname AS function_name,
    n.nspname AS schema_name
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.prosrc LIKE '%timer_settings%'
   OR p.proname LIKE '%timer%'
   OR p.proname LIKE '%handle_new_user%';

-- Step 2: Drop ALL versions of handle_new_user function
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS auth.handle_new_user() CASCADE;

-- Step 3: Drop ALL triggers on auth.users table
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT tgname 
        FROM pg_trigger 
        WHERE tgrelid = 'auth.users'::regclass
    LOOP
        EXECUTE 'DROP TRIGGER IF EXISTS ' || quote_ident(r.tgname) || ' ON auth.users CASCADE';
        RAISE NOTICE 'Dropped trigger: %', r.tgname;
    END LOOP;
END $$;

-- Step 4: Search for timer_settings in ALL schemas
SELECT 
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_name LIKE '%timer%';

-- Step 5: Drop timer_settings from ALL schemas
DROP TABLE IF EXISTS public.timer_settings CASCADE;
DROP TABLE IF EXISTS auth.timer_settings CASCADE;
DROP TABLE IF EXISTS timer_settings CASCADE;

-- Step 6: Create a MINIMAL handle_new_user function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, role)
    VALUES (NEW.id, NEW.email, 'user')
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 7: Create ONLY our needed trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Step 8: Check what functions still exist
SELECT 'Functions that might still reference timer:' as check;
SELECT 
    n.nspname || '.' || p.proname AS function_name
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.prosrc LIKE '%timer%';

-- Step 9: Final verification
SELECT 'Triggers on auth.users after cleanup:' as status;
SELECT 
    tgname AS trigger_name,
    proname AS function_name
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE t.tgrelid = 'auth.users'::regclass;