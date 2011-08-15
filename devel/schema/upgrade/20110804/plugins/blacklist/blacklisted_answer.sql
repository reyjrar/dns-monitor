CREATE TABLE blacklisted_answer
(
  blacklisted_id integer NOT NULL,
  answer_id bigint NOT NULL,
  CONSTRAINT blacklisted_answer_pkey PRIMARY KEY (answer_id, blacklisted_id),
  CONSTRAINT blacklisted_answer_fki_blacklisted FOREIGN KEY (blacklisted_id)
      REFERENCES blacklisted (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT blacklisted_answer_fki_answer FOREIGN KEY (answer_id)
      REFERENCES packet_record_answer (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE
)
WITH (
  OIDS=FALSE
);

CREATE INDEX blacklisted_answer_idx_blacklisted
  ON blacklisted_answer
  USING btree
  (blacklisted_id);
