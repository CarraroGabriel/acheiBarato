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


CREATE TABLE Tb_Mercado (
                id_mercado INTEGER NOT NULL,
                nu_cnpj CHAR(14) NOT NULL,
                nm_mercado VARCHAR(30) NOT NULL,
                ds_email VARCHAR(50) NOT NULL,
                nu_cep INTEGER NOT NULL,
                nm_endereco VARCHAR(50) NOT NULL,
                ds_senha VARCHAR(15) NOT NULL,
                fl_motoboy BOOLEAN NOT NULL,
                ds_foto_mercado VARCHAR(50) NOT NULL,
                nu_latitude NUMERIC NOT NULL,
                nu_longitude NUMERIC NOT NULL,
                nu_avg_nota NUMERIC(3,2) NOT NULL,
                nul_avaliacoes INTEGER NOT NULL,
                CONSTRAINT pk_mercado PRIMARY KEY (id_mercado)
);


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


CREATE TABLE Tb_Usuario (
                id_usuario INTEGER NOT NULL,
                nu_cpf CHAR(11) NOT NULL,
                nm_usuario VARCHAR(50) NOT NULL,
                ds_email VARCHAR(50) NOT NULL,
                dt_nascimento DATE NOT NULL,
                ds_senha VARCHAR(15) NOT NULL,
                CONSTRAINT pk_usuario PRIMARY KEY (id_usuario)
);


CREATE UNIQUE INDEX tb_usuario_idx
 ON Tb_Usuario
 ( nu_cpf );

CREATE TABLE Tb_Carrinho (
                id_carrinho INTEGER NOT NULL,
                fl_ativo BOOLEAN NOT NULL,
                id_usuario INTEGER NOT NULL,
                CONSTRAINT pk_carrinho PRIMARY KEY (id_carrinho)
);


CREATE TABLE Tb_Item_Carrinho (
                id_item_carrinho INTEGER NOT NULL,
                id_carrinho INTEGER NOT NULL,
                id_produto INTEGER NOT NULL,
                vl_total NUMERIC(10,2) NOT NULL,
                nu_qtde INTEGER NOT NULL,
                dt_compra DATE NOT NULL,
                CONSTRAINT tb_item_carrinho_pk PRIMARY KEY (id_item_carrinho, id_carrinho, id_produto)
);


CREATE TABLE Tb_Avaliacao_Mercado (
                id_avaliacao INTEGER NOT NULL,
                id_usuario INTEGER NOT NULL,
                id_mercado INTEGER NOT NULL,
                dt_avaliacao DATE NOT NULL,
                nu_nota INTEGER NOT NULL,
                CONSTRAINT pk_avaliacao_mercado PRIMARY KEY (id_avaliacao, id_usuario, id_mercado)
);


CREATE TABLE Tb_Mercado_Favorito (
                id_mercado_fav INTEGER NOT NULL,
                id_mercado INTEGER NOT NULL,
                id_usuario INTEGER NOT NULL,
                CONSTRAINT pk_mercado_fav PRIMARY KEY (id_mercado_fav, id_mercado, id_usuario)
);


CREATE TABLE Tb_Produto_Favorito (
                id_prod_fav INTEGER NOT NULL,
                id_usuario INTEGER NOT NULL,
                id_produto INTEGER NOT NULL,
                CONSTRAINT pk_produto_favorito PRIMARY KEY (id_prod_fav, id_usuario, id_produto)
);


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