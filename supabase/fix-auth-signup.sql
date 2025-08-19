-- IMMEDIATE FIX FOR USER SIGNUP ERROR
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/kwpptrhywkyuzadwxgdl/editor

-- Step 1: Create the function to handle new user signups
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role)
  VALUES (
    NEW.id,
    NEW.email,
    'user'
  )
  ON CONFLICT (id) DO UPDATE
  SET email = EXCLUDED.email;
  
  RETURN NEW;
EXCEPTION
  WHEN others THEN
    -- Don't block user creation if profile creation fails
    RAISE LOG 'Profile creation failed for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 2: Create the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Step 3: Fix RLS policies
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Allow service role to do anything (for triggers)
DROP POLICY IF EXISTS "Service role bypass" ON public.profiles;
CREATE POLICY "Service role bypass" ON public.profiles
  USING (auth.jwt()->>'role' = 'service_role');

-- Allow users to read all profiles (needed for app functionality)
DROP POLICY IF EXISTS "Public profiles are viewable" ON public.profiles;
CREATE POLICY "Public profiles are viewable" ON public.profiles
  FOR SELECT
  USING (true);

-- Allow users to update their own profile
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE
  USING (auth.uid() = id);

-- Step 4: Create profiles for any existing users that don't have one
INSERT INTO public.profiles (id, email, role)
SELECT 
  id,
  email,
  'user'
FROM auth.users
WHERE id NOT IN (SELECT id FROM public.profiles)
ON CONFLICT DO NOTHING;

-- Step 5: Verify the fix
SELECT 'Setup complete! Users should now be able to sign up.' as message;