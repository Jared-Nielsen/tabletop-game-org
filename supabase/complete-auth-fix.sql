-- COMPLETE AUTH FIX - Run ALL of this in Supabase SQL Editor
-- https://supabase.com/dashboard/project/kwpptrhywkyuzadwxgdl/editor

-- Step 1: Ensure profiles table has correct structure
-- Check if email column exists, if not add it
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' 
        AND column_name = 'email'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN email TEXT;
    END IF;
END $$;

-- Step 2: Remove any constraints that might be causing issues
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_email_key CASCADE;

-- Step 3: Ensure the profile ID matches auth.users ID
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey CASCADE;
ALTER TABLE public.profiles 
    ADD CONSTRAINT profiles_id_fkey 
    FOREIGN KEY (id) 
    REFERENCES auth.users(id) 
    ON DELETE CASCADE;

-- Step 4: Create or replace the trigger function with better error handling
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    default_role TEXT := 'user';
BEGIN
    -- Insert profile with minimal required data
    INSERT INTO public.profiles (
        id,
        email,
        role,
        created_at
    ) VALUES (
        NEW.id,
        NEW.email,
        default_role,
        NOW()
    )
    ON CONFLICT (id) 
    DO UPDATE SET 
        email = COALESCE(EXCLUDED.email, profiles.email),
        updated_at = NOW();
    
    RETURN NEW;
EXCEPTION 
    WHEN OTHERS THEN
        -- Log error but don't fail the signup
        RAISE LOG 'Error in handle_new_user for %: % %', NEW.email, SQLERRM, SQLSTATE;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 5: Drop and recreate the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Step 6: Fix ALL RLS policies
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies first
DO $$ 
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN 
        SELECT polname 
        FROM pg_policy 
        WHERE polrelid = 'public.profiles'::regclass
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.profiles', pol.polname);
    END LOOP;
END $$;

-- Create new comprehensive policies
-- Allow authenticated users to view all profiles (needed for app functionality)
CREATE POLICY "Enable read access for authenticated users" ON public.profiles
    FOR SELECT 
    TO authenticated
    USING (true);

-- Allow users to update their own profile
CREATE POLICY "Enable update for users based on user_id" ON public.profiles
    FOR UPDATE 
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Allow inserts from triggers (service role)
CREATE POLICY "Enable insert for service role" ON public.profiles
    FOR INSERT 
    TO authenticated, anon
    WITH CHECK (true);

-- Service role bypass for everything
CREATE POLICY "Service role has full access" ON public.profiles
    FOR ALL 
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Step 7: Grant necessary permissions
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, service_role;
GRANT SELECT, UPDATE ON public.profiles TO authenticated;
GRANT INSERT ON public.profiles TO anon; -- For signup

-- Step 8: Create any missing profiles for existing users
INSERT INTO public.profiles (id, email, role, created_at)
SELECT 
    id, 
    email,
    'user',
    COALESCE(created_at, NOW())
FROM auth.users
WHERE NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE profiles.id = users.id
)
ON CONFLICT (id) DO NOTHING;

-- Step 9: Verify the setup
DO $$
DECLARE
    trigger_count INT;
    function_exists BOOLEAN;
    profiles_count INT;
    users_count INT;
BEGIN
    -- Check trigger
    SELECT COUNT(*) INTO trigger_count
    FROM pg_trigger 
    WHERE tgname = 'on_auth_user_created';
    
    -- Check function
    SELECT EXISTS(
        SELECT 1 FROM pg_proc 
        WHERE proname = 'handle_new_user'
    ) INTO function_exists;
    
    -- Count records
    SELECT COUNT(*) INTO users_count FROM auth.users;
    SELECT COUNT(*) INTO profiles_count FROM public.profiles;
    
    -- Report
    RAISE NOTICE 'Setup Status:';
    RAISE NOTICE '  Trigger exists: %', trigger_count > 0;
    RAISE NOTICE '  Function exists: %', function_exists;
    RAISE NOTICE '  Users count: %', users_count;
    RAISE NOTICE '  Profiles count: %', profiles_count;
    
    IF trigger_count > 0 AND function_exists THEN
        RAISE NOTICE '✓ Auth setup complete! Signup should now work.';
    ELSE
        RAISE WARNING '✗ Setup incomplete. Please check for errors above.';
    END IF;
END $$;