ALTER TABLE list_meta_question ADD COLUMN list_id INTEGER;

ALTER TABLE list_meta_question ADD CONSTRAINT list_meta_question_list FOREIGN KEY (list_id) REFERENCES list (id)
   ON UPDATE NO ACTION ON DELETE NO ACTION;

CREATE INDEX fki_list_meta_question_list_id ON list_meta_question(list_id);

