-- =============================================
-- LOBBIE APPOINTMENTS TABLE
-- Run this in Supabase SQL Editor
-- Stores appointment data synced from Lobbie
-- =============================================

CREATE TABLE IF NOT EXISTS appointments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  location_slug TEXT NOT NULL DEFAULT 'troy',
  date DATE NOT NULL,

  -- Lobbie appointment data
  appointment_id INT NOT NULL,
  patient_name TEXT,
  patient_first_name TEXT,
  patient_last_name TEXT,
  patient_id INT,
  appointment_type TEXT,
  appointment_type_id INT,
  service_category TEXT CHECK (service_category IN (
    'trt', 'glp1', 'peptides', 'pshot', 'gaineswave',
    'vitamin_shots', 'supplements', 'labs', 'consult', 'other'
  )),

  -- Scheduling details
  scheduler_config TEXT,
  scheduler_config_id INT,
  status INT DEFAULT 0,
  status_label TEXT,
  start_time TEXT,
  duration INT,
  practitioner_id INT,
  note TEXT,

  -- Sync metadata
  synced_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(location_slug, appointment_id)
);

-- Enable RLS
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all appointments" ON appointments FOR ALL USING (true) WITH CHECK (true);

-- Indexes
CREATE INDEX idx_appointments_date ON appointments(location_slug, date DESC);
CREATE INDEX idx_appointments_patient ON appointments(patient_name, date DESC);
CREATE INDEX idx_appointments_category ON appointments(service_category, date DESC);
