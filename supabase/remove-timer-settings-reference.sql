-- REMOVE TIMER_SETTINGS REFERENCES
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/kwpptrhywkyuzadwxgdl/editor

-- Step 1: Find ALL functions that reference timer_settings
SELECT 
    p.proname AS function_name,
    n.nspname AS schema_name
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE pg_get_functiondef(p.oid) LIKE '%timer_settings%';

-- Step 2: Find ALL triggers on auth.users table
SELECT 
    t.tgname AS trigger_name,
    p.proname AS function_name,
    n.nspname AS function_schema
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON p.pronamespace = n.oid
JOIN pg_namespace cn ON c.relnamespace = cn.oid
WHERE cn.nspname = 'auth' AND c.relname = 'users';

-- Step 3: Drop any triggers/functions that reference timer_settings
-- (We'll need to see the output from above first)

-- Step 4: Create a CLEAN handle_new_user function for TabletopGame.org
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- ONLY create a profile - nothing else
    INSERT INTO public.profiles (
        id,
        email,
        role,
        created_at
    ) VALUES (
        NEW.id,
        NEW.email,
        'user',
        NOW()
    )
    ON CONFLICT (id) 
    DO UPDATE SET 
        email = COALESCE(EXCLUDED.email, profiles.email);
    
    RETURN NEW;
EXCEPTION 
    WHEN OTHERS THEN
        -- Log but don't fail
        RAISE LOG 'Profile creation error for %: %', NEW.email, SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 5: Recreate ONLY the trigger we need
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Step 6: List all remaining triggers to verify cleanup
SELECT 'Remaining triggers on auth.users:' as info;
SELECT 
    t.tgname AS trigger_name,
    p.proname AS function_name
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace cn ON c.relnamespace = cn.oid
WHERE cn.nspname = 'auth' AND c.relname = 'users'
ORDER BY t.tgname;