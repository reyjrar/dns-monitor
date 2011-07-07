-- Timing
ALTER TABLE packet_response add column capture_time NUMERIC(16,6);

-- Fix OpCode/Status
ALTER TABLE packet_response alter column opcode TYPE character varying (12);
ALTER TABLE packet_response alter column status TYPE character varying (20);
