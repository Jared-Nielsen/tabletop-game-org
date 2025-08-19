-- COMPLETE REMOVAL OF TIMER_SETTINGS
-- Run this ENTIRE script in Supabase SQL Editor: https://supabase.com/dashboard/project/kwpptrhywkyuzadwxgdl/editor

-- Step 1: Find and list all functions that reference timer_settings
DO $$
DECLARE
    func RECORD;
BEGIN
    RAISE NOTICE 'Finding functions that reference timer_settings...';
    FOR func IN 
        SELECT 
            p.proname AS function_name,
            n.nspname AS schema_name
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE pg_get_functiondef(p.oid) LIKE '%timer_settings%'
    LOOP
        RAISE NOTICE 'Found function: %.%', func.schema_name, func.function_name;
        -- Drop the function
        EXECUTE format('DROP FUNCTION IF EXISTS %I.%I CASCADE', func.schema_name, func.function_name);
        RAISE NOTICE '  -> Dropped function: %.%', func.schema_name, func.function_name;
    END LOOP;
END $$;

-- Step 2: Drop the timer_settings table if it exists
DROP TABLE IF EXISTS public.timer_settings CASCADE;
DROP TABLE IF EXISTS timer_settings CASCADE;

-- Step 3: Find ALL triggers on auth.users and list them
DO $$
DECLARE
    trig RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE 'Current triggers on auth.users:';
    FOR trig IN 
        SELECT 
            t.tgname AS trigger_name,
            p.proname AS function_name
        FROM pg_trigger t
        JOIN pg_proc p ON t.tgfoid = p.oid
        JOIN pg_class c ON t.tgrelid = c.oid
        JOIN pg_namespace cn ON c.relnamespace = cn.oid
        WHERE cn.nspname = 'auth' AND c.relname = 'users'
    LOOP
        RAISE NOTICE '  - Trigger: % -> Function: %', trig.trigger_name, trig.function_name;
    END LOOP;
END $$;

-- Step 4: Drop ALL existing triggers on auth.users to start fresh
DO $$
DECLARE
    trig RECORD;
BEGIN
    FOR trig IN 
        SELECT tgname 
        FROM pg_trigger t
        JOIN pg_class c ON t.tgrelid = c.oid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE n.nspname = 'auth' AND c.relname = 'users'
        AND tgname != 'on_auth_user_created' -- keep our good trigger
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS %I ON auth.users', trig.tgname);
        RAISE NOTICE 'Dropped trigger: %', trig.tgname;
    END LOOP;
END $$;

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

-- Step 6: Create ONLY the trigger we need
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Step 7: Verify cleanup
DO $$
DECLARE
    timer_count INTEGER;
    trigger_count INTEGER;
BEGIN
    -- Check for any remaining timer_settings references
    SELECT COUNT(*) INTO timer_count
    FROM pg_proc p
    WHERE pg_get_functiondef(p.oid) LIKE '%timer_settings%';
    
    -- Count triggers on auth.users
    SELECT COUNT(*) INTO trigger_count
    FROM pg_trigger t
    JOIN pg_class c ON t.tgrelid = c.oid
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE n.nspname = 'auth' AND c.relname = 'users';
    
    RAISE NOTICE '';
    RAISE NOTICE '========== CLEANUP COMPLETE ==========';
    RAISE NOTICE 'Timer settings references remaining: %', timer_count;
    RAISE NOTICE 'Triggers on auth.users: %', trigger_count;
    
    IF timer_count = 0 THEN
        RAISE NOTICE '✓ All timer_settings references removed!';
    ELSE
        RAISE WARNING '⚠ Still have % timer_settings references', timer_count;
    END IF;
    
    RAISE NOTICE '✓ Signup should now work properly!';
    RAISE NOTICE '======================================';
END $$;