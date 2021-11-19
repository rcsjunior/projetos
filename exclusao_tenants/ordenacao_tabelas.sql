CREATE OR REPLACE FUNCTION public.reordenar_tabela_sincronia()
RETURNS VOID
LANGUAGE 'plpgsql'
AS $reordenar_tabela_sincronia$
DECLARE
	ordenacao INTEGER;
BEGIN

	ordenacao = 0;
	
	CREATE TEMP TABLE temp_tabelas AS
	SELECT
		sc.nspname AS esquema,
		tb.relname AS tabela,
		scf.nspname AS fk_esquema,
		tbf.relname AS fk_tabela,
		attf.attname AS fk_coluna
	FROM pg_catalog.pg_namespace sc
	INNER JOIN pg_catalog.pg_class tb ON sc.oid = tb.relnamespace
	INNER JOIN pg_catalog.pg_attribute att ON tb.oid = att.attrelid AND att.attname = 'tenant'
	LEFT JOIN pg_catalog.pg_constraint cst ON tb.oid = cst.confrelid
	LEFT JOIN pg_catalog.pg_class tbf ON cst.conrelid = tbf.oid
	LEFT JOIN pg_catalog.pg_namespace scf ON tbf.relnamespace = scf.oid
	LEFT JOIN pg_catalog.pg_attribute attf ON tbf.oid = attf.attrelid AND attf.attname = 'tenant'
	WHERE tb.relkind = 'r'
	AND tb.relpersistence = 'p'
	AND sc.nspname || '.' || tb.relname <> 'ns.tenants'
	AND (cst.contype = 'f' OR cst.contype IS NULL)
	AND (scf.nspname || '.' || tbf.relname <> 'ns.tenants' OR scf.nspname || '.' || tbf.relname IS NULL)
	ORDER BY
		sc.nspname,
		tb.relname;
	
	UPDATE temp_tabelas
	SET fk_esquema = NULL, fk_tabela = NULL
	WHERE
		(esquema || '.' || tabela = fk_esquema || '.' || fk_tabela)
	OR
		(fk_tabela IS NOT NULL AND fk_coluna IS NULL)
	OR
		(fk_esquema || '.' || fk_tabela = 'ns.tenants');
		
	DELETE FROM temp_tabelas WHERE fk_tabela = NULL AND (esquema, tabela) IN (SELECT fk_esquema, fk_tabela FROM temp_tabelas WHERE fk_tabela IS NOT NULL);
	
	DROP TABLE IF EXISTS temp_tabelas_ordenadas;
	CREATE TEMP TABLE temp_tabelas_ordenadas (ordem integer, esquema varchar, tabela varchar);
	
	WHILE EXISTS(SELECT 1 FROM temp_tabelas LIMIT 1) AND (SELECT COUNT(1) FROM temp_tabelas) <> 4 LOOP
		
		ordenacao = ordenacao + 1;
		
		INSERT INTO temp_tabelas_ordenadas(esquema,tabela,ordem)
		SELECT DISTINCT ttp.esquema, ttp.tabela, ordenacao
		FROM temp_tabelas ttp
		WHERE ttp.fk_tabela IS NULL
		ORDER BY ttp.esquema, ttp.tabela;
		
		DELETE FROM temp_tabelas WHERE (esquema, tabela) IN (SELECT esquema, tabela FROM temp_tabelas_ordenadas);
		
		UPDATE temp_tabelas SET fk_esquema = NULL, fk_tabela = NULL WHERE (fk_esquema, fk_tabela) IN (SELECT esquema, tabela FROM temp_tabelas_ordenadas);
		
		DELETE FROM temp_tabelas WHERE fk_tabela = NULL AND (esquema, tabela) IN (SELECT fk_esquema, fk_tabela FROM temp_tabelas WHERE fk_tabela IS NOT NULL);
	
	END LOOP;
	
	TRUNCATE tenant_tabelas_ordem;
	
	INSERT INTO tenant_tabelas_ordem (ordem, esquema, tabela, nivel)
	SELECT ROW_NUMBER() OVER (ORDER BY ordem, esquema, tabela) AS ordem, esquema, tabela, ordem AS nivel
	FROM temp_tabelas_ordenadas;
	
	DROP TABLE temp_tabelas;
	
	DROP TABLE temp_tabelas_ordenadas;

END;
$reordenar_tabela_sincronia$;

ALTER FUNCTION reordenar_tabela_sincronia()
    OWNER TO group_nasajon;
