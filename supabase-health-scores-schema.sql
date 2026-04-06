-- Patient Visit History (populated by Clinical History bookmarklet from Lobbie)
CREATE TABLE IF NOT EXISTS patient_visit_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  location_slug TEXT NOT NULL DEFAULT 'troy',
  patient_id INT NOT NULL,
  patient_name TEXT NOT NULL,
  total_visits_90d INT DEFAULT 0,
  last_visit_date DATE,
  days_since_last_visit INT DEFAULT 999,
  no_shows_90d INT DEFAULT 0,
  cancellations_90d INT DEFAULT 0,
  primary_service TEXT DEFAULT 'unknown',
  all_services TEXT,
  visit_dates TEXT, -- comma-separated last 10 visit dates
  synced_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(location_slug, patient_id)
);

CREATE INDEX IF NOT EXISTS idx_pvh_patient ON patient_visit_history(location_slug, patient_id);
CREATE INDEX IF NOT EXISTS idx_pvh_days ON patient_visit_history(location_slug, days_since_last_visit);

ALTER TABLE patient_visit_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow anon all patient_visit_history" ON patient_visit_history FOR ALL USING (true) WITH CHECK (true);

-- Patient Health Scores (calculated by n8n Agent 12 v2)
CREATE TABLE IF NOT EXISTS patient_health_scores (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  location_slug TEXT NOT NULL DEFAULT 'troy',
  patient_id INT,
  ghl_contact_id TEXT,
  patient_name TEXT NOT NULL,
  health_score INT NOT NULL DEFAULT 0,       -- 0-100 (higher = more at risk)
  risk_level TEXT NOT NULL DEFAULT 'green',   -- green, yellow, orange, red
  -- Component scores
  visit_score INT DEFAULT 0,                 -- 0-40 points from visit patterns
  payment_score INT DEFAULT 0,               -- 0-35 points from payment signals
  engagement_score INT DEFAULT 0,            -- 0-15 points from engagement
  sentiment_score INT DEFAULT 0,             -- 0-10 points from sentiment/tags
  -- Key metrics
  days_since_last_visit INT,
  total_visits_90d INT,
  no_shows_90d INT,
  declined_payments INT DEFAULT 0,
  primary_service TEXT,
  -- Risk flags (comma-separated)
  risk_flags TEXT,
  -- Timestamps
  last_calculated TIMESTAMPTZ DEFAULT NOW(),
  score_change INT DEFAULT 0,                -- change from previous calculation
  previous_score INT DEFAULT 0,
  UNIQUE(location_slug, patient_name)
);

CREATE INDEX IF NOT EXISTS idx_phs_score ON patient_health_scores(location_slug, health_score DESC);
CREATE INDEX IF NOT EXISTS idx_phs_risk ON patient_health_scores(location_slug, risk_level);
CREATE INDEX IF NOT EXISTS idx_phs_ghl ON patient_health_scores(ghl_contact_id);

ALTER TABLE patient_health_scores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow anon all patient_health_scores" ON patient_health_scores FOR ALL USING (true) WITH CHECK (true);

-- Health Score History (for trend tracking)
CREATE TABLE IF NOT EXISTS health_score_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  location_slug TEXT NOT NULL DEFAULT 'troy',
  patient_name TEXT NOT NULL,
  health_score INT NOT NULL,
  risk_level TEXT NOT NULL,
  calculated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_hsh_patient ON health_score_history(location_slug, patient_name, calculated_at DESC);

ALTER TABLE health_score_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow anon all health_score_history" ON health_score_history FOR ALL USING (true) WITH CHECK (true);
