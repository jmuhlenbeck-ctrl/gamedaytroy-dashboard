-- =============================================
-- PATIENT TOUCHPOINT TRACKER
-- Run this in Supabase SQL Editor
-- Auto-populated from Lobbie appointment data
-- =============================================

-- Patient enrollment records
CREATE TABLE IF NOT EXISTS patient_tracker (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  location_slug TEXT NOT NULL DEFAULT 'troy',

  -- Patient identity
  patient_name TEXT NOT NULL,
  patient_first_name TEXT,
  patient_last_name TEXT,
  patient_id INT,                    -- Lobbie patient_id

  -- Treatment
  service_type TEXT NOT NULL CHECK (service_type IN ('trt', 'glp1')),
  start_date DATE NOT NULL,          -- First appointment date for this service
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'paused', 'completed', 'churned')),

  -- Auto-updated from appointments
  last_visit_date DATE,
  visit_count INT DEFAULT 1,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(location_slug, patient_id, service_type)
);

-- Scheduled touchpoints
CREATE TABLE IF NOT EXISTS patient_touchpoints (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  patient_id UUID NOT NULL REFERENCES patient_tracker(id) ON DELETE CASCADE,

  -- Touchpoint details
  touchpoint_key TEXT NOT NULL,      -- e.g. 'trt_checkin_week2', 'glp1_4week_1'
  touchpoint_name TEXT NOT NULL,     -- Display name: 'Check-in Call'
  purpose TEXT,                       -- 'Catch early dropout, address concerns'
  due_date DATE NOT NULL,

  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'skipped', 'overdue')),
  completed_at TIMESTAMPTZ,
  completed_by TEXT,
  notes TEXT,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(patient_id, touchpoint_key)
);

-- Enable RLS
ALTER TABLE patient_tracker ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_touchpoints ENABLE ROW LEVEL SECURITY;

-- Permissive policies (matches existing dashboard pattern)
CREATE POLICY "Allow all patient_tracker" ON patient_tracker FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all patient_touchpoints" ON patient_touchpoints FOR ALL USING (true) WITH CHECK (true);

-- Indexes
CREATE INDEX idx_patient_tracker_service ON patient_tracker(location_slug, service_type, status);
CREATE INDEX idx_patient_tracker_patient ON patient_tracker(patient_id);
CREATE INDEX idx_touchpoints_due ON patient_touchpoints(due_date, status);
CREATE INDEX idx_touchpoints_patient ON patient_touchpoints(patient_id, due_date);

-- Auto-update trigger
CREATE OR REPLACE FUNCTION update_patient_tracker_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_patient_tracker_updated_at
  BEFORE UPDATE ON patient_tracker
  FOR EACH ROW
  EXECUTE FUNCTION update_patient_tracker_updated_at();
