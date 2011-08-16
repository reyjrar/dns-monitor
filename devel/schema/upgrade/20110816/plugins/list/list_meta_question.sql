CREATE TABLE list_meta_question
(
  list_entry_id integer NOT NULL,
  question_id bigint NOT NULL,
  CONSTRAINT list_meta_question_pkey PRIMARY KEY (question_id, list_entry_id),
  CONSTRAINT list_meta_question_fki_list_entry FOREIGN KEY (list_entry_id)
      REFERENCES list_entry (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT list_meta_question_fki_question FOREIGN KEY (question_id)
      REFERENCES packet_record_question (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE
)
WITH (
  OIDS=FALSE
);

CREATE INDEX list_meta_question_idx_list_entry
  ON list_meta_question
  USING btree
  (list_entry_id);
