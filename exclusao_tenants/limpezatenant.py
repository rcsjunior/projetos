from dadosconexao import RecuperaDadosConexao
from humanfriendly import format_size
from conexao import ConexaoPostgreSQL
import argparse

parser=argparse.ArgumentParser()

parser.add_argument("--section", "-s", help='Nome da seção para recuperação dos dados de conexão')
parser.add_argument("--tenant", "-t", help='Número do tenant que será realizada a limpeza')
parser.add_argument("--dryrun", "-dr", action='store_true', help='Define apenas execução de Dry Run')
args = parser.parse_args()

section = args.section
tenant = args.tenant
dryrun = args.dryrun

def dry_run(tenant,resultado):

    arquivo = open(str(tenant)+"_limpeza.txt","w+")
    for item in resultado:
        ultimo_item = item.get("tabela",0) == 0
        arquivo.write("A tabela {} terá {} de espaço liberado ({}).\n".format(item.get("tabela",0), format_size(item.get("espaco_a_liberar",0)),item.get("ordem",0))) if not ultimo_item else None
        arquivo.write('Total de espaço a liberar: {}.'.format(format_size(item.get("total_espaco_liberado",0)))) if ultimo_item else None
    arquivo.close()

def limpa_tenant(tenant,resultado):
    pass    

def limpeza_tenant(section,tenant,dryrun):

    conexao = ConexaoPostgreSQL(RecuperaDadosConexao(section).parametros())
    conexao.exeucao_query_sem_retorno("SELECT public.reordenar_tabela_sincronia()")
    resultado = conexao.exeucao_query("SELECT public.gera_limpa_tenant(%(long)s)",{'long': tenant})
    resultado = resultado[0][0]
    
    dry_run(tenant,resultado) if dryrun else limpa_tenant(tenant,resultado)

    return resultado

if (__name__ == "__main__"):
    limpeza_tenant(section,tenant,dryrun)