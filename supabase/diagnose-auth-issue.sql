-- DIAGNOSTIC SCRIPT - Run this in Supabase SQL Editor
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

-- 2. Check if the trigger exists
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE trigger_schema = 'public' 
AND event_object_table = 'users';

-- 3. Check for any triggers on auth.users
SELECT 
    tgname AS trigger_name,
    proname AS function_name
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE t.tgrelid = 'auth.users'::regclass;

-- 4. Check RLS policies on profiles
SELECT 
    polname AS policy_name,
    polcmd AS command,
    qual AS using_expression,
    with_check AS with_check_expression
FROM pg_policy
WHERE polrelid = 'public.profiles'::regclass;

-- 5. Check if handle_new_user function exists
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_schema = 'public' 
AND routine_name = 'handle_new_user';

-- 6. Check for any recent errors in auth schema
SELECT COUNT(*) as existing_users FROM auth.users;
SELECT COUNT(*) as existing_profiles FROM public.profiles;

-- 7. Check constraints on profiles table
SELECT
    conname AS constraint_name,
    contype AS constraint_type,
    pg_get_constraintdef(c.oid) AS definition
FROM pg_constraint c
JOIN pg_namespace n ON n.oid = c.connamespace
JOIN pg_class cl ON cl.oid = c.conrelid
WHERE n.nspname = 'public' 
AND cl.relname = 'profiles';