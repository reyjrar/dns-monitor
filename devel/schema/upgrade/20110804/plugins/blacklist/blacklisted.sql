CREATE TABLE blacklisted
(
  id serial NOT NULL,
  blacklist_id integer NOT NULL,
  "zone" character varying(255) NOT NULL,
  path ltree NOT NULL,
  blacklist_refreshed boolean NOT NULL DEFAULT false,
  first_ts timestamp without time zone NOT NULL DEFAULT now(),
  last_ts timestamp without time zone NOT NULL DEFAULT now(),
  CONSTRAINT blacklisted_pkey PRIMARY KEY (id),
  CONSTRAINT blacklisted_fki_blacklist FOREIGN KEY (blacklist_id)
      REFERENCES blacklist (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT blacklisted_uniq UNIQUE (zone, blacklist_id)
)
WITH (
  OIDS=FALSE
);

CREATE INDEX blacklisted_idx_path_btree on blacklisted using BTREE (path);
CREATE INDEX blacklisted_idx_path_gist on blacklisted using GIST (path);
