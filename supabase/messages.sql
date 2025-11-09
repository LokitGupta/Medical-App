-- Create messages table for doctor-patient chat
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null,
  receiver_id uuid not null,
  message text not null,
  timestamp timestamptz not null default now(),
  constraint messages_sender_fk foreign key (sender_id) references public.users (id) on delete cascade,
  constraint messages_receiver_fk foreign key (receiver_id) references public.users (id) on delete cascade
);

-- Enable Row Level Security
alter table public.messages enable row level security;

-- Allow authenticated users to insert messages that they send
create policy messages_insert_self_sender on public.messages
  for insert
  to authenticated
  with check (auth.uid() = sender_id);

-- Allow users to read messages where they are sender or receiver
create policy messages_select_self_only on public.messages
  for select
  to authenticated
  using (auth.uid() = sender_id or auth.uid() = receiver_id);

-- Optional: Allow users to delete their own sent messages (not required)
create policy messages_delete_self_sender on public.messages
  for delete
  to authenticated
  using (auth.uid() = sender_id);

-- Helpful indexes
create index if not exists idx_messages_sender_receiver on public.messages (sender_id, receiver_id);
create index if not exists idx_messages_timestamp on public.messages (timestamp);