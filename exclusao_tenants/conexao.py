import psycopg2

class ConexaoPostgreSQL:

    def __init__(self, parametros):
        try:
            self._conexao = psycopg2.connect(**parametros)
        except (Exception, psycopg2.DatabaseError) as error:
            print(error)
    
    def encerra_conexao(self):
        try:
            self._conexao.close()
        except (Exception, psycopg2.DatabaseError) as error:
            print(error)
    
    def exeucao_query_sem_retorno(self, query=None,argumentos={}):
        try:
            cursor = self._conexao.cursor()
            cursor.execute(query,argumentos)
            self._conexao.commit()
            cursor.close()
        except (Exception, psycopg2.DatabaseError) as error:
            print(error)
    
    def exeucao_query(self, query=None,argumentos={}):
        try:
            cursor = self._conexao.cursor()
            cursor.execute(query,argumentos)
            self._conexao.commit()
            retorno = cursor.fetchall()
            cursor.close()
            return retorno
        except (Exception, psycopg2.DatabaseError) as error:
            print(error)