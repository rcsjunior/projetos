import re

class ExtratorURL:
    def __init__(self, url):
        self.url = self.sanitiza_url(url)
        self.valida_url()
    
    def sanitiza_url(self, url):
        if type(url) == str:
            return url.strip()
        else:
            return ""
    
    def valida_url(self):
        if not self.url:
            raise ValueError("A URL está vazia")

        padrao_url = re.compile('(http(s)?://)?(www.)?bytebank.com(.br)?/cambio')
        match = padrao_url.match(self.url)
        if not match:
            raise ValueError("A URL não é válida.")
    
    def get_url_base(self):
        indice_interrogacao = self.url.find('?')
        url_base = self.url[:indice_interrogacao]
        return url_base
    
    def get_url_parametros(self):
        indice_interrogacao = self.url.find('?')
        url_parametros = self.url[indice_interrogacao+1:]
        return url_parametros
    
    def get_valor_parametro(self, parametro_busca):
        indice_parametro = self.get_url_parametros().find(parametro_busca)
        indice_valor = indice_parametro + len(parametro_busca) + 1
        indice_e_comercial = self.get_url_parametros().find('&', indice_valor)
        if indice_e_comercial == -1:
            valor = self.get_url_parametros()[indice_valor:]
        else:
            valor = self.get_url_parametros()[indice_valor:indice_e_comercial]
        return valor
    
    def conversao(self, parametro):
        moeda_origem = self.get_valor_parametro("moedaOrigem")
        moeda_destino = self.get_valor_parametro("moedaDestino")
        quantidade = self.get_valor_parametro("quantidade")
        quantidade = float(quantidade)

        validador = moeda_origem == 'real'

        if validador:
            conversao = quantidade/parametro
        else:
            conversao = parametro*quantidade

        print(f'{quantidade} em {moeda_origem} equivale a {conversao} em {moeda_destino}.' )
    
    def __len__(self):
        return len(self.url)
    
    def __str__(self):
        return "URL: " + self.url + "\n" + "URL Base: " + self.get_url_base() + "\n" + "Parâmetros: " + self.get_url_parametros() 
    
    def __eq__(self, other):
        return self.url == other.url


url = "bytebank.com/cambio?quantidade=100&moedaOrigem=real&moedaDestino=dolar"
extrator_url = ExtratorURL(url)

VALOR_DOLAR = 5.50

extrator_url.conversao(VALOR_DOLAR)