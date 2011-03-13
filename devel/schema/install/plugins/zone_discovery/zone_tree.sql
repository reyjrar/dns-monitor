-- BASE Function
CREATE OR REPLACE FUNCTION zone_tree(in_zone_id bigint, in_return_self boolean)
  RETURNS SETOF zone AS
$BODY$DECLARE
  r zone%ROWTYPE;
BEGIN
  IF in_return_self THEN
    RETURN QUERY SELECT * FROM zone WHERE id = in_zone_id;
  END IF;
  FOR r IN SELECT * FROM zone WHERE parent_id = in_zone_id
  LOOP
    RETURN NEXT r;
    RETURN QUERY SELECT * FROM zone_tree(r.id, FALSE);
  END LOOP;
  RETURN;
END;$BODY$
  LANGUAGE plpgsql STABLE
  COST 100
  ROWS 1000;

-- Alias by BIGINT
CREATE OR REPLACE FUNCTION zone_tree(in_zone_id bigint)
  RETURNS SETOF zone AS
$BODY$BEGIN
  RETURN QUERY SELECT * FROM zone_tree(zone_id, TRUE);
  RETURN;
END$BODY$
  LANGUAGE plpgsql STABLE
  COST 100
  ROWS 1000;

-- Alias by INTEGER
CREATE OR REPLACE FUNCTION zone_tree(in_zone_id integer)
  RETURNS SETOF zone AS
$BODY$BEGIN
  RETURN QUERY SELECT * FROM zone_tree( cast(area_id as bigint), TRUE);
  RETURN;
END$BODY$
  LANGUAGE plpgsql STABLE
  COST 100
  ROWS 1000;

-- Alias by zone name
CREATE OR REPLACE FUNCTION zone_tree(in_zone_name text)
  RETURNS SETOF zone AS
$BODY$DECLARE
	var_zone_id BIGINT;
BEGIN
	select into var_zone_id id from zone where name = in_zone_name;

	IF NOT FOUND THEN
		RAISE EXCEPTION 'zone_tree() Unknown zone: "%"', in_zone_name;
	END IF;

	RETURN QUERY SELECT * FROM zone_tree( var_zone_id, TRUE );

END$BODY$
  LANGUAGE plpgsql STABLE
  COST 100
  ROWS 1000;
