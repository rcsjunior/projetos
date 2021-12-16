class Programa:

    def __init__(self, nome, ano):
        self._nome = nome.title()
        self.ano = ano
        self._likes = 0
    
    @property
    def nome(self):
        return self._nome

    @property
    def likes(self):
        return self._likes
    
    @nome.setter
    def nome(self, novo_nome):
        self._nome=novo_nome.title()
    
    def dar_likes(self):
        self._likes += 1
    
    def __str__(self):
        return f'Nome: {self._nome} - Ano: {self.ano} - Likes: {self._likes}'


class Filme(Programa):

    def __init__(self, nome, ano, duracao):
        super().__init__(nome, ano)
        self.duracao = duracao
    
    def __str__(self):
        return f'Nome: {self._nome} - Ano: {self.ano} - {self.duracao} min - Likes: {self._likes}'

class Serie(Programa):

    def __init__(self, nome, ano, temporadas):
        super().__init__(nome, ano)
        self.temporadas = temporadas
    
    def __str__(self):
        return f'Nome: {self._nome} - Ano: {self.ano} - {self.temporadas} temporadas - Likes: {self._likes}'

class Playlist:

    def __init__(self, nome, programas):
        self.nome = nome
        self._programas = programas
    
    def __getitem__(self, item):
        return self._programas[item]
    
    def __len__(self):
        return len(self._programas)
    
    @property
    def listagem(self):
        return self._programas

vingadores = Filme('vingadores - guerra infinita', 2018, 160)
tmep = Filme('todo mundo em pânico', 1999, 100)
atlanta = Serie('atlanta', 2018, 2)
demolidor = Serie('demolidor', 2016, 2)

vingadores.dar_likes()
vingadores.dar_likes()
vingadores.dar_likes()
atlanta.dar_likes()
atlanta.dar_likes()
tmep.dar_likes()
tmep.dar_likes()
demolidor.dar_likes()
demolidor.dar_likes()

listinha = [atlanta, vingadores, demolidor, tmep]
minha_playlist = Playlist('fim de semana', listinha)

print(f'Tamanho do playlist: {len(minha_playlist)}')

for programa in minha_playlist:
    print(programa)

print(minha_playlist[0])