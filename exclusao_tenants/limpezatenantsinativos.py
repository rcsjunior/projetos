from dadosconexao import RecuperaDadosConexao
from humanfriendly import format_size
from conexao import ConexaoPostgreSQL
import limpezatenant

def tenants_bloqueados():
    diretorio = ConexaoPostgreSQL(RecuperaDadosConexao("diretorio_prod","Limpeza Tenant Inativos").parametros())
    resultado = diretorio.exeucao_query("SELECT id FROM diretorio.tenants WHERE situacao NOT IN (0,1) ORDER BY id")
    return resultado

def dry_run_por_tenant(resultado):
    tabelas = {}
    for item in resultado:
        registro = limpezatenant.limpeza_tenant("postgresql_prod",item[0],True)
        for tabela in registro:
            ultimo_item = tabela.get("tabela",0) == 0
            if not ultimo_item:
                tabelas[tabela.get("tabela")] = tabelas.get(tabela.get("tabela"),0)+tabela.get("espaco_a_liberar")
    return tabelas

def gera_totalizador(tabelas):
    arquivo = open("total_limpeza.txt","w+")
    total = 0
    for chave, valor in tabelas.items():
        total += valor
        arquivo.write("A tabela {} terá {} de espaço liberado.\n".format(chave, format_size(valor)))
    arquivo.write('Total de espaço a liberar: {}.'.format(format_size(total)))
    arquivo.close()

if (__name__ == "__main__"):
    gera_totalizador(dry_run_por_tenant(tenants_bloqueados()))