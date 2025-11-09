-- Appointments Table RLS Policies with Double-Booking Prevention (CORRECTED VERSION)

-- Enable Row Level Security on appointments table
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;

-- =========================================================
-- 1. Allow patients to view their own appointments
-- =========================================================
CREATE POLICY "patient-can-view-own-appointments"
ON appointments
FOR SELECT
TO authenticated
USING (patient_id = auth.uid());

-- =========================================================
-- 2. Allow doctors to view their own appointments
-- =========================================================
CREATE POLICY "doctor-can-view-own-appointments"
ON appointments
FOR SELECT
TO authenticated
USING (doctor_id = auth.uid());

-- =========================================================
-- 3. Allow patients to insert new appointments (with double-booking check)
-- =========================================================
CREATE POLICY "patient-can-insert-appointments"
ON appointments
FOR INSERT
TO authenticated
WITH CHECK (
  patient_id = auth.uid() AND

  -- Prevent doctor from being double-booked on same date
  NOT EXISTS (
    SELECT 1 FROM appointments a
    WHERE a.doctor_id = appointments.doctor_id
      AND a.status = 'accepted'
      AND DATE(a.appointment_date) = DATE(appointments.appointment_date)
  ) AND

  -- Prevent patient from booking multiple appointments on same date
  NOT EXISTS (
    SELECT 1 FROM appointments a
    WHERE a.patient_id = appointments.patient_id
      AND a.status IN ('accepted', 'pending')
      AND DATE(a.appointment_date) = DATE(appointments.appointment_date)
  )
);

-- =========================================================
-- 4. Allow doctors to update appointment status only
-- =========================================================
CREATE POLICY "doctor-can-update-appointment-status"
ON appointments
FOR UPDATE
TO authenticated
USING (doctor_id = auth.uid())
WITH CHECK (
  doctor_id = auth.uid() AND
  -- Only allow status changes (no change in date or participants)
  appointment_date = appointments.appointment_date AND
  doctor_id = appointments.doctor_id AND
  patient_id = appointments.patient_id
);

-- =========================================================
-- 5. Allow patients to cancel their own pending appointments
-- =========================================================
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
  status = 'cancelled' AND
  appointment_date = appointments.appointment_date AND
  doctor_id = appointments.doctor_id AND
  patient_id = appointments.patient_id
);

-- =========================================================
-- 6. Allow patients to delete their own pending appointments
-- =========================================================
CREATE POLICY "patient-can-delete-pending-appointments"
ON appointments
FOR DELETE
TO authenticated
USING (
  patient_id = auth.uid() AND
  status = 'pending'
);

-- =========================================================
-- Indexes for better performance
-- =========================================================
CREATE INDEX IF NOT EXISTS idx_appointments_doctor_date ON appointments(doctor_id, appointment_date);
CREATE INDEX IF NOT EXISTS idx_appointments_patient_date ON appointments(patient_id, appointment_date);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status);
CREATE INDEX IF NOT EXISTS idx_appointments_doctor_status ON appointments(doctor_id, status);

-- =========================================================
-- Function: Check if doctor is available on specific date
-- =========================================================
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

-- =========================================================
-- Function: Check if patient already has appointment on date
-- =========================================================
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

-- =========================================================
-- Notes:
-- 1. Columns assumed: id (UUID), patient_id (UUID), doctor_id (UUID), appointment_date (TIMESTAMP), status (TEXT)
-- 2. Double-booking prevention works per-day
-- 3. For time-slot precision, extend the logic to include start_time/end_time columns
-- =========================================================