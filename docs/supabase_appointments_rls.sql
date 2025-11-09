-- Appointments Table RLS Policies with Double-Booking Prevention

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

-- 3. Allow patients to insert new appointments (with double-booking check)
CREATE POLICY "patient-can-insert-appointments"
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

-- 4. Allow doctors to update appointment status
CREATE POLICY "doctor-can-update-appointment-status"
ON appointments
FOR UPDATE
TO authenticated
USING (doctor_id = auth.uid())
WITH CHECK (
  doctor_id = auth.uid() AND
  -- Only allow status updates (not time changes)
  start_time = OLD.start_time AND
  end_time = OLD.end_time AND
  doctor_id = OLD.doctor_id AND
  patient_id = OLD.patient_id
);

-- 5. Allow patients to cancel their own appointments
CREATE POLICY "patient-can-cancel-own-appointments"
ON appointments
FOR UPDATE
TO authenticated
USING (
  patient_id = auth.uid() AND
  status = 'pending' AND
  -- Only allow status change to cancelled
  status = 'cancelled' AND
  start_time = OLD.start_time AND
  end_time = OLD.end_time AND
  doctor_id = OLD.doctor_id AND
  patient_id = OLD.patient_id
);

-- 6. Allow patients to delete their pending appointments
CREATE POLICY "patient-can-delete-pending-appointments"
ON appointments
FOR DELETE
TO authenticated
USING (
  patient_id = auth.uid() AND
  status = 'pending'
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_appointments_doctor_time ON appointments(doctor_id, start_time, end_time);
CREATE INDEX IF NOT EXISTS idx_appointments_patient_time ON appointments(patient_id, start_time, end_time);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status);
CREATE INDEX IF NOT EXISTS idx_appointments_doctor_status ON appointments(doctor_id, status);

-- Function to check if a time slot is available for a doctor
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

-- Function to check if patient has overlapping appointments
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