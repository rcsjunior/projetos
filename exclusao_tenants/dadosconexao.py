from configparser import ConfigParser

class RecuperaDadosConexao:

    def __init__(self, section=None, filename="database.ini"):
        self._filename = filename
        self._section = section
        self.valida_dados_conexao()
    
    def __str__(self):
        return "{0}".format(self.parametros())
    
    def parametros(self):
        # create a parser
        parser = ConfigParser()
        # read config file
        parser.read(self._filename)

        # get section, default to postgresql
        db = {}
        params = parser.items(self._section)
        for param in params:
            db[param[0]] = param[1]
        
        return db
    
    def valida_dados_conexao(self):
        if not self._section:
            raise ValueError("Seção não informada.")
        
        parser = ConfigParser()
        existe_arquivo = parser.read(self._filename) != []
        if not existe_arquivo:
            raise ValueError("Arquivo não encontrado.")
        
        if not parser.has_section(self._section):
            raise ValueError('Seção {0} não encontrada no arquivo {1}.'.format(self._section, self._filename))
        
        existe_parametros = parser.items(self._section) != []
        if not existe_parametros:
            raise ValueError('Seção {0} sem parâmetros.'.format(self._section))