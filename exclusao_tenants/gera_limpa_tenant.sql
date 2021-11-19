CREATE OR REPLACE FUNCTION public.gera_limpa_tenant(
	_tenant bigint)
    RETURNS jsonb
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
    DECLARE
        _tabela RECORD;
        _espaco_liberado NUMERIC;
        _espaco_consumido_registro NUMERIC;
        _total_espaco_liberado NUMERIC = 0;
        _lista_tabelas JSONB;
    BEGIN
    
        FOR _tabela IN (SELECT ordem, esquema, tabela FROM public.tenant_tabelas_ordem ORDER BY ordem) LOOP
			
			--RAISE NOTICE '% - % - Avaliando tabela %.%.',_tabela.ordem, clock_timestamp(), _tabela.esquema, _tabela.tabela;
        
            _espaco_consumido_registro = (SELECT CASE WHEN reltuples::NUMERIC = 0 THEN 0 ELSE ROUND((pg_total_relation_size(c.oid)/reltuples::NUMERIC)::NUMERIC,0) END AS "espaco_consumido_registro"
											FROM pg_class c
											INNER JOIN pg_namespace n ON n.oid = c.relnamespace
											WHERE n.nspname = _tabela.esquema
											AND c.relname = _tabela.tabela);
    
            EXECUTE 'SELECT COUNT(1)*' || _espaco_consumido_registro || ' FROM ' || _tabela.esquema || '.' || _tabela.tabela || ' WHERE tenant = ' || _tenant  INTO _espaco_liberado;
    
            IF _espaco_liberado > 0 THEN
    
                    IF _lista_tabelas IS NULL THEN
    
                        _lista_tabelas := ('[{"ordem":' || _tabela.ordem || ',"tabela":"' || _tabela.esquema || '.' || _tabela.tabela || '","comando":"SELECT public.tenant_tabela_excluir((''' || _tabela.esquema || ''',''' || _tabela.tabela || ''',' || _tenant || ',))","espaco_a_liberar":' || _espaco_liberado || '}]')::jsonb;
    
                    ELSE
    
                        _lista_tabelas := _lista_tabelas || ('{"ordem":' || _tabela.ordem || ',"tabela":"' || _tabela.esquema || '.' || _tabela.tabela || '","comando":"SELECT public.tenant_tabela_excluir((''' || _tabela.esquema || ''',''' || _tabela.tabela || ''',' || _tenant || '))","espaco_a_liberar":' || _espaco_liberado || '}')::jsonb;
    
                    END IF;
                    
                    _total_espaco_liberado := _total_espaco_liberado + _espaco_liberado;
            END IF;
        
        END LOOP;
        
        _lista_tabelas := _lista_tabelas || ('{"total_espaco_liberado":' || _total_espaco_liberado || '}')::jsonb;
        
        RETURN _lista_tabelas;
    END
    
$BODY$;

ALTER FUNCTION public.gera_limpa_tenant(bigint)
    OWNER TO group_nasajon;