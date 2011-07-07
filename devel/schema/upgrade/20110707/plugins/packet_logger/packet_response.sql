CREATE INDEX packet_response_idx_capture_time
  ON packet_response
  USING btree
  (capture_time DESC NULLS LAST);
