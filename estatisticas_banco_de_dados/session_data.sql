DO
$session_data$
BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'session_data') THEN
		
		CREATE TABLE session_data AS
		SELECT datname, usename, client_addr, COUNT(1) AS sessions, now() AS created_at
		FROM pg_stat_activity
		WHERE datid IS NOT NULL
		GROUP BY datname, usename, client_addr;
	
	ELSE
		
		INSERT INTO session_data
		SELECT datname, usename, client_addr, COUNT(1) AS sessions, now() AS created_at
		FROM pg_stat_activity
		WHERE datid IS NOT NULL
		GROUP BY datname, usename, client_addr;
	
	END IF;

END
$session_data$;