-- Index for Packet Timing Queries
CREATE INDEX packet_query_idx_capture_time on packet_query USING btree ( capture_time DESC NULLS LAST )
