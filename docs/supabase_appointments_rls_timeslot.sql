-- Appointments Table RLS Policies with Time-Slot Double-Booking Prevention

-- Enable Row Level Security on appointments table
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;

-- Drop existing policies and functions to ensure a clean slate
DROP POLICY IF EXISTS "patient-can-view-own-appointments" ON appointments;
DROP POLICY IF EXISTS "doctor-can-view-own-appointments" ON appointments;
DROP POLICY IF EXISTS "patient-can-insert-appointments" ON appointments;
DROP POLICY IF EXISTS "doctor-can-update-appointment-status" ON appointments;
DROP POLICY IF EXISTS "patient-can-cancel-own-appointments" ON appointments;
DROP POLICY IF EXISTS "patient-can-delete-pending-appointments" ON appointments;
DROP FUNCTION IF EXISTS is_doctor_available_at_time(UUID, TIMESTAMPTZ);
DROP FUNCTION IF EXISTS has_patient_overlapping_appointment(UUID, TIMESTAMPTZ);

-- =========================================================
-- Function: Check if doctor is available at a specific time slot
-- Assumes a fixed 30-minute duration for appointments
-- =========================================================
CREATE OR REPLACE FUNCTION is_doctor_available_at_time(
  p_doctor_id UUID,
  p_appointment_timestamp TIMESTAMPTZ
) RETURNS BOOLEAN AS $$
DECLARE
  appointment_duration INTERVAL := '30 minutes';
BEGIN
  RETURN NOT EXISTS (
    SELECT 1 FROM public.appointments a
    WHERE a.doctor_id = p_doctor_id
      AND LOWER(a.status) IN ('accepted', 'pending')
      -- Check for overlapping time slots
      AND a.appointment_date < (p_appointment_timestamp + appointment_duration)
      AND p_appointment_timestamp < (a.appointment_date + appointment_duration)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- =========================================================
-- Function: Check if patient already has an overlapping appointment
-- Assumes a fixed 30-minute duration for appointments
-- =========================================================
CREATE OR REPLACE FUNCTION has_patient_overlapping_appointment(
  p_patient_id UUID,
  p_appointment_timestamp TIMESTAMPTZ
) RETURNS BOOLEAN AS $$
DECLARE
  appointment_duration INTERVAL := '30 minutes';
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.appointments a
    WHERE a.patient_id = p_patient_id
      AND LOWER(a.status) IN ('accepted', 'pending')
      -- Check for overlapping time slots
      AND a.appointment_date < (p_appointment_timestamp + appointment_duration)
      AND p_appointment_timestamp < (a.appointment_date + appointment_duration)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- =========================================================
-- Policies
-- =========================================================

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

-- 3. Allow patients to insert new appointments (with time-slot double-booking check)
CREATE POLICY "patient-can-insert-appointments"
ON appointments
FOR INSERT
TO authenticated
WITH CHECK (
  patient_id = auth.uid() AND
  is_doctor_available_at_time(doctor_id, appointment_date) AND
  NOT has_patient_overlapping_appointment(patient_id, appointment_date)
);

-- 4. Allow doctors to update appointment status only
CREATE POLICY "doctor-can-update-appointment-status"
ON appointments
FOR UPDATE
TO authenticated
USING (doctor_id = auth.uid())
WITH CHECK (
  doctor_id = auth.uid()
);

-- 5. Allow patients to cancel their own pending appointments
CREATE POLICY "patient-can-cancel-own-appointments"
ON appointments
FOR UPDATE
TO authenticated
USING (
  patient_id = auth.uid() AND
  LOWER(status) = 'pending'
)
WITH CHECK (
  patient_id = auth.uid() AND
  LOWER(status) = 'cancelled'
);

-- 6. Allow patients to delete their own pending appointments
CREATE POLICY "patient-can-delete-pending-appointments"
ON appointments
FOR DELETE
TO authenticated
USING (
  patient_id = auth.uid() AND
  LOWER(status) = 'pending'
);

-- =========================================================
-- Indexes for better performance
-- =========================================================
CREATE INDEX IF NOT EXISTS idx_appointments_doctor_date ON appointments(doctor_id, appointment_date);
CREATE INDEX IF NOT EXISTS idx_appointments_patient_date ON appointments(patient_id, appointment_date);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status);
CREATE INDEX IF NOT EXISTS idx_appointments_doctor_status ON appointments(doctor_id, status);

-- Prevent exact same-time double bookings at the database layer
CREATE UNIQUE INDEX IF NOT EXISTS uniq_appointments_doctor_timeslot_active
ON appointments(doctor_id, appointment_date)
WHERE LOWER(status) IN ('accepted','pending');

-- =========================================================
-- Notes:
-- 1. This policy assumes a fixed 30-minute appointment duration.
--    If your appointment durations vary, you will need to add an 'end_time' or 'duration' column to the table.
-- 2. Columns assumed: id (UUID), patient_id (UUID), doctor_id (UUID), appointment_date (TIMESTAMPTZ), status (TEXT)
-- =========================================================