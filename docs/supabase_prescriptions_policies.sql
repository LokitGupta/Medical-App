-- Enable Row Level Security on prescriptions table
ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;

-- Allow only authenticated users (patients) to SELECT their own prescriptions
CREATE POLICY "patient-can-select-own-prescriptions"
ON prescriptions
FOR SELECT
TO authenticated
USING (patient_id = auth.uid());

-- Allow only authenticated users (doctors) to INSERT prescriptions for patients
CREATE POLICY "doctor-can-insert-prescriptions"
ON prescriptions
FOR INSERT
TO authenticated
WITH CHECK (doctor_id = auth.uid());

-- Allow doctors to UPDATE only the prescriptions they created (e.g., attach file_url)
CREATE POLICY "doctor-can-update-own-prescriptions"
ON prescriptions
FOR UPDATE
TO authenticated
USING (doctor_id = auth.uid())
WITH CHECK (doctor_id = auth.uid());

-- Optional: if you want doctors to be able to view prescriptions they created, uncomment:
-- CREATE POLICY "doctor-can-select-own-prescriptions"
-- ON prescriptions
-- FOR SELECT
-- TO authenticated
-- USING (doctor_id = auth.uid());

-- NOTE: Ensure your auth schema has users matching patient_id/doctor_id fields,
-- and that your application writes correct IDs when creating prescriptions.
-- Simple patient-only prescriptions table and RLS
-- Run these statements in Supabase SQL editor

-- 1) Create table
create table if not exists patient_prescriptions (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null,
  patient_id uuid not null,
  doctor_id uuid not null,
  prescription text not null,
  created_at timestamp with time zone default now()
);

-- 2) Enable RLS
alter table patient_prescriptions enable row level security;

-- 3) Policies
-- Allow the authenticated patient to read only their prescriptions
create policy if not exists "patient can read own prescriptions"
  on patient_prescriptions for select
  using (
    auth.uid() = patient_id
  );

-- Allow the doctor to insert prescriptions they author
create policy if not exists "doctor can insert prescriptions for their patients"
  on patient_prescriptions for insert
  with check (
    exists (
      select 1 from appointments a
      where a.id = appointment_id
        and a.doctor_id = auth.uid()
    )
  );

-- Optional: allow the doctor to update prescriptions they authored
create policy if not exists "doctor can update prescriptions they authored"
  on patient_prescriptions for update
  using (
    doctor_id = auth.uid()
  ) with check (
    doctor_id = auth.uid()
  );

-- Indexes to improve fetches
create index if not exists idx_patient_prescriptions_patient on patient_prescriptions(patient_id);
create index if not exists idx_patient_prescriptions_appointment on patient_prescriptions(appointment_id);
create index if not exists idx_patient_prescriptions_doctor on patient_prescriptions(doctor_id);