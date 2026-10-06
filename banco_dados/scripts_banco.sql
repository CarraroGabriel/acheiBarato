-- Criação do Pacote

create schema achei_barato;

set search_path to achei_barato;

-- Criação das Tabelas via SQL Power Architect

CREATE TABLE Tb_Categoria (
                id_categoria INTEGER NOT NULL,
                nm_categoria VARCHAR(30) NOT NULL,
                CONSTRAINT pk_categoria PRIMARY KEY (id_categoria)
);

CREATE SEQUENCE IF NOT EXISTS sq_tb_categoria START 1;
ALTER TABLE tb_categoria
    ALTER COLUMN id_categoria SET DEFAULT nextval('sq_tb_categoria');

CREATE UNIQUE INDEX tb_categoria_nome_uk ON tb_categoria (UPPER(nm_categoria));


CREATE TABLE Tb_Produto (
                id_produto INTEGER NOT NULL,
                nm_produto VARCHAR(50) NOT NULL,
                id_categoria INTEGER NOT NULL,
                ds_imagem_padrao VARCHAR(100), -- imagem incluída no app (ex.: asset:produtos/arroz.png)
                CONSTRAINT pk_produtos PRIMARY KEY (id_produto)
);

CREATE SEQUENCE IF NOT EXISTS sq_tb_produtos START 1;
ALTER TABLE tb_produto
    ALTER COLUMN id_produto SET DEFAULT nextval('sq_tb_produtos');

CREATE UNIQUE INDEX tb_produto_nome_uk ON tb_produto (UPPER(nm_produto));


CREATE TABLE Tb_Tipo_Produto (
                id_tipo INTEGER NOT NULL,
                id_produto INTEGER NOT NULL,
                nm_tipo VARCHAR(30) NOT NULL,
                CONSTRAINT pk_tipo_produto PRIMARY KEY (id_tipo)
);

CREATE SEQUENCE IF NOT EXISTS sq_tb_tipo_produto START 1;
ALTER TABLE tb_tipo_produto
    ALTER COLUMN id_tipo SET DEFAULT nextval('sq_tb_tipo_produto');

CREATE UNIQUE INDEX tb_tipo_produto_uk ON tb_tipo_produto (id_produto, UPPER(nm_tipo));


CREATE TABLE Tb_Marca (
                id_marca INTEGER NOT NULL,
                nm_marca VARCHAR(40) NOT NULL,
                CONSTRAINT pk_marca PRIMARY KEY (id_marca)
);

CREATE SEQUENCE IF NOT EXISTS sq_tb_marca START 1;
ALTER TABLE tb_marca
    ALTER COLUMN id_marca SET DEFAULT nextval('sq_tb_marca');

CREATE UNIQUE INDEX tb_marca_nome_uk ON tb_marca (UPPER(nm_marca));


CREATE TABLE Tb_Marca_Produto (
                id_produto INTEGER NOT NULL,
                id_marca INTEGER NOT NULL,
                CONSTRAINT pk_marca_produto PRIMARY KEY (id_produto, id_marca)
);


/* Unidade de medida
ds_grandeza + nu_fator permitem comparar preço por kg ou por litro
(ex.: 500 g = 500 * 0.001 = 0,5 kg). */

CREATE TABLE Tb_Unidade_Medida (
                id_unidade INTEGER NOT NULL,
                nm_unidade VARCHAR(20) NOT NULL,
                sg_unidade VARCHAR(2) NOT NULL,
                ds_grandeza VARCHAR(10) NOT NULL,
                nu_fator NUMERIC(10,4) NOT NULL,
                CONSTRAINT pk_unidade_medida PRIMARY KEY (id_unidade),
                CONSTRAINT tb_unidade_medida_nome_uk UNIQUE (nm_unidade),
                CONSTRAINT tb_unidade_medida_sigla_uk UNIQUE (sg_unidade),
                CONSTRAINT ck_unidade_medida_grandeza CHECK (ds_grandeza IN ('MASSA', 'VOLUME', 'UNIDADE')),
                CONSTRAINT ck_unidade_medida_fator CHECK (nu_fator > 0)
);

