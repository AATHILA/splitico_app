-- ==============================================================================
-- Supabase SQL Script: Completely Delete User Account & Related Data
-- ==============================================================================
-- Run this in your Supabase Dashboard:
-- 1. Go to your Supabase Project Dashboard
-- 2. Click "SQL Editor" in the left sidebar
-- 3. Click "New query"
-- 4. Paste this entire script and click "Run"
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.delete_user()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_user_id uuid;
BEGIN
  -- Get the current authenticated user's ID
  current_user_id := auth.uid();
  
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- 1. Delete user groups (casting to text works for both UUID and TEXT columns)
  DELETE FROM public.groups WHERE created_by::text = current_user_id::text;

  -- 2. Completely delete the user from Supabase Auth
  DELETE FROM auth.users WHERE id = current_user_id;
END;
$$;

-- Grant execution permission to authenticated users
GRANT EXECUTE ON FUNCTION public.delete_user() TO authenticated;
