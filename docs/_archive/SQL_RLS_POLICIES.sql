-- RLS policies for couples and profiles tables
-- Run this in Supabase Dashboard → SQL Editor
-- ARCHIVED: This file is kept for reference only.
-- For current RLS policies, see the Supabase dashboard or ARCHITECTURE.md

-- ============================================================
-- Couples table policies
CREATE POLICY "couples_insert" ON public.couples
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = partner_a_id);

CREATE POLICY "couples_select" ON public.couples
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "couples_update" ON public.couples
  FOR UPDATE TO authenticated
  USING (auth.uid() = partner_a_id OR auth.uid() = partner_b_id);

CREATE POLICY "couples_delete" ON public.couples
  FOR DELETE TO authenticated
  USING (auth.uid() = partner_a_id);

-- Profiles table policies
CREATE POLICY "profiles_insert" ON public.profiles
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_select" ON public.profiles
  FOR SELECT TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "profiles_update" ON public.profiles
  FOR UPDATE TO authenticated
  USING (auth.uid() = id);

-- ============================================================
-- Profiles table policies
-- ============================================================

CREATE POLICY "profiles_insert" ON public.profiles
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_select" ON public.profiles
  FOR SELECT TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "profiles_update" ON public.profiles
  FOR UPDATE TO authenticated
  USING (auth.uid() = id);
