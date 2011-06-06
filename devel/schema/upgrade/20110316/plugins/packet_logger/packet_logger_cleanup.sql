CREATE OR REPLACE FUNCTION packet_logger_cleanup(text)
  RETURNS integer AS
$BODY$DECLARE
	in_interval INTERVAL = CAST($1 as INTERVAL);
	rows_deleted_query INTEGER;
	rows_deleted_response INTEGER;

BEGIN

	DELETE from packet_query where query_ts < NOW() - in_interval;
	GET DIAGNOSTICS rows_deleted_query := ROW_COUNT;

	DELETE from packet_response where response_ts < NOW() - in_interval;
	GET DIAGNOSTICS rows_deleted_response := ROW_COUNT;

	RETURN rows_deleted_query + rows_deleted_response;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