CREATE SEQUENCE IF NOT EXISTS sq_tb_unidade_medida START 1;
ALTER TABLE tb_unidade_medida
    ALTER COLUMN id_unidade SET DEFAULT nextval('sq_tb_unidade_medida');


CREATE TABLE Tb_Item_Produto (
                id_item_produto INTEGER NOT NULL,
                id_tipo INTEGER NOT NULL,
                id_marca INTEGER NOT NULL,
                nu_medida NUMERIC(10,3) NOT NULL,
                id_unidade INTEGER NOT NULL,
                ds_foto_produto VARCHAR(255),
                CONSTRAINT pk_item_produto PRIMARY KEY (id_item_produto),
                CONSTRAINT tb_item_produto_uk UNIQUE (id_tipo, id_marca, nu_medida, id_unidade),
                CONSTRAINT ck_item_produto_medida CHECK (nu_medida > 0)
);

CREATE SEQUENCE IF NOT EXISTS sq_tb_item_produto START 1;
ALTER TABLE tb_item_produto
    ALTER COLUMN id_item_produto SET DEFAULT nextval('sq_tb_item_produto');


CREATE TABLE Tb_Mercado (
                id_mercado INTEGER NOT NULL,
                nu_cnpj CHAR(14) NOT NULL,
                nm_mercado VARCHAR(30) NOT NULL,
                ds_email VARCHAR(50) NOT NULL,
                nu_cep INTEGER NOT NULL,
                nm_endereco VARCHAR(50) NOT NULL,
                ds_senha VARCHAR(255) NOT NULL, -- valor alto para caber o hash de senha
                fl_motoboy BOOLEAN NOT NULL,
                nu_taxa_entrega NUMERIC(5,2) NOT NULL DEFAULT 0, -- taxa da tele-entrega; 0 = grátis
                ds_foto_mercado VARCHAR(255) NOT NULL, -- caminho em public/uploads (ex.: uploads/mercados/1-mercado-do-ze.jpg)
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

ALTER TABLE tb_mercado ADD CONSTRAINT tb_mercado_email_uk UNIQUE (ds_email);


CREATE TABLE Tb_Produto_Mercado (
                id_produto_mercado INTEGER NOT NULL,
                id_item_produto INTEGER NOT NULL,
                id_mercado INTEGER NOT NULL,
                nu_valor NUMERIC(10,2) NOT NULL,
                nu_qtde INTEGER NOT NULL,
                fl_promocao BOOLEAN NOT NULL,
                fl_disponivel BOOLEAN NOT NULL,
                dt_atualizacao DATE NOT NULL,
                nu_desconto INTEGER NOT NULL DEFAULT 0,
                dt_fim_promocao TIMESTAMPTZ, -- término da promoção; nulo = sem prazo
                CONSTRAINT pk_produto_mercado PRIMARY KEY (id_produto_mercado),
                CONSTRAINT tb_produto_mercado_uk UNIQUE (id_item_produto, id_mercado)
);

CREATE SEQUENCE IF NOT EXISTS sq_tb_produto_mercado START 1;
ALTER TABLE tb_produto_mercado
    ALTER COLUMN id_produto_mercado SET DEFAULT nextval('sq_tb_produto_mercado');

ALTER TABLE tb_produto_mercado
    ALTER COLUMN dt_atualizacao SET DEFAULT CURRENT_DATE;

/* Alteração visando o erro de promoção sobre valor de promoção */

ALTER TABLE tb_produto_mercado
ADD CONSTRAINT ck_produto_mercado_desconto CHECK (nu_desconto BETWEEN 0 AND 100);


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

-- remover futuramente fiz automático via email, o login é via CPF
CREATE UNIQUE INDEX IF NOT EXISTS tb_usuario_email_idx
ON tb_usuario
(LOWER(ds_email));


CREATE TABLE Tb_Avaliacao_Mercado (
                id_avaliacao INTEGER NOT NULL,
                id_usuario INTEGER NOT NULL,
                id_mercado INTEGER NOT NULL,
                dt_avaliacao DATE NOT NULL,
                nu_nota INTEGER NOT NULL,
                CONSTRAINT pk_avaliacao_mercado PRIMARY KEY (id_avaliacao, id_usuario, id_mercado),
                CONSTRAINT ck_avaliacao_mercado_nota CHECK (nu_nota BETWEEN 1 AND 5)
);

CREATE SEQUENCE IF NOT EXISTS sq_tb_avaliacao_mercado START 1;
ALTER TABLE tb_avaliacao_mercado
    ALTER COLUMN id_avaliacao SET DEFAULT nextval('sq_tb_avaliacao_mercado');

/* Cada usuário avalia um mercado uma única vez; avaliar de novo substitui a nota. */
CREATE UNIQUE INDEX tb_avaliacao_mercado_uk ON tb_avaliacao_mercado (id_usuario, id_mercado);


CREATE TABLE Tb_Mercado_Favorito (
                id_mercado_fav INTEGER NOT NULL,
                id_mercado INTEGER NOT NULL,
                id_usuario INTEGER NOT NULL,
                CONSTRAINT pk_mercado_fav PRIMARY KEY (id_mercado_fav, id_mercado, id_usuario)
);

CREATE SEQUENCE IF NOT EXISTS sq_tb_mercado_favorito START 1;
ALTER TABLE tb_mercado_favorito
    ALTER COLUMN id_mercado_fav SET DEFAULT nextval('sq_tb_mercado_favorito');

CREATE UNIQUE INDEX IF NOT EXISTS tb_mercado_favorito_uk
	ON tb_mercado_favorito (id_usuario, id_mercado);


CREATE TABLE Tb_Produto_Favorito (
                id_prod_fav INTEGER NOT NULL,
                id_usuario INTEGER NOT NULL,
                id_item_produto INTEGER NOT NULL,
                CONSTRAINT pk_produto_favorito PRIMARY KEY (id_prod_fav, id_usuario, id_item_produto)
);

CREATE SEQUENCE IF NOT EXISTS sq_tb_produto_fav START 1;
ALTER TABLE tb_produto_favorito
    ALTER COLUMN id_prod_fav SET DEFAULT nextval('sq_tb_produto_fav');

CREATE UNIQUE INDEX tb_produto_favorito_uk ON tb_produto_favorito (id_usuario, id_item_produto);


/*
Horario de funcionamento por dia da semana
nu_dia_semana: 0 = domingo ... 6 = sabado (mesma convencao do date('w') do PHP).
Um mercado pode ter mais de uma faixa no mesmo dia (ex.: pausa para almoco).
Limitacao: hr_fechamento > hr_abertura (nao cobre horario que vira a meia-noite).
*/

CREATE TABLE Tb_Horario_Mercado (
                id_horario INTEGER NOT NULL,
                id_mercado INTEGER NOT NULL,
                nu_dia_semana SMALLINT NOT NULL,
                hr_abertura TIME NOT NULL,
                hr_fechamento TIME NOT NULL,
                CONSTRAINT pk_horario_mercado PRIMARY KEY (id_horario),
                CONSTRAINT ck_horario_dia CHECK (nu_dia_semana BETWEEN 0 AND 6),
                CONSTRAINT ck_horario_faixa CHECK (hr_fechamento > hr_abertura)
);

CREATE SEQUENCE IF NOT EXISTS sq_tb_horario_mercado START 1;
ALTER TABLE tb_horario_mercado
    ALTER COLUMN id_horario SET DEFAULT nextval('sq_tb_horario_mercado');

CREATE INDEX IF NOT EXISTS tb_horario_mercado_idx ON tb_horario_mercado (id_mercado, nu_dia_semana);


-- Chaves estrangeiras

ALTER TABLE Tb_Produto ADD CONSTRAINT tb_categoria_tb_produto_fk
FOREIGN KEY (id_categoria)
REFERENCES Tb_Categoria (id_categoria);

ALTER TABLE Tb_Tipo_Produto ADD CONSTRAINT tb_produto_tb_tipo_produto_fk
FOREIGN KEY (id_produto)
REFERENCES Tb_Produto (id_produto);

ALTER TABLE Tb_Marca_Produto ADD CONSTRAINT tb_produto_tb_marca_produto_fk
FOREIGN KEY (id_produto)
REFERENCES Tb_Produto (id_produto);

ALTER TABLE Tb_Marca_Produto ADD CONSTRAINT tb_marca_tb_marca_produto_fk
FOREIGN KEY (id_marca)
REFERENCES Tb_Marca (id_marca);

ALTER TABLE Tb_Item_Produto ADD CONSTRAINT tb_tipo_produto_tb_item_produto_fk
FOREIGN KEY (id_tipo)
REFERENCES Tb_Tipo_Produto (id_tipo);

ALTER TABLE Tb_Item_Produto ADD CONSTRAINT tb_marca_tb_item_produto_fk
FOREIGN KEY (id_marca)
REFERENCES Tb_Marca (id_marca);

ALTER TABLE Tb_Item_Produto ADD CONSTRAINT tb_unidade_medida_tb_item_produto_fk
FOREIGN KEY (id_unidade)
REFERENCES Tb_Unidade_Medida (id_unidade);

ALTER TABLE Tb_Produto_Mercado ADD CONSTRAINT tb_item_produto_tb_produto_mercado_fk
FOREIGN KEY (id_item_produto)
REFERENCES Tb_Item_Produto (id_item_produto);

ALTER TABLE Tb_Produto_Mercado ADD CONSTRAINT tb_mercado_tb_produto_mercado_fk
FOREIGN KEY (id_mercado)
REFERENCES Tb_Mercado (id_mercado);

ALTER TABLE Tb_Produto_Favorito ADD CONSTRAINT tb_item_produto_tb_produto_favorito_fk
FOREIGN KEY (id_item_produto)
REFERENCES Tb_Item_Produto (id_item_produto);

ALTER TABLE Tb_Mercado_Favorito ADD CONSTRAINT tb_mercado_tb_mercado_favorito_fk
FOREIGN KEY (id_mercado)
REFERENCES Tb_Mercado (id_mercado);

ALTER TABLE Tb_Avaliacao_Mercado ADD CONSTRAINT tb_mercado_tb_avaliacao_mercado_fk
FOREIGN KEY (id_mercado)
REFERENCES Tb_Mercado (id_mercado);

ALTER TABLE Tb_Horario_Mercado ADD CONSTRAINT tb_horario_mercado_tb_mercado_fk
FOREIGN KEY (id_mercado)
REFERENCES Tb_Mercado (id_mercado);

ALTER TABLE Tb_Produto_Favorito ADD CONSTRAINT tb_usuario_tb_produto_favorito_fk
FOREIGN KEY (id_usuario)
REFERENCES Tb_Usuario (id_usuario);

ALTER TABLE Tb_Mercado_Favorito ADD CONSTRAINT tb_usuario_tb_mercado_favorito_fk
FOREIGN KEY (id_usuario)
REFERENCES Tb_Usuario (id_usuario);

ALTER TABLE Tb_Avaliacao_Mercado ADD CONSTRAINT tb_usuario_tb_avaliacao_mercado_fk
FOREIGN KEY (id_usuario)
REFERENCES Tb_Usuario (id_usuario);


/* View com a descrição completa do item, usada pelas consultas da API.
ds_item_produto: "ARROZ BRANCO 5 kg"
ds_foto_produto: foto do item (enviada pelo mercado ou "asset:" incluída no app);
ds_imagem_padrao: imagem genérica do produto, usada quando o item não tem foto. */

CREATE OR REPLACE VIEW vw_item_produto AS
SELECT i.id_item_produto,
       p.id_produto, p.nm_produto,
       t.id_tipo, t.nm_tipo,
       m.id_marca, m.nm_marca,
       c.id_categoria, c.nm_categoria,
       i.nu_medida,
       u.id_unidade, u.sg_unidade, u.ds_grandeza, u.nu_fator,
       i.ds_foto_produto,
       p.nm_produto || ' ' || t.nm_tipo || ' '
           || REPLACE(TRIM(TRAILING '.' FROM TRIM(TRAILING '0' FROM i.nu_medida::TEXT)), '.', ',')
           || ' ' || u.sg_unidade AS ds_item_produto,
       p.ds_imagem_padrao
  FROM tb_item_produto i
 INNER JOIN tb_tipo_produto t ON t.id_tipo = i.id_tipo
 INNER JOIN tb_produto p ON p.id_produto = t.id_produto
 INNER JOIN tb_categoria c ON c.id_categoria = p.id_categoria
 INNER JOIN tb_marca m ON m.id_marca = i.id_marca
 INNER JOIN tb_unidade_medida u ON u.id_unidade = i.id_unidade;

/* Dados iniciais */

INSERT INTO tb_unidade_medida (nm_unidade, sg_unidade, ds_grandeza, nu_fator) VALUES
    ('Grama',      'g',  'MASSA',   0.001),
    ('Quilograma', 'kg', 'MASSA',   1),
    ('Mililitro',  'mL', 'VOLUME',  0.001),
    ('Litro',      'L',  'VOLUME',  1),
    ('Unidade',    'un', 'UNIDADE', 1);

INSERT INTO tb_categoria (nm_categoria) VALUES
    ('GRÃOS'), ('CARNES'), ('MASSAS'), ('LATICÍNIOS'), ('ÓLEOS'),
    ('MERCEARIA'), ('BEBIDAS'), ('LIMPEZA'), ('OUTRO');

INSERT INTO tb_produto (nm_produto, id_categoria, ds_imagem_padrao)
SELECT v.nm_produto, c.id_categoria, v.ds_imagem_padrao
  FROM (VALUES
        ('ARROZ',        'GRÃOS',      'asset:produtos/arroz.png'),
        ('FEIJÃO',       'GRÃOS',      'asset:produtos/feijao.png'),
        ('CARNE BOVINA', 'CARNES',     'asset:produtos/carne_bovina.png'),
        ('FRANGO',       'CARNES',     'asset:produtos/frango.png'),
        ('MASSA',        'MASSAS',     'asset:produtos/massa.png'),
        ('LEITE',        'LATICÍNIOS', 'asset:produtos/leite.png'),
        ('ÓLEO',         'ÓLEOS',      'asset:produtos/oleo.png'),
        ('AÇÚCAR',       'MERCEARIA',  'asset:produtos/acucar.png'),
        ('CAFÉ',         'MERCEARIA',  'asset:produtos/cafe.png'),
        ('AMACIANTE',    'LIMPEZA',    'asset:produtos/amaciante.png')
       ) AS v (nm_produto, nm_categoria, ds_imagem_padrao)
 INNER JOIN tb_categoria c ON c.nm_categoria = v.nm_categoria;

INSERT INTO tb_tipo_produto (id_produto, nm_tipo)
SELECT p.id_produto, v.nm_tipo
  FROM (VALUES
        ('ARROZ', 'BRANCO'), ('ARROZ', 'INTEGRAL'), ('ARROZ', 'PARBOILIZADO'),
        ('FEIJÃO', 'PRETO'), ('FEIJÃO', 'CARIOCA'), ('FEIJÃO', 'VERMELHO'),
        ('CARNE BOVINA', 'MAMINHA'), ('CARNE BOVINA', 'COXÃO MOLE'), ('CARNE BOVINA', 'PATINHO'),
        ('FRANGO', 'PEITO'), ('FRANGO', 'SOBRECOXA'), ('FRANGO', 'COXA'),
        ('MASSA', 'PARAFUSO'), ('MASSA', 'ESPAGUETE'), ('MASSA', 'PENNE'),
        ('LEITE', 'INTEGRAL'), ('LEITE', 'SEMIDESNATADO'), ('LEITE', 'DESNATADO'),
        ('ÓLEO', 'SOJA'), ('ÓLEO', 'MILHO'), ('ÓLEO', 'CANOLA'),
        ('AÇÚCAR', 'REFINADO'), ('AÇÚCAR', 'CRISTAL'), ('AÇÚCAR', 'DEMERARA'),
        ('CAFÉ', 'TRADICIONAL'), ('CAFÉ', 'EXTRAFORTE'), ('CAFÉ', 'DESCAFEINADO'),
        ('AMACIANTE', 'CONCENTRADO'), ('AMACIANTE', 'DILUÍDO'), ('AMACIANTE', 'PERFUMADO')
       ) AS v (nm_produto, nm_tipo)
 INNER JOIN tb_produto p ON p.nm_produto = v.nm_produto;

INSERT INTO tb_marca (nm_marca) VALUES
    ('TIO JOÃO'), ('NAMORADO'), ('PRATO FINO'), ('FRITZ & FRIDA'),
    ('CAMIL'), ('QUERO'),
    ('FRIBOI'), ('MINERVA'), ('BASSI'),
    ('SADIA'), ('PERDIGÃO'), ('AURORA'),
    ('ORQUÍDEA'), ('ISABELA'), ('RENATA'),
    ('ELEGÊ'), ('PIÁ'), ('ITALAC'),
    ('LIZA'), ('SOYA'), ('COAMO'),
    ('UNIÃO'), ('CARAVELAS'), ('DA BARRA'),
    ('MELITTA'), ('3 CORAÇÕES'), ('PILÃO'),
    ('COMFORT'), ('DOWNY'), ('FOFO');

INSERT INTO tb_marca_produto (id_produto, id_marca)
SELECT p.id_produto, m.id_marca
  FROM (VALUES
        ('ARROZ', 'TIO JOÃO'), ('ARROZ', 'NAMORADO'), ('ARROZ', 'PRATO FINO'), ('ARROZ', 'FRITZ & FRIDA'),
        ('FEIJÃO', 'CAMIL'), ('FEIJÃO', 'NAMORADO'), ('FEIJÃO', 'QUERO'),
        ('CARNE BOVINA', 'FRIBOI'), ('CARNE BOVINA', 'MINERVA'), ('CARNE BOVINA', 'BASSI'),
        ('FRANGO', 'SADIA'), ('FRANGO', 'PERDIGÃO'), ('FRANGO', 'AURORA'),
        ('MASSA', 'ORQUÍDEA'), ('MASSA', 'ISABELA'), ('MASSA', 'RENATA'),
        ('LEITE', 'ELEGÊ'), ('LEITE', 'PIÁ'), ('LEITE', 'ITALAC'),
        ('ÓLEO', 'LIZA'), ('ÓLEO', 'SOYA'), ('ÓLEO', 'COAMO'),
        ('AÇÚCAR', 'UNIÃO'), ('AÇÚCAR', 'CARAVELAS'), ('AÇÚCAR', 'DA BARRA'),
        ('CAFÉ', 'MELITTA'), ('CAFÉ', '3 CORAÇÕES'), ('CAFÉ', 'PILÃO'),
        ('AMACIANTE', 'COMFORT'), ('AMACIANTE', 'DOWNY'), ('AMACIANTE', 'FOFO')
       ) AS v (nm_produto, nm_marca)
 INNER JOIN tb_produto p ON p.nm_produto = v.nm_produto
 INNER JOIN tb_marca m ON m.nm_marca = v.nm_marca;
