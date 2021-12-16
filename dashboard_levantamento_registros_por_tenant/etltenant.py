from dadosconexao import RecuperaDadosConexao
from conexao import ConexaoPostgreSQL
from datetime import datetime
import argparse

parser=argparse.ArgumentParser()
parser.add_argument("--env", "-e", help='Ambiente: prod - produção | qa - testes | dev - desenvolvimento')
args = parser.parse_args()

ENV = args.env
SECTION_WEB = "web_"+ENV
SECTION_ESTATISTICA = "estatistica_"+ENV
TABELAS_QUERY = """
WITH tabelas_tenant AS (
    SELECT DISTINCT
        sc.nspname AS esquema,
        tb.relname AS tabela,
        CASE
            WHEN tb.reltuples::NUMERIC = 0 THEN 0
            ELSE ROUND((pg_total_relation_size(tb.oid)/tb.reltuples::NUMERIC)::NUMERIC,0)
        END AS "espaco_consumido_registro"
    FROM pg_catalog.pg_namespace sc
    INNER JOIN pg_catalog.pg_class tb ON sc.oid = tb.relnamespace
    INNER JOIN pg_catalog.pg_attribute att ON tb.oid = att.attrelid AND att.attname = 'tenant'
    WHERE tb.relkind = 'r'
    AND tb.relpersistence = 'p'
    AND sc.nspname || '.' || tb.relname <> 'ns.tenants'
	AND sc.nspname <> 'public'
)
SELECT esquema, tabela, espaco_consumido_registro, 1 AS tem_tenant
FROM tabelas_tenant

UNION

SELECT DISTINCT
    sc.nspname AS esquema,
    tb.relname AS tabela,
        CASE
            WHEN tb.reltuples::NUMERIC = 0 THEN 0
            ELSE ROUND((pg_total_relation_size(tb.oid)/tb.reltuples::NUMERIC)::NUMERIC,0)
        END AS "espaco_consumido_registro",
    0 AS tem_tenant
FROM pg_catalog.pg_namespace sc
INNER JOIN pg_catalog.pg_class tb ON sc.oid = tb.relnamespace
WHERE tb.relkind = 'r'
AND tb.relpersistence = 'p'
AND sc.nspname || '.' || tb.relname <> 'ns.tenants'
AND (sc.nspname, tb.relname) NOT IN (SELECT esquema, tabela FROM tabelas_tenant)
AND sc.nspname NOT LIKE 'pg\_%%'
AND sc.nspname NOT IN ('information_schema','public');
"""

class ETLTenants:

    def __init__(self):
        self._extracao = []

    def extract_transform(self):
        try:
            conexao = ConexaoPostgreSQL(RecuperaDadosConexao(SECTION_WEB,"Extração de Metricas por Tenant").parametros())
            tabelas = conexao.execucao_query(TABELAS_QUERY)
            for tabela in tabelas:
                resultado = conexao.execucao_query("SELECT tenant, COUNT(1) AS quantidade FROM " + tabela[0] + "." + tabela[1] + " GROUP BY tenant;") if tabela[3] else conexao.execucao_query("SELECT COUNT(1) AS quantidade FROM " + tabela[0] + "." + tabela[1] + ";")
                if tabela[3]:
                    for item in resultado:
                        if item[1] != 0:
                            extracao = {}
                            extracao["esquema"] = tabela[0]
                            extracao["tabela"] = tabela[1]
                            extracao["tenant"] = item[0]
                            extracao["quantidade"] = item[1]
                            extracao["espaco_ocupado"] = int(item[1]*tabela[2])
                            self._extracao.append(extracao)
                else:
                    if resultado != []:
                        if resultado[0][0] != 0:
                            extracao = {}
                            extracao["esquema"] = tabela[0]
                            extracao["tabela"] = tabela[1]
                            extracao["quantidade"] = resultado[0][0]
                            extracao["espaco_ocupado"] = int(resultado[0][0] * tabela[2])
                            self._extracao.append(extracao)
            conexao.encerra_conexao()
        except:
            conexao.encerra_conexao()
    
    def load(self):
        try:
            conexao = ConexaoPostgreSQL(RecuperaDadosConexao(SECTION_ESTATISTICA,"Load de Metricas por Tenant").parametros())

            sem_tenant = ''
            com_tenant = ''
            process_datetime = datetime.now()

            for item in self._extracao:
                if item.get("tenant", 0) != 0:
                    if com_tenant == '':
                        com_tenant = "INSERT INTO dadostabelastenants (esquema,tabela,tenant,numeroregistros,espacoocupado,created_at) VALUES ('{}','{}',{},{},{},'{}')".format(item.get("esquema"),item.get("tabela"),item.get("tenant"),item.get("quantidade"),item.get("espaco_ocupado"),process_datetime)
                    else:
                        com_tenant = com_tenant + ", ('{}','{}',{},{},{},'{}')".format(item.get("esquema"),item.get("tabela"),item.get("tenant") if item.get("tenant") != None else "NULL",item.get("quantidade"),item.get("espaco_ocupado"),process_datetime)
                else:
                    if sem_tenant == '':
                        sem_tenant = "INSERT INTO dadostabelassemtenants (esquema,tabela,numeroregistros,espacoocupado,created_at) VALUES ('{}','{}',{},{},'{}')".format(item.get("esquema"),item.get("tabela"),item.get("quantidade"),item.get("espaco_ocupado"),process_datetime)
                    else:
                        sem_tenant = sem_tenant + ", ('{}','{}',{},{},'{}')".format(item.get("esquema"),item.get("tabela"),item.get("quantidade"),item.get("espaco_ocupado"),process_datetime)
            
            conexao.execucao_query_sem_retorno(com_tenant) if com_tenant != '' else None
            conexao.execucao_query_sem_retorno(sem_tenant) if sem_tenant != '' else None

            conexao.encerra_conexao()
        except:
            conexao.encerra_conexao()

# if (__name__ == "__main__"):
#     gera_totalizador(dry_run_por_tenant(tenants_bloqueados()))

objeto = ETLTenants()
objeto.extract_transform()
objeto.load()