-- TOP TENANTS - ESPAÇO
SELECT
	tenant,
	pg_size_pretty(SUM(espacoocupado)) AS espaco_ocupado
FROM dadostabelastenants
WHERE created_at = (SELECT MAX(created_at) FROM dadostabelastenants)
AND tenant IS NOT NULL
GROUP BY tenant
ORDER BY SUM(espacoocupado) DESC

-- TOP TENANTS - QUANTIDADE DE REGISTROS
SELECT
	tenant,
	SUM(numeroregistros) AS quantidade_registros
FROM dadostabelastenants
WHERE created_at = (SELECT MAX(created_at) FROM dadostabelastenants)
AND tenant IS NOT NULL
GROUP BY tenant
ORDER BY SUM(numeroregistros) DESC

-- TOP TABELAS - ESPAÇO
SELECT
	esquema,
	tabela,
	pg_size_pretty(SUM(espacoocupado)) AS espaco_ocupado
FROM dadostabelastenants
WHERE created_at = (SELECT MAX(created_at) FROM dadostabelastenants)
GROUP BY esquema, tabela
ORDER BY SUM(espacoocupado) DESC

-- TOP TABELAS - QUANTIDADE DE REGISTROS
SELECT
	esquema,
	tabela,
	SUM(numeroregistros) AS quantidade_registros
FROM dadostabelastenants
WHERE created_at = (SELECT MAX(created_at) FROM dadostabelastenants)
GROUP BY esquema, tabela
ORDER BY SUM(numeroregistros) DESC

-- DIFERENÇA ENTRE DIAS DE MENSURAÇÃO
WITH dados_dia AS (
	SELECT
		created_at::DATE AS data_snapshot,
		SUM(numeroregistros) AS quantidade_registros,
		SUM(espacoocupado) AS espaco_ocupado,
		ROW_NUMBER() OVER (PARTITION BY created_at::DATE ORDER BY created_at DESC) ordem_created_at
	FROM dadostabelastenants
	GROUP BY created_at
	ORDER BY SUM(numeroregistros) DESC
), dados_dia_ordem AS (
	SELECT
		data_snapshot,
		quantidade_registros,
		espaco_ocupado,
		ROW_NUMBER() OVER (ORDER BY data_snapshot  DESC) AS ordem_data_snapshot
	FROM dados_dia
	WHERE ordem_created_at = 1


)
SELECT
	ddo.data_snapshot,
	ddoa.data_snapshot data_snapshot_dia_anterior,
	ddo.quantidade_registros-ddoa.quantidade_registros AS diferencas_registros,
	pg_size_pretty(ddo.espaco_ocupado-ddoa.espaco_ocupado) AS diferencas_espaco_ocupado
FROM dados_dia_ordem AS ddo
INNER JOIN dados_dia_ordem AS ddoa ON ddo.ordem_data_snapshot = ddoa.ordem_data_snapshot-1

-- TABELAS COM TENANT VAZIO
SELECT
	esquema,
	tabela,
	SUM(numeroregistros) AS quantidade_registros,
	pg_size_pretty(SUM(espacoocupado)) AS espaco_ocupado
FROM dadostabelastenants
WHERE created_at = (SELECT MAX(created_at) FROM dadostabelastenants)
AND tenant IS NULL
GROUP BY esquema, tabela
ORDER BY SUM(espacoocupado) DESC

-- TABELAS SEM CAMPO TENANT COM REGISTROS
SELECT
	esquema,
	tabela,
	numeroregistros,
	pg_size_pretty(espacoocupado)
FROM dadostabelassemtenants
WHERE created_at = (SELECT MAX(created_at) FROM dadostabelassemtenants)
ORDER BY esquema, tabela

-- TENANTS DETALHADOS
SELECT t.id AS id,t.codigo AS codigo_tenant, c.codigo AS codigo_erp, c.razaosocial AS razaosocial, CASE COALESCE(c.cpf,'') WHEN '' THEN c.cnpj ELSE c.cpf END,'' AS documento
FROM diretorio.tenants AS t
LEFT JOIN diretorio.clientes AS c ON t.cliente_id = c.id
ORDER BY t.id