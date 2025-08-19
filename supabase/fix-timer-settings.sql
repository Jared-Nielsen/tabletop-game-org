-- FIX FOR TIMER_SETTINGS TABLE ERROR
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/kwpptrhywkyuzadwxgdl/editor

-- Step 1: Create the timer_settings table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.timer_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    work_duration INTEGER DEFAULT 25, -- minutes
    break_duration INTEGER DEFAULT 5, -- minutes
    long_break_duration INTEGER DEFAULT 15, -- minutes
    sessions_until_long_break INTEGER DEFAULT 4,
    auto_start_breaks BOOLEAN DEFAULT false,
    auto_start_work BOOLEAN DEFAULT false,
    sound_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Step 2: Create RLS policies for timer_settings
ALTER TABLE public.timer_settings ENABLE ROW LEVEL SECURITY;

-- Allow users to view their own timer settings
CREATE POLICY "Users can view own timer settings" ON public.timer_settings
    FOR SELECT
    USING (auth.uid() = user_id);

-- Allow users to insert their own timer settings
CREATE POLICY "Users can insert own timer settings" ON public.timer_settings
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Allow users to update their own timer settings
CREATE POLICY "Users can update own timer settings" ON public.timer_settings
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Allow users to delete their own timer settings
CREATE POLICY "Users can delete own timer settings" ON public.timer_settings
    FOR DELETE
    USING (auth.uid() = user_id);

-- Step 3: Update the handle_new_user function to NOT reference timer_settings
-- (or to handle it gracefully if needed)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Insert profile with minimal required data
    BEGIN
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
            email = COALESCE(EXCLUDED.email, profiles.email),
            updated_at = NOW();
    EXCEPTION 
        WHEN OTHERS THEN
            RAISE LOG 'Error creating profile for %: %', NEW.email, SQLERRM;
    END;
    
    -- Optionally create default timer settings (commented out if not needed)
    -- BEGIN
    --     INSERT INTO public.timer_settings (user_id)
    --     VALUES (NEW.id)
    --     ON CONFLICT (user_id) DO NOTHING;
    -- EXCEPTION 
    --     WHEN OTHERS THEN
    --         RAISE LOG 'Error creating timer settings for %: %', NEW.email, SQLERRM;
    -- END;
    
    RETURN NEW;
EXCEPTION 
    WHEN OTHERS THEN
        -- Log error but don't fail the signup
        RAISE LOG 'Error in handle_new_user for %: %', NEW.email, SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 4: Check if there's another function that might be referencing timer_settings
-- List all functions that might be called during signup
SELECT 
    p.proname AS function_name,
    n.nspname AS schema_name,
    pg_get_functiondef(p.oid) AS function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE pg_get_functiondef(p.oid) LIKE '%timer_settings%';

-- Step 5: Drop and recreate the auth trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Step 6: Grant permissions
GRANT ALL ON public.timer_settings TO authenticated;
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

-- Step 7: Verify the fix
SELECT 'Timer settings table created and auth trigger updated!' as status;