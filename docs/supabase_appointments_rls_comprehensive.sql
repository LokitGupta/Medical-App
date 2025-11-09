-- Comprehensive Appointments Table RLS Policies with Double-Booking Prevention
-- This version handles both date-based and time-based booking systems

-- Enable Row Level Security on appointments table
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;

-- Basic RLS Policies for appointments

-- 1. Allow patients to view their own appointments
CREATE POLICY "patient-can-view-own-appointments"
ON appointments
FOR SELECT
TO authenticated
USING (patient_id = auth.uid());

-- 2. Allow doctors to view their own appointments
CREATE POLICY "doctor-can-view-own-appointments"
ON appointments
FOR SELECT
TO authenticated
USING (doctor_id = auth.uid());

-- 3. Time-based double-booking prevention (if your table has time columns)
-- This version assumes you have start_time and end_time columns
CREATE POLICY "patient-can-insert-appointments-time-based"
ON appointments
FOR INSERT
TO authenticated
WITH CHECK (
  patient_id = auth.uid() AND
  -- Double-booking prevention: Check if doctor has any accepted appointments in the same time slot
  NOT EXISTS (
    SELECT 1 FROM appointments a
    WHERE a.doctor_id = NEW.doctor_id
      AND a.status = 'accepted'
      AND (
        -- Check for overlapping time slots
        (a.start_time <= NEW.start_time AND a.end_time > NEW.start_time) OR
        (a.start_time < NEW.end_time AND a.end_time >= NEW.end_time) OR
        (a.start_time >= NEW.start_time AND a.end_time <= NEW.end_time)
      )
  ) AND
  -- Also prevent patient from booking overlapping appointments
  NOT EXISTS (
    SELECT 1 FROM appointments a
    WHERE a.patient_id = NEW.patient_id
      AND a.status IN ('accepted', 'pending')
      AND (
        -- Check for overlapping time slots
        (a.start_time <= NEW.start_time AND a.end_time > NEW.start_time) OR
        (a.start_time < NEW.end_time AND a.end_time >= NEW.end_time) OR
        (a.start_time >= NEW.start_time AND a.end_time <= NEW.end_time)
      )
  )
);

-- 4. Date-based double-booking prevention (if your table only has appointment_date)
-- Use this instead of the time-based policy if you don't have start_time/end_time columns
CREATE POLICY "patient-can-insert-appointments-date-based"
ON appointments
FOR INSERT
TO authenticated
WITH CHECK (
  patient_id = auth.uid() AND
  -- Double-booking prevention: Check if doctor has any accepted appointments on the same date
  NOT EXISTS (
    SELECT 1 FROM appointments a
    WHERE a.doctor_id = NEW.doctor_id
      AND a.status = 'accepted'
      AND DATE(a.appointment_date) = DATE(NEW.appointment_date)
  ) AND
  -- Also prevent patient from booking multiple appointments on same date
  NOT EXISTS (
    SELECT 1 FROM appointments a
    WHERE a.patient_id = NEW.patient_id
      AND a.status IN ('accepted', 'pending')
      AND DATE(a.appointment_date) = DATE(NEW.appointment_date)
  )
);

-- 5. Allow doctors to update appointment status
CREATE POLICY "doctor-can-update-appointment-status"
ON appointments
FOR UPDATE
TO authenticated
USING (doctor_id = auth.uid())
WITH CHECK (
  doctor_id = auth.uid() AND
  -- Only allow status updates (not time/date changes)
  appointment_date = OLD.appointment_date AND
  doctor_id = OLD.doctor_id AND
  patient_id = OLD.patient_id
);

-- 6. Allow patients to cancel their own appointments
CREATE POLICY "patient-can-cancel-own-appointments"
ON appointments
FOR UPDATE
TO authenticated
USING (
  patient_id = auth.uid() AND
  status = 'pending'
)
WITH CHECK (
  patient_id = auth.uid() AND
  -- Only allow status change to cancelled
  status = 'cancelled' AND
  appointment_date = OLD.appointment_date AND
  doctor_id = OLD.doctor_id AND
  patient_id = OLD.patient_id
);

-- 7. Allow patients to delete their pending appointments
CREATE POLICY "patient-can-delete-pending-appointments"
ON appointments
FOR DELETE
TO authenticated
USING (
  patient_id = auth.uid() AND
  status = 'pending'
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_appointments_doctor_date ON appointments(doctor_id, appointment_date);
CREATE INDEX IF NOT EXISTS idx_appointments_patient_date ON appointments(patient_id, appointment_date);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status);
CREATE INDEX IF NOT EXISTS idx_appointments_doctor_status ON appointments(doctor_id, status);

-- Additional indexes for time-based queries (if you have time columns)
CREATE INDEX IF NOT EXISTS idx_appointments_doctor_time ON appointments(doctor_id, start_time, end_time);
CREATE INDEX IF NOT EXISTS idx_appointments_patient_time ON appointments(patient_id, start_time, end_time);

-- Function to check if a time slot is available for a doctor (time-based)
CREATE OR REPLACE FUNCTION is_time_slot_available(
  p_doctor_id UUID,
  p_start_time TIMESTAMP WITH TIME ZONE,
  p_end_time TIMESTAMP WITH TIME ZONE,
  p_exclude_appointment_id UUID DEFAULT NULL
) RETURNS BOOLEAN AS $$
BEGIN
  RETURN NOT EXISTS (
    SELECT 1 FROM appointments a
    WHERE a.doctor_id = p_doctor_id
      AND a.status = 'accepted'
      AND a.id != COALESCE(p_exclude_appointment_id, '00000000-0000-0000-0000-000000000000'::UUID)
      AND (
        -- Check for overlapping time slots
        (a.start_time <= p_start_time AND a.end_time > p_start_time) OR
        (a.start_time < p_end_time AND a.end_time >= p_end_time) OR
        (a.start_time >= p_start_time AND a.end_time <= p_end_time)
      )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if doctor is available on specific date (date-based)
CREATE OR REPLACE FUNCTION is_doctor_available_on_date(
  p_doctor_id UUID,
  p_appointment_date DATE,
  p_exclude_appointment_id UUID DEFAULT NULL
) RETURNS BOOLEAN AS $$
BEGIN
  RETURN NOT EXISTS (
    SELECT 1 FROM appointments a
    WHERE a.doctor_id = p_doctor_id
      AND a.status = 'accepted'
      AND DATE(a.appointment_date) = p_appointment_date
      AND a.id != COALESCE(p_exclude_appointment_id, '00000000-0000-0000-0000-000000000000'::UUID)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if patient has overlapping appointments (time-based)
CREATE OR REPLACE FUNCTION has_patient_overlapping_appointments(
  p_patient_id UUID,
  p_start_time TIMESTAMP WITH TIME ZONE,
  p_end_time TIMESTAMP WITH TIME ZONE,
  p_exclude_appointment_id UUID DEFAULT NULL
) RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM appointments a
    WHERE a.patient_id = p_patient_id
      AND a.status IN ('accepted', 'pending')
      AND a.id != COALESCE(p_exclude_appointment_id, '00000000-0000-0000-0000-000000000000'::UUID)
      AND (
        -- Check for overlapping time slots
        (a.start_time <= p_start_time AND a.end_time > p_start_time) OR
        (a.start_time < p_end_time AND a.end_time >= p_end_time) OR
        (a.start_time >= p_start_time AND a.end_time <= p_end_time)
      )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if patient has appointment on specific date (date-based)
CREATE OR REPLACE FUNCTION has_patient_appointment_on_date(
  p_patient_id UUID,
  p_appointment_date DATE,
  p_exclude_appointment_id UUID DEFAULT NULL
) RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM appointments a
    WHERE a.patient_id = p_patient_id
      AND a.status IN ('accepted', 'pending')
      AND DATE(a.appointment_date) = p_appointment_date
      AND a.id != COALESCE(p_exclude_appointment_id, '00000000-0000-0000-0000-000000000000'::UUID)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- IMPORTANT: Choose the right policy based on your database schema!
-- 
-- IF YOUR TABLE HAS start_time AND end_time COLUMNS:
-- Use: "patient-can-insert-appointments-time-based" policy
-- 
-- IF YOUR TABLE ONLY HAS appointment_date COLUMN:
-- Use: "patient-can-insert-appointments-date-based" policy
-- 
-- DROP THE POLICY YOU DON'T NEED:
-- DROP POLICY "patient-can-insert-appointments-time-based" ON appointments;
-- OR
-- DROP POLICY "patient-can-insert-appointments-date-based" ON appointments;