CREATE INDEX packet_response_idx_response_ts
  ON packet_response
  USING btree
  (response_ts DESC NULLS LAST);
