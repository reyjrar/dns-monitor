CREATE INDEX packet_timing_idx_query_id
  ON packet_timing
  USING btree
  (query_id NULLS LAST);

CREATE INDEX packet_timing_idx_response_id
  ON packet_timing
  USING btree
  (response_id NULLS LAST);

CREATE INDEX packet_timing_idx_conversation_id
  ON packet_timing
  USING btree
  (conversation_id NULLS LAST);
