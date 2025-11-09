-- Diagnostic queries to check your appointments table schema
-- Run these queries in your Supabase SQL editor to understand your table structure

-- 1. Check the actual column names in appointments table
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'appointments' 
ORDER BY ordinal_position;

-- 2. Check what data is currently in the table
SELECT * FROM appointments LIMIT 5;

-- 3. Common column name variations for appointment scheduling systems:
--    - appointment_date (DATE or TIMESTAMP)
--    - start_time, end_time (TIMESTAMP)
--    - scheduled_at (TIMESTAMP)
--    - created_at (TIMESTAMP - usually for record creation)

-- 4. Based on your error "column a.start_time does not exist", 
--    your table likely uses one of these schemas:

-- SCHEMA OPTION A (Date-based only):
-- appointments (
--   id UUID,
--   patient_id UUID,
--   doctor_id UUID,
--   appointment_date DATE or TIMESTAMP,
--   status TEXT,
--   notes TEXT,
--   created_at TIMESTAMP
-- )

-- SCHEMA OPTION B (Time-based):
-- appointments (
--   id UUID,
--   patient_id UUID,
--   doctor_id UUID,
--   start_time TIMESTAMP,
--   end_time TIMESTAMP,
--   status TEXT,
--   notes TEXT,
--   created_at TIMESTAMP
-- )

-- 5. Once you know your schema, use the appropriate RLS policy:
--    - For date-based: Use the "date-based" policies
--    - For time-based: Use the "time-based" policies