/*

CASO NÃO EXISTA NA INSTÂNCIA:

CREATE ROLE estatisticas WITH LOGIN PASSWORD '';
GRANT rds_superuser TO estatisticas;
CREATE DATABASE estatisticas;
ALTER DATABASE estatisticas OWNER TO estatisticas;

*/

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

DROP TABLE IF EXISTS dadostabelastenants;
DROP TABLE IF EXISTS dadostabelassemtenants;

CREATE TABLE dadostabelastenants (
	dadotabelatenant uuid NOT NULL DEFAULT uuid_generate_v4(),
	esquema varchar NOT NULL,
	tabela varchar NOT NULL,
	tenant bigint,
	numeroregistros numeric NOT NULL,
	espacoocupado numeric NOT NULL,
	created_at timestamp without time zone NOT NULL,
	CONSTRAINT pk_dadostabelastenants PRIMARY KEY (dadotabelatenant)
);

CREATE TABLE dadostabelassemtenants (
	dadotabelasemtenant uuid NOT NULL DEFAULT uuid_generate_v4(),
	esquema varchar NOT NULL,
	tabela varchar NOT NULL,
	numeroregistros numeric NOT NULL,
	espacoocupado numeric NOT NULL,
	created_at timestamp without time zone NOT NULL,
	CONSTRAINT pk_dadostabelassemtenants PRIMARY KEY (dadotabelasemtenant)
);

ALTER TABLE dadostabelastenants OWNER TO estatisticas;
ALTER TABLE dadostabelassemtenants OWNER TO estatisticas;

GRANT SELECT ON TABLE dadostabelastenants, dadostabelassemtenants TO group_nasajon;
