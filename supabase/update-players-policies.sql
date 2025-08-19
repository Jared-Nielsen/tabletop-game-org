-- UPDATE PLAYERS TABLE POLICIES TO FIX 406 ERROR
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/kwpptrhywkyuzadwxgdl/editor

-- Step 1: Check current policies
SELECT 
    polname as policy_name,
    polcmd as command,
    (SELECT rolname FROM pg_roles WHERE oid = ANY(polroles)) as applies_to
FROM pg_policy 
WHERE polrelid = 'public.players'::regclass;

-- Step 2: Drop existing restrictive policies
DROP POLICY IF EXISTS "Allow users to create their own player profile" ON public.players;
DROP POLICY IF EXISTS "Allow users to read player profiles" ON public.players;
DROP POLICY IF EXISTS "Allow users to update their own player profile" ON public.players;

-- Step 3: Create more permissive policies that work with the app

-- IMPORTANT: Allow EVERYONE (including anon) to SELECT players
-- This is needed because the app queries players before full auth context is established
CREATE POLICY "Enable read access for everyone" ON public.players
    FOR SELECT
    USING (true);

-- Allow authenticated users to insert their own player record
CREATE POLICY "Users can insert their own player" ON public.players
    FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() = auth_id 
        OR auth.uid() IN (SELECT id FROM auth.users WHERE email = players.email)
    );

-- Allow authenticated users to update their own player record
CREATE POLICY "Users can update their own player" ON public.players
    FOR UPDATE
    TO authenticated
    USING (
        auth.uid() = auth_id 
        OR auth.uid() IN (SELECT id FROM auth.users WHERE email = players.email)
    )
    WITH CHECK (
        auth.uid() = auth_id 
        OR auth.uid() IN (SELECT id FROM auth.users WHERE email = players.email)
    );

-- Allow authenticated users to delete their own player record
CREATE POLICY "Users can delete their own player" ON public.players
    FOR DELETE
    TO authenticated
    USING (
        auth.uid() = auth_id 
        OR auth.uid() IN (SELECT id FROM auth.users WHERE email = players.email)
    );

-- Step 4: Grant proper permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT SELECT ON public.players TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.players TO authenticated;
GRANT ALL ON public.players TO service_role;

-- Step 5: Ensure anon role can execute necessary functions
GRANT EXECUTE ON FUNCTION auth.uid() TO anon;
GRANT EXECUTE ON FUNCTION auth.jwt() TO anon;

-- Step 6: Create any missing player records for existing users
INSERT INTO public.players (auth_id, email, alias, created_at)
SELECT 
    u.id as auth_id,
    u.email,
    COALESCE(u.raw_user_meta_data->>'username', u.email) as alias,
    NOW()
FROM auth.users u
WHERE NOT EXISTS (
    SELECT 1 FROM public.players p WHERE p.auth_id = u.id OR p.email = u.email
)
ON CONFLICT DO NOTHING;

-- Step 7: Verify the fix
SELECT 
    'Policy Check Complete' as status,
    COUNT(*) as policy_count,
    STRING_AGG(polname, ', ') as policies
FROM pg_policy 
WHERE polrelid = 'public.players'::regclass;

-- Step 8: Test that anon can select
SET ROLE anon;
SELECT COUNT(*) as anon_can_see_count FROM public.players;
RESET ROLE;

SELECT '✓ Policies updated! The 406 error should be fixed.' as message;