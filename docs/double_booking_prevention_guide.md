# Double-Booking Prevention System

This guide explains the comprehensive double-booking prevention system implemented for the medical appointment application.

## Overview

The system prevents patients from booking appointments when:
1. A doctor already has an accepted appointment at the requested time
2. A patient already has an overlapping appointment (accepted or pending)

## Implementation Components

### 1. Database-Level Security (RLS Policies)

**File**: `docs/supabase_appointments_rls.sql`

The primary defense is implemented at the database level using Supabase Row Level Security (RLS) policies:

```sql
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
```

### 2. Client-Side Validation

**Files**:
- `lib/providers/appointment_provider.dart`
- `lib/views/appointments/new_appointment_screen.dart`

#### Enhanced Appointment Provider

The `AppointmentNotifier` class includes:

1. **isDoctorAvailable()**: Checks if a doctor is available at a specific time
2. **getDoctorAvailability()**: Fetches doctor's accepted appointments for a date range
3. **Enhanced createAppointment()**: Handles RLS policy violations with user-friendly messages

#### New Appointment Screen

The booking screen includes:

1. **Pre-booking validation**: Checks availability before attempting to create appointment
2. **Improved error messaging**: Provides clear feedback when time slots are unavailable
3. **Asynchronous availability checking**: Uses the provider methods for real-time validation

### 3. Error Handling

The system provides user-friendly error messages:

- **Time slot unavailable**: "This time slot is no longer available. The doctor may have another appointment scheduled. Please choose a different time."
- **Authorization issues**: "You are not authorized to book this appointment. Please ensure you are logged in and try again."

## How It Works

### Booking Flow

1. **User selects doctor and time**: Patient chooses a doctor and time slot
2. **Client-side validation**: App checks if doctor is available using cached appointments
3. **Attempt booking**: If available, app attempts to create the appointment
4. **Database validation**: RLS policy performs final validation
5. **Success or error**: 
   - Success: Appointment is created
   - Failure: User-friendly error message is displayed

### Time Slot Overlap Detection

The system detects overlapping appointments using three conditions:

1. **New appointment starts during existing appointment**
2. **New appointment ends during existing appointment**  
3. **New appointment completely contains existing appointment**

### Status-Based Filtering

Only appointments with status `'accepted'` are considered for doctor conflicts, ensuring pending appointments don't block new bookings.

## Benefits

1. **Race condition protection**: Database-level validation prevents concurrent booking attempts
2. **User experience**: Clear error messages guide users to available time slots
3. **Data integrity**: Prevents double-booking even if client-side validation fails
4. **Performance**: Client-side pre-validation reduces unnecessary database calls
5. **Flexibility**: Easy to modify time slot duration and overlap rules

## Usage Examples

### Checking Doctor Availability

```dart
final isAvailable = await ref.read(appointmentProvider.notifier)
    .isDoctorAvailable(doctorId, startTime, endTime);

if (!isAvailable) {
  // Show message to user
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('This time slot is no longer available...'),
    ),
  );
  return;
}
```

### Getting Doctor Schedule

```dart
final availability = await ref.read(appointmentProvider.notifier)
    .getDoctorAvailability(doctorId, startDate, endDate);

// Use this data to show unavailable time slots in UI
```

## Future Enhancements

1. **Real-time updates**: Use Supabase realtime to update availability instantly
2. **Time slot management**: Add configurable appointment durations
3. **Buffer time**: Add gaps between appointments
4. **Working hours**: Integrate with doctor working schedules
5. **Advanced scheduling**: Support recurring appointments and bulk scheduling