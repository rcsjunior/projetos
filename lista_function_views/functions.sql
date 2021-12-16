SELECT
	sc.nspname || '.' || fct.proname || '(' || COALESCE(pg_get_function_arguments(fct.oid),'') || ')' AS funcao,
	case fct.prokind
		WHEN 'f' then 'FUNCTION'
		WHEN 'p' then 'PROCEDURE'
		WHEN 'a' then 'AGGREGATE'
		WHEN 'w' then 'WINDOW'
	END AS kind,
	lan.lanname as language,
	tp.typname as return_type,
	CASE
		WHEN pg_get_functiondef(fct.oid) ILIKE '%LOOP%UPDATE%END LOOP%' THEN 'Alta'
		WHEN pg_get_functiondef(fct.oid) ILIKE '%LOOP%DELETE%END LOOP%' THEN 'Alta'
		WHEN pg_get_functiondef(fct.oid) ILIKE '%LOOP%INSERT%END LOOP%' THEN 'Alta'
		WHEN pg_get_functiondef(fct.oid) ILIKE '%LOOP%END LOOP%' THEN 'Media'
		ELSE 'Baixa'
	END AS complexidade
FROM pg_catalog.pg_proc fct
INNER JOIN pg_catalog.pg_namespace sc ON fct.pronamespace = sc.oid
LEFT JOIN pg_catalog.pg_language lan ON fct.prolang = lan.oid
LEFT JOIN pg_catalog.pg_type tp on fct.prorettype = tp.oid
WHERE sc.nspname <> 'information_schema'
AND sc.nspname NOT LIKE 'pg\_%'
--AND tp.typname <> 'trigger'
AND fct.proname NOT LIKE 'fsym%'
AND fct.proname NOT LIKE 'sym%'
AND lan.lanname <> 'internal'
ORDER BY
complexidade DESC,
sc.nspname,
fct.proname