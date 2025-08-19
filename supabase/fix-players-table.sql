-- FIX PLAYERS TABLE 406 ERROR
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/kwpptrhywkyuzadwxgdl/editor

-- Step 1: Check if players table exists
SELECT EXISTS (
    SELECT 1 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'players'
) as players_table_exists;

-- Step 2: Create players table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.players (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    alias TEXT,
    first_name TEXT,
    last_name TEXT,
    phone TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    zip TEXT,
    country TEXT DEFAULT 'USA',
    date_of_birth DATE,
    profile_image_url TEXT,
    bio TEXT,
    website TEXT,
    twitter_handle TEXT,
    facebook_url TEXT,
    instagram_handle TEXT,
    tiktok_handle TEXT,
    youtube_channel TEXT,
    twitch_channel TEXT,
    discord_username TEXT,
    steam_id TEXT,
    xbox_gamertag TEXT,
    playstation_id TEXT,
    nintendo_friend_code TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(auth_id),
    UNIQUE(email)
);

-- Step 3: Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_players_auth_id ON public.players(auth_id);
CREATE INDEX IF NOT EXISTS idx_players_email ON public.players(email);

-- Step 4: Enable RLS
ALTER TABLE public.players ENABLE ROW LEVEL SECURITY;

-- Step 5: Drop existing policies to start fresh
DROP POLICY IF EXISTS "Public players are viewable by everyone" ON public.players;
DROP POLICY IF EXISTS "Players can view all players" ON public.players;
DROP POLICY IF EXISTS "Players can update own player" ON public.players;
DROP POLICY IF EXISTS "Players can insert own player" ON public.players;
DROP POLICY IF EXISTS "Service role bypass" ON public.players;

-- Step 6: Create comprehensive RLS policies
-- Allow anyone to read players (needed for app functionality)
CREATE POLICY "Enable read access for all users" ON public.players
    FOR SELECT
    USING (true);

-- Allow authenticated users to insert their own player record
CREATE POLICY "Enable insert for authenticated users" ON public.players
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = auth_id);

-- Allow users to update their own player record
CREATE POLICY "Enable update for users based on auth_id" ON public.players
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = auth_id)
    WITH CHECK (auth.uid() = auth_id);

-- Allow users to delete their own player record
CREATE POLICY "Enable delete for users based on auth_id" ON public.players
    FOR DELETE
    TO authenticated
    USING (auth.uid() = auth_id);

-- Step 7: Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON public.players TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.players TO authenticated;

-- Step 8: Create players for existing users who don't have one
INSERT INTO public.players (auth_id, email, alias, created_at)
SELECT 
    u.id,
    u.email,
    COALESCE(p.username, u.email),
    NOW()
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
WHERE NOT EXISTS (
    SELECT 1 FROM public.players pl WHERE pl.auth_id = u.id
)
ON CONFLICT (auth_id) DO NOTHING;

-- Step 9: Update the handle_new_user function to also create a player record
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Create profile for new user
    INSERT INTO public.profiles (id, email, role, created_at)
    VALUES (NEW.id, NEW.email, 'user', NOW())
    ON CONFLICT (id) 
    DO UPDATE SET email = EXCLUDED.email;
    
    -- Create player record for new user
    INSERT INTO public.players (auth_id, email, alias, created_at)
    VALUES (NEW.id, NEW.email, NEW.email, NOW())
    ON CONFLICT (auth_id) 
    DO UPDATE SET email = EXCLUDED.email;
    
    RETURN NEW;
EXCEPTION 
    WHEN OTHERS THEN
        RAISE LOG 'Error in handle_new_user: %', SQLERRM;
        RETURN NEW;
END;
$$;

-- Step 10: Verify the setup
SELECT 
    'Players table check:' as status,
    COUNT(*) as total_players,
    COUNT(DISTINCT auth_id) as unique_users
FROM public.players;

SELECT 'Fix complete! The 406 error should be resolved.' as message;