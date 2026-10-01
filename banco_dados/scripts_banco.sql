-- Criação do Pacote

create schema achei_barato

set search_path to achei_barato;

-- Criação das Tabelas via SQL Power Architect

CREATE TABLE Tb_Produtos (
                id_produto INTEGER NOT NULL,
                nm_produto VARCHAR(20) NOT NULL,
                nm_marca VARCHAR(30) NOT NULL,
                ds_categoria VARCHAR(20) NOT NULL,
                ds_foto_produto VARCHAR(50) NOT NULL,
                CONSTRAINT pk_produtos PRIMARY KEY (id_produto)
);

CREATE SEQUENCE IF NOT EXISTS sq_tb_produtos START 1;
ALTER TABLE tb_produtos
    ALTER COLUMN id_produto SET DEFAULT nextval('sq_tb_produtos');


CREATE TABLE Tb_Mercado (
                id_mercado INTEGER NOT NULL,
                nu_cnpj CHAR(14) NOT NULL,
                nm_mercado VARCHAR(30) NOT NULL,
                ds_email VARCHAR(50) NOT NULL,
                nu_cep INTEGER NOT NULL,
                nm_endereco VARCHAR(50) NOT NULL,
                ds_senha VARCHAR(255) NOT NULL, -- valor alto para caber o hash de senha
                fl_motoboy BOOLEAN NOT NULL,
                ds_foto_mercado VARCHAR(50) NOT NULL,
                nu_latitude NUMERIC NOT NULL,
                nu_longitude NUMERIC NOT NULL,
                nu_avg_nota NUMERIC(3,2) NOT NULL,
                nul_avaliacoes INTEGER NOT NULL,
                CONSTRAINT pk_mercado PRIMARY KEY (id_mercado)
);

CREATE SEQUENCE IF NOT EXISTS sq_tb_mercado START 1;
ALTER TABLE tb_mercado
    ALTER COLUMN id_mercado SET DEFAULT nextval('sq_tb_mercado');

CREATE UNIQUE INDEX tb_mercado_idx
 ON Tb_Mercado
 ( nu_cnpj );

CREATE TABLE Tb_Produto_Mercado (
                id_produto_mercado INTEGER NOT NULL,
                id_produto INTEGER NOT NULL,
                id_mercado INTEGER NOT NULL,
                nu_valor NUMERIC(10,2) NOT NULL,
                nu_qtde INTEGER NOT NULL,
                fl_promocao BOOLEAN NOT NULL,
                fl_disponivel BOOLEAN NOT NULL,
                dt_atualizacao DATE NOT NULL,
                CONSTRAINT pk_produto_mercado PRIMARY KEY (id_produto_mercado, id_produto, id_mercado)
);

CREATE SEQUENCE IF NOT EXISTS sq_tb_produto_mercado START 1;
ALTER TABLE tb_produto_mercado
    ALTER COLUMN id_produto_mercado SET DEFAULT nextval('sq_tb_produto_mercado');

ALTER TABLE tb_produto_mercado
    ALTER COLUMN dt_atualizacao SET DEFAULT CURRENT_DATE;

CREATE TABLE Tb_Usuario (
                id_usuario INTEGER NOT NULL,
                nu_cpf CHAR(11) NOT NULL,
                nm_usuario VARCHAR(50) NOT NULL,
                ds_email VARCHAR(50) NOT NULL,
                dt_nascimento DATE NOT NULL,
                ds_senha VARCHAR(255) NOT NULL, -- valor alto para caber o hash de senha
                CONSTRAINT pk_usuario PRIMARY KEY (id_usuario)
);

CREATE SEQUENCE IF NOT EXISTS sq_tb_usuario START 1;
ALTER TABLE tb_usuario
    ALTER COLUMN id_usuario SET DEFAULT nextval('sq_tb_usuario');


