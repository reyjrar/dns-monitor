CREATE TABLE "zone"
(
  id bigserial NOT NULL,
  parent_id bigint NOT NULL DEFAULT 0,
  "name" character varying(255) NOT NULL,
  CONSTRAINT zone_pki_id PRIMARY KEY (id),
  CONSTRAINT zone_uniq_name UNIQUE (name)
)
WITH (
  OIDS=FALSE
);

CREATE INDEX zone_idx_cluster_parent
  ON "zone"
  USING btree
  (parent_id);
