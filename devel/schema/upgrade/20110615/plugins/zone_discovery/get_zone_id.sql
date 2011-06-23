-- Drop the old get_zone_id
DROP FUNCTION get_zone_id(character varying);

-- Create the new function
CREATE OR REPLACE FUNCTION get_zone_id(in_zone_name character varying, in_zone_path character varying)
  RETURNS integer AS $$
DECLARE
	out_zone_id INTEGER;
	var_zone_name character varying;
	var_zone_path ltree;
BEGIN
	var_zone_name := lower( in_zone_name );
	var_zone_path := lower( in_zone_path );


	-- Check for this zone
	select into out_zone_id id from zone where name = var_zone_name;

	-- Immediate Return
	IF FOUND THEN
		RETURN out_zone_id;
	END IF;

	-- Create it if it doesn't exist
	INSERT INTO zone ( name, path ) values ( var_zone_name, var_zone_path );
	select into out_zone_id currval('zone_id_seq');

	RETURN out_zone_id;
END;
$$
  LANGUAGE plpgsql VOLATILE
  COST 100;

