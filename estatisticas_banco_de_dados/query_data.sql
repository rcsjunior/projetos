DO
$query_data$
BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'query_data') THEN
		
		CREATE TABLE query_data AS
		SELECT
			pr.rolname, pd.datname, pss.calls, pss.total_time, pss.min_time, pss.max_time, pss.mean_time, pss.stddev_time, pss.rows, pss.shared_blks_hit, pss.shared_blks_read,
			pss.shared_blks_dirtied, pss.shared_blks_written, pss.local_blks_hit, pss.local_blks_read, pss.local_blks_dirtied, pss.local_blks_written, pss.temp_blks_read,
			pss.temp_blks_written, pss.blk_read_time, pss.blk_write_time, pss.query, now() AS created_at
		FROM pg_stat_statements AS pss
		INNER JOIN pg_roles AS pr ON pss.userid = pr.oid
		INNER JOIN pg_database AS pd ON pss.dbid = pd.oid;
	
	ELSE
		
		INSERT INTO query_data
		SELECT
			pr.rolname, pd.datname, pss.calls, pss.total_time, pss.min_time, pss.max_time, pss.mean_time, pss.stddev_time, pss.rows, pss.shared_blks_hit, pss.shared_blks_read,
			pss.shared_blks_dirtied, pss.shared_blks_written, pss.local_blks_hit, pss.local_blks_read, pss.local_blks_dirtied, pss.local_blks_written, pss.temp_blks_read,
			pss.temp_blks_written, pss.blk_read_time, pss.blk_write_time, pss.query, now() AS created_at
		FROM pg_stat_statements AS pss
		INNER JOIN pg_roles AS pr ON pss.userid = pr.oid
		INNER JOIN pg_database AS pd ON pss.dbid = pd.oid;
	
	END IF;
	
	PERFORM pg_stat_statements_reset();
END
$query_data$;