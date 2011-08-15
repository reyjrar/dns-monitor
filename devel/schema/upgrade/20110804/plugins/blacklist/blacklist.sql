CREATE TABLE blacklist
(
  id serial NOT NULL,
  "name" character varying(80) NOT NULL,
  "type" character(15) NOT NULL DEFAULT 'malicious'::bpchar,
  can_refresh boolean NOT NULL DEFAULT false,
  refresh_url character varying(255),
  refresh_every interval DEFAULT '7 days'::interval,
  refresh_last_ts timestamp without time zone,
  CONSTRAINT blacklist_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