CREATE UNIQUE INDEX tb_usuario_idx
 ON Tb_Usuario
 ( nu_cpf );

 /* O login do usuário é feito por e-mail. Para evitar duas contas com o mesmo
    identificador de login, foi criado índices únicos de e-mail.*/
CREATE UNIQUE INDEX IF NOT EXISTS tb_usuario_email_idx 
ON tb_usuario 
(LOWER(ds_email));

CREATE TABLE Tb_Carrinho (
                id_carrinho INTEGER NOT NULL,
                fl_ativo BOOLEAN NOT NULL,
                id_usuario INTEGER NOT NULL,
                CONSTRAINT pk_carrinho PRIMARY KEY (id_carrinho)
);

CREATE SEQUENCE IF NOT EXISTS sq_tb_carrinho START 1;
ALTER TABLE tb_carrinho
    ALTER COLUMN id_carrinho SET DEFAULT nextval('sq_tb_carrinho');


CREATE TABLE Tb_Item_Carrinho (
                id_item_carrinho INTEGER NOT NULL,
                id_carrinho INTEGER NOT NULL,
                id_produto INTEGER NOT NULL,
                vl_total NUMERIC(10,2) NOT NULL,
                nu_qtde INTEGER NOT NULL,
                dt_compra DATE NOT NULL,
                CONSTRAINT tb_item_carrinho_pk PRIMARY KEY (id_item_carrinho, id_carrinho, id_produto)
);

CREATE SEQUENCE IF NOT EXISTS sq_tb_item_carrinho START 1;
ALTER TABLE tb_item_carrinho
    ALTER COLUMN id_item_carrinho SET DEFAULT nextval('sq_tb_item_carrinho');

CREATE TABLE Tb_Avaliacao_Mercado (
                id_avaliacao INTEGER NOT NULL,
                id_usuario INTEGER NOT NULL,
                id_mercado INTEGER NOT NULL,
                dt_avaliacao DATE NOT NULL,
                nu_nota INTEGER NOT NULL,
                CONSTRAINT pk_avaliacao_mercado PRIMARY KEY (id_avaliacao, id_usuario, id_mercado)
);

CREATE SEQUENCE IF NOT EXISTS sq_tb_avaliacao_mercado START 1;
ALTER TABLE tb_avaliacao_mercado
    ALTER COLUMN id_avaliacao SET DEFAULT nextval('sq_tb_avaliacao_mercado');

CREATE TABLE Tb_Mercado_Favorito (
                id_mercado_fav INTEGER NOT NULL,
                id_mercado INTEGER NOT NULL,
                id_usuario INTEGER NOT NULL,
                CONSTRAINT pk_mercado_fav PRIMARY KEY (id_mercado_fav, id_mercado, id_usuario)
);

CREATE SEQUENCE IF NOT EXISTS sq_tb_mercado_favorito START 1;
ALTER TABLE tb_mercado_favorito
    ALTER COLUMN id_mercado_fav SET DEFAULT nextval('sq_tb_mercado_favorito');

CREATE TABLE Tb_Produto_Favorito (
                id_prod_fav INTEGER NOT NULL,
                id_usuario INTEGER NOT NULL,
                id_produto INTEGER NOT NULL,
                CONSTRAINT pk_produto_favorito PRIMARY KEY (id_prod_fav, id_usuario, id_produto)
);

CREATE SEQUENCE IF NOT EXISTS sq_tb_produto_fav START 1;
ALTER TABLE tb_produto_favorito
    ALTER COLUMN id_prod_fav SET DEFAULT nextval('sq_tb_produto_fav');

ALTER TABLE Tb_Produto_Mercado ADD CONSTRAINT tb_produtos_tb_produto_mercado_fk
FOREIGN KEY (id_produto)
REFERENCES Tb_Produtos (id_produto);

ALTER TABLE Tb_Produto_Favorito ADD CONSTRAINT tb_produtos_tb_produto_favorito_fk
FOREIGN KEY (id_produto)
REFERENCES Tb_Produtos (id_produto);

ALTER TABLE Tb_Item_Carrinho ADD CONSTRAINT tb_produtos_tb_item_carrinho_fk
FOREIGN KEY (id_produto)
REFERENCES Tb_Produtos (id_produto);

ALTER TABLE Tb_Produto_Mercado ADD CONSTRAINT tb_mercado_tb_produto_mercado_fk
FOREIGN KEY (id_mercado)
REFERENCES Tb_Mercado (id_mercado);

ALTER TABLE Tb_Mercado_Favorito ADD CONSTRAINT tb_mercado_tb_mercado_favorito_fk
FOREIGN KEY (id_mercado)
REFERENCES Tb_Mercado (id_mercado);

ALTER TABLE Tb_Avaliacao_Mercado ADD CONSTRAINT tb_mercado_tb_avaliacao_mercado_fk
FOREIGN KEY (id_mercado)
REFERENCES achei_barato.Tb_Mercado (id_mercado);

ALTER TABLE Tb_Produto_Favorito ADD CONSTRAINT tb_usuario_tb_produto_favorito_fk
FOREIGN KEY (id_usuario)
REFERENCES achei_barato.Tb_Usuario (id_usuario);

ALTER TABLE Tb_Mercado_Favorito ADD CONSTRAINT tb_usuario_tb_mercado_favorito_fk
FOREIGN KEY (id_usuario)
REFERENCES achei_barato.Tb_Usuario (id_usuario);

ALTER TABLE Tb_Avaliacao_Mercado ADD CONSTRAINT tb_usuario_tb_avaliacao_mercado_fk
FOREIGN KEY (id_usuario)
REFERENCES achei_barato.Tb_Usuario (id_usuario);

ALTER TABLE Tb_Carrinho ADD CONSTRAINT tb_usuario_tb_carrinho_fk
FOREIGN KEY (id_usuario)
REFERENCES achei_barato.Tb_Usuario (id_usuario);

ALTER TABLE Tb_Item_Carrinho ADD CONSTRAINT tb_carrinho_tb_item_carrinho_fk
FOREIGN KEY (id_carrinho)
REFERENCES achei_barato.Tb_Carrinho (id_carrinho);

ALTER TABLE tb_mercado ADD CONSTRAINT tb_mercado_email_uk UNIQUE (ds_email);

/* ============================================================ 
Horario de funcionamento por dia da semana 
nu_dia_semana: 0 = domingo ... 6 = sabado (mesma convencao do date('w') do PHP).
Um mercado pode ter mais de uma faixa no mesmo dia (ex.: pausa para almoco).
Limitacao: hr_fechamento > hr_abertura (nao cobre horario que vira a meia-noite). 
============================================================ */


CREATE SEQUENCE IF NOT EXISTS sq_tb_horario_mercado START 1;

CREATE TABLE IF NOT EXISTS tb_horario_mercado (
    id_horario     INTEGER  NOT NULL DEFAULT nextval('sq_tb_horario_mercado'),
    id_mercado     INTEGER  NOT NULL,
    nu_dia_semana  SMALLINT NOT NULL,
    hr_abertura    TIME     NOT NULL,
    hr_fechamento  TIME     NOT NULL,
    CONSTRAINT pk_horario_mercado PRIMARY KEY (id_horario),
    CONSTRAINT ck_horario_dia CHECK (nu_dia_semana BETWEEN 0 AND 6),
    CONSTRAINT ck_horario_faixa CHECK (hr_fechamento > hr_abertura) 
);

ALTER TABLE tb_horario_mercado ADD CONSTRAINT tb_horario_mercado_tb_mercado_fk
FOREIGN KEY (id_mercado)
REFERENCES tb_mercado (id_mercado);

CREATE INDEX IF NOT EXISTS tb_horario_mercado_idx ON tb_horario_mercado (id_mercado, nu_dia_semana);