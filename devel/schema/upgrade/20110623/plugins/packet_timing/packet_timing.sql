-- Timing table
CREATE TABLE packet_timing
(
  id bigserial NOT NULL,
  conversation_id bigint,
  query_id bigint,
  response_id bigint,
  question_id bigint NOT NULL,
  answer_id bigint NOT NULL,
  difference numeric(11,6) NOT NULL,
  CONSTRAINT packet_timing_pki PRIMARY KEY (id),
  CONSTRAINT packet_timing_fk_conversation FOREIGN KEY (conversation_id)
      REFERENCES conversation (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT packet_timing_fk_answer FOREIGN KEY (answer_id)
      REFERENCES packet_record_answer (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT packet_timing_fk_query FOREIGN KEY (query_id)
      REFERENCES packet_query (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT packet_timing_fk_question FOREIGN KEY (question_id)
      REFERENCES packet_record_question (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT packet_timing_fk_response FOREIGN KEY (response_id)
      REFERENCES packet_response (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE SET NULL
)
WITH (
  OIDS=FALSE
);

