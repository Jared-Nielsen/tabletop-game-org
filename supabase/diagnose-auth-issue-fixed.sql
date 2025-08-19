-- DIAGNOSTIC SCRIPT (FIXED) - Run this in Supabase SQL Editor
-- https://supabase.com/dashboard/project/kwpptrhywkyuzadwxgdl/editor

-- 1. Check if the profiles table exists and its structure
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Check if the trigger exists on auth.users
SELECT 
    tgname AS trigger_name,
    proname AS function_name,
    tgenabled AS enabled
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'auth' AND c.relname = 'users';

-- 3. Check RLS policies on profiles (simplified)
SELECT 
    polname AS policy_name,
    CASE polcmd 
        WHEN 'r' THEN 'SELECT'
        WHEN 'a' THEN 'INSERT'
        WHEN 'w' THEN 'UPDATE'
        WHEN 'd' THEN 'DELETE'
        WHEN '*' THEN 'ALL'
    END AS command
FROM pg_policy
WHERE polrelid = 'public.profiles'::regclass;

-- 4. Check if handle_new_user function exists
SELECT 
    proname AS function_name,
    prosrc AS function_source
FROM pg_proc
WHERE proname = 'handle_new_user'
LIMIT 1;

-- 5. Count users vs profiles
SELECT 
    (SELECT COUNT(*) FROM auth.users) as total_users,
    (SELECT COUNT(*) FROM public.profiles) as total_profiles,
    (SELECT COUNT(*) FROM auth.users WHERE id NOT IN (SELECT id FROM public.profiles)) as users_without_profiles;

-- 6. Check constraints on profiles table
SELECT
    conname AS constraint_name,
    CASE contype 
        WHEN 'p' THEN 'PRIMARY KEY'
        WHEN 'u' THEN 'UNIQUE'
        WHEN 'f' THEN 'FOREIGN KEY'
        WHEN 'c' THEN 'CHECK'
    END AS constraint_type
FROM pg_constraint c
JOIN pg_namespace n ON n.oid = c.connamespace
JOIN pg_class cl ON cl.oid = c.conrelid
WHERE n.nspname = 'public' 
AND cl.relname = 'profiles';

-- 7. Check if there are any recent auth errors in logs (last 10)
-- This might not work depending on your permissions, but worth trying
SELECT 'Check your Supabase Dashboard Logs for any auth errors' as note;