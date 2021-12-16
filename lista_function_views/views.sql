SELECT
    sc.nspname || '.' || tb.relname AS view_name,
    CASE tb.relkind
        WHEN 'v' THEN 'VIEW'
        WHEN 'm' THEN 'MATERIALIZED VIEW'
    END AS kind,
    COUNT(1) AS column_count,
    CASE
		WHEN pg_catalog.pg_get_viewdef(tb.oid, true) ILIKE '%JOIN%WHERE%' THEN 'Alta'
		WHEN pg_catalog.pg_get_viewdef(tb.oid, true) ILIKE '%JOIN%GROUP BY%' THEN 'Alta'
		WHEN pg_catalog.pg_get_viewdef(tb.oid, true) ILIKE '%ORDER BY%' THEN 'Alta'
		WHEN pg_catalog.pg_get_viewdef(tb.oid, true) ILIKE '%JOIN%' THEN 'Media'
		WHEN pg_catalog.pg_get_viewdef(tb.oid, true) ILIKE '%WHERE%' THEN 'Media'
		WHEN pg_catalog.pg_get_viewdef(tb.oid, true) ILIKE '%GROUP BY%' THEN 'Media'
		ELSE 'Baixa'
	END AS complexidade
FROM pg_catalog.pg_namespace sc
INNER JOIN pg_catalog.pg_class tb ON (sc.oid = tb.relnamespace)
INNER JOIN pg_catalog.pg_attribute att ON (tb.oid = att.attrelid AND att.attnum > 0 AND NOT att.attisdropped)
WHERE sc.nspname <> 'information_schema'
AND sc.nspname NOT LIKE 'pg\_%'
AND tb.relkind IN ('v','m')
GROUP BY
    sc.nspname,
    tb.relkind,
    tb.relname,
    tb.oid
ORDER BY
    sc.nspname,
    tb.relname;