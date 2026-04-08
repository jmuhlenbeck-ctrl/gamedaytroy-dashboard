-- =============================================
-- MARKETING SOURCES PERFORMANCE
-- Run this in Supabase SQL Editor
-- Populated by n8n Agent 16 (weekly Monday 8 AM + monthly 1st 8 AM)
-- Excludes SMS blast reactivations from "new lead" counts
-- =============================================

CREATE TABLE IF NOT EXISTS marketing_sources (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  location_slug TEXT NOT NULL DEFAULT 'troy',

  -- Period
  mode TEXT NOT NULL CHECK (mode IN ('weekly', 'monthly')),
  period_key DATE NOT NULL,            -- month: first of month; week: Monday of that week
  period_label TEXT,                   -- Human label e.g. 'Month 2026-03'

  -- Source/tag bucket
  tag TEXT NOT NULL,                   -- 'paradigm', 'google', 'outliant', 'TOTAL (new, excluding reactivations)', etc.

  -- Current period
  leads INT DEFAULT 0,
  wins INT DEFAULT 0,
  conversion_pct NUMERIC DEFAULT 0,

  -- Prior period (for delta display)
  prev_leads INT DEFAULT 0,
  prev_wins INT DEFAULT 0,
  prev_conversion_pct NUMERIC DEFAULT 0,

  -- Deltas
  delta_leads INT DEFAULT 0,
  delta_conversion_pp NUMERIC DEFAULT 0,

  -- Attribution diagnostics
  untagged_attribution INT DEFAULT 0,  -- contacts in this tag with no sessionSource
  top_source_1 TEXT,                   -- "sessionSource | utmSource (count)"
  top_source_2 TEXT,
  top_source_3 TEXT,

  -- Metadata
  generated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(location_slug, mode, period_key, tag)
);

-- Enable RLS
ALTER TABLE marketing_sources ENABLE ROW LEVEL SECURITY;

-- Permissive policies (matches existing dashboard pattern)
CREATE POLICY "Allow all marketing_sources" ON marketing_sources FOR ALL USING (true) WITH CHECK (true);

-- Indexes for fast dashboard queries
CREATE INDEX IF NOT EXISTS idx_marketing_sources_latest
  ON marketing_sources(location_slug, mode, period_key DESC);
CREATE INDEX IF NOT EXISTS idx_marketing_sources_tag
  ON marketing_sources(location_slug, mode, tag, period_key DESC);
