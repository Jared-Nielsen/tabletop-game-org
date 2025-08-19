-- COMPLETE REMOVAL OF TIMER_SETTINGS (FIXED)
-- Run this ENTIRE script in Supabase SQL Editor: https://supabase.com/dashboard/project/kwpptrhywkyuzadwxgdl/editor

-- Step 1: Find functions that reference timer_settings (without using problematic query)
SELECT 
    n.nspname AS schema_name,
    p.proname AS function_name,
    'DROP FUNCTION IF EXISTS ' || n.nspname || '.' || p.proname || ' CASCADE;' as drop_command
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE EXISTS (
    SELECT 1 
    FROM pg_proc p2 
    WHERE p2.oid = p.oid 
    AND p2.prosrc LIKE '%timer_settings%'
);

-- Step 2: Drop the timer_settings table if it exists
DROP TABLE IF EXISTS public.timer_settings CASCADE;

-- Step 3: List all triggers on auth.users
SELECT 
    'Trigger: ' || t.tgname || ' -> Function: ' || p.proname as trigger_info
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace cn ON c.relnamespace = cn.oid
WHERE cn.nspname = 'auth' AND c.relname = 'users';

-- Step 4: Drop suspicious triggers (manually drop any that aren't on_auth_user_created)
-- We'll see the list from step 3 first

-- Step 5: Create a CLEAN handle_new_user function (no timer_settings!)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Create profile for new user - NOTHING ELSE
    INSERT INTO public.profiles (
        id,
        email,
        role,
        created_at
    ) VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'role', 'user'),
        NOW()
    )
    ON CONFLICT (id) 
    DO UPDATE SET 
        email = EXCLUDED.email,
        updated_at = NOW();
    
    RETURN NEW;
EXCEPTION 
    WHEN OTHERS THEN
        -- Log error but allow signup to continue
        RAISE WARNING 'Profile creation issue for user %: %', NEW.id, SQLERRM;
        RETURN NEW;
END;
$$;

-- Step 6: Recreate ONLY the trigger we need
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Step 7: Final verification
SELECT 'CLEANUP STATUS:' as status;

-- Check for timer_settings references in functions
SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ No timer_settings references found in functions'
        ELSE '⚠ Found ' || COUNT(*) || ' functions with timer_settings references'
    END as function_check
FROM pg_proc p
WHERE p.prosrc LIKE '%timer_settings%';

-- Check table existence
SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ timer_settings table removed'
        ELSE '⚠ timer_settings table still exists'
    END as table_check
FROM information_schema.tables 
WHERE table_name = 'timer_settings';

-- List final triggers on auth.users
SELECT 
    '✓ Final trigger count on auth.users: ' || COUNT(*) as trigger_status
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace cn ON c.relnamespace = cn.oid
WHERE cn.nspname = 'auth' AND c.relname = 'users';

SELECT '✓ Signup should now work! Try creating a new account.' as message;