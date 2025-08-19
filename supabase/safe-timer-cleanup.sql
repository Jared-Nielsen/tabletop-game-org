-- SAFE TIMER_SETTINGS CLEANUP
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/kwpptrhywkyuzadwxgdl/editor

-- Step 1: Find ALL user-defined functions that might reference timer_settings
SELECT 
    n.nspname || '.' || p.proname AS function_full_name,
    p.proname AS function_name,
    n.nspname AS schema_name,
    CASE 
        WHEN p.prosrc LIKE '%timer_settings%' THEN 'REFERENCES TIMER_SETTINGS - MUST DROP!'
        ELSE 'Check if needed'
    END as status
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE (p.prosrc LIKE '%timer_settings%'
   OR p.proname LIKE '%timer%'
   OR p.proname LIKE '%handle_new_user%')
   AND n.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY status DESC;

-- Step 2: Drop specific functions safely
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS auth.handle_new_user() CASCADE;

-- Step 3: Drop ONLY user-defined triggers on auth.users (not constraint triggers)
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT tgname 
        FROM pg_trigger 
        WHERE tgrelid = 'auth.users'::regclass
        AND tgname NOT LIKE 'RI_ConstraintTrigger%'  -- Skip constraint triggers
        AND tgname NOT LIKE '%_pkey%'  -- Skip primary key triggers
        AND tgname NOT LIKE '%_fkey%'  -- Skip foreign key triggers
    LOOP
        EXECUTE 'DROP TRIGGER IF EXISTS ' || quote_ident(r.tgname) || ' ON auth.users';
        RAISE NOTICE 'Dropped user trigger: %', r.tgname;
    END LOOP;
END $$;

-- Step 4: Drop timer_settings table
DROP TABLE IF EXISTS public.timer_settings CASCADE;
DROP TABLE IF EXISTS auth.timer_settings CASCADE;

-- Step 5: Find the problematic function by checking ALL functions for timer_settings
SELECT 
    'DROP FUNCTION IF EXISTS ' || n.nspname || '.' || p.proname || '(' || 
    pg_get_function_identity_arguments(p.oid) || ') CASCADE;' as drop_command,
    n.nspname || '.' || p.proname as function_name
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.prosrc LIKE '%timer_settings%'
AND n.nspname NOT IN ('pg_catalog', 'information_schema');

-- Step 6: Create a CLEAN handle_new_user function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Only create profile, nothing else
    INSERT INTO public.profiles (id, email, role, created_at)
    VALUES (NEW.id, NEW.email, 'user', NOW())
    ON CONFLICT (id) DO UPDATE 
    SET email = EXCLUDED.email;
    
    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    RAISE LOG 'Profile creation failed: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- Step 7: Create our trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Step 8: List remaining user-defined triggers
SELECT 
    'User triggers on auth.users:' as info,
    tgname AS trigger_name,
    proname AS function_name
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE t.tgrelid = 'auth.users'::regclass
AND tgname NOT LIKE 'RI_ConstraintTrigger%'
AND tgname NOT LIKE '%_pkey%'
AND tgname NOT LIKE '%_fkey%';

-- Step 9: Final check for timer_settings references
SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ No timer_settings references found!'
        ELSE '⚠ STILL HAVE ' || COUNT(*) || ' functions with timer_settings - SEE STEP 5 OUTPUT ABOVE FOR DROP COMMANDS'
    END as final_status
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.prosrc LIKE '%timer_settings%'
AND n.nspname NOT IN ('pg_catalog', 'information_schema');