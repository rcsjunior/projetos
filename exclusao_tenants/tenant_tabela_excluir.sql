CREATE TYPE tp_tenant_tabela_excluir AS (
	esquema varchar,
	tabela varchar,
	tenant bigint
);

ALTER TYPE tp_tenant_tabela_excluir OWNER TO group_nasajon;

CREATE OR REPLACE FUNCTION tenant_tabela_excluir(a_objeto tp_tenant_tabela_excluir)
RETURNS VOID
LANGUAGE 'plpgsql'
AS $tenant_tabela_excluir$
DECLARE
	_trigger RECORD;
BEGIN

	CREATE TEMP TABLE triggers_ativas AS
	SELECT
		trg.tgname as gatilho
	FROM pg_trigger trg
	JOIN pg_class tbl ON trg.tgrelid = tbl.oid
	JOIN pg_namespace sc ON sc.oid = tbl.relnamespace
	WHERE sc.nspname = a_objeto.esquema
	AND tbl.relname = a_objeto.tabela
	AND trg.tgname NOT LIKE '%ConstraintTrigger%'
	AND trg.tgenabled = 'O'
	ORDER BY
		trg.tgname;
	
	FOR _trigger IN (SELECT gatilho FROM triggers_ativas) LOOP
	
		EXECUTE 'ALTER TABLE ' || a_objeto.esquema || '.' || a_objeto.tabela || ' DISABLE TRIGGER "' || _trigger.gatilho || '"';
	
	END LOOP;
	
	EXECUTE 'DELETE FROM ' || a_objeto.esquema || '.' || a_objeto.tabela || ' WHERE tenant = ' || a_objeto.tenant;
	
	FOR _trigger IN (SELECT gatilho FROM triggers_ativas) LOOP
	
		EXECUTE 'ALTER TABLE ' || a_objeto.esquema || '.' || a_objeto.tabela || ' ENABLE TRIGGER "' || _trigger.gatilho || '"';
	
	END LOOP;
	
	DROP TABLE triggers_ativas;

END;
$tenant_tabela_excluir$;

ALTER FUNCTION tenant_tabela_excluir(tp_tenant_tabela_excluir)
    OWNER TO group_nasajon;