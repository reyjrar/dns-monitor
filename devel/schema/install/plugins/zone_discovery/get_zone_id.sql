CREATE OR REPLACE FUNCTION get_zone_id(in_zone_name character varying)
  RETURNS integer AS
$BODY$DECLARE
	out_zone_id INTEGER;
	var_zone_name character varying;
	var_parent_zone character varying;
	var_parent_zone_id INTEGER;
	var_first_dot INTEGER;
BEGIN
	var_zone_name := lower( in_zone_name );
	select into out_zone_id id from zone where name = var_zone_name;

	-- Immediate Return
	IF FOUND THEN
		RETURN out_zone_id;
	END IF;

	var_first_dot := STRPOS( var_zone_name, '.' );
	-- Check for TLD
	IF var_first_dot = 0 THEN
		INSERT INTO zone ( parent_id, name ) values ( 0, var_zone_name );
		select into out_zone_id currval('zone_id_seq');
	ELSE
		var_parent_zone := substr( var_zone_name, var_first_dot + 1 );
		var_parent_zone_id := get_zone_id( var_parent_zone );
		INSERT INTO zone ( parent_id, name ) values ( var_parent_zone_id, var_zone_name );
		select into out_zone_id currval('zone_id_seq');
	END IF;

	RETURN out_zone_id;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
