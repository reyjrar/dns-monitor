CREATE TABLE blacklisted_question
(
  blacklisted_id integer NOT NULL,
  question_id bigint NOT NULL,
  CONSTRAINT blacklisted_question_pkey PRIMARY KEY (question_id, blacklisted_id),
  CONSTRAINT blacklisted_question_fki_blacklisted FOREIGN KEY (blacklisted_id)
      REFERENCES blacklisted (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT blacklisted_question_fki_question FOREIGN KEY (question_id)
      REFERENCES packet_record_question (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE
)
WITH (
  OIDS=FALSE
);

CREATE INDEX blacklisted_question_idx_blacklisted
  ON blacklisted_question
  USING btree
  (blacklisted_id);
