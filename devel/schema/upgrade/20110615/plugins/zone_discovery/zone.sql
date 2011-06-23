-- Remove the zone_tree functions
DROP FUNCTION zone_tree(text);
DROP FUNCTION zone_tree(integer);
DROP FUNCTION zone_tree(bigint);
DROP FUNCTION zone_tree(bigint,boolean);

-- Delete the Data from the tables
TRUNCATE zone_question;
TRUNCATE zone_answer;
TRUNCATE zone;

-- Reset the Sequence ID
SELECT setval('zone_id_seq', 0, true);

-- Remove the parent_id columns
ALTER TABLE zone delete column parent_id;

-- Add new columns
ALTER TABLE zone add column path ltree;
ALTER TABLE zone add column reference_count BIGINT DEFAULT 0;
ALTER TABLE zone add column first_ts TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW();
ALTER TABLE zone add column last_ts TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW();
