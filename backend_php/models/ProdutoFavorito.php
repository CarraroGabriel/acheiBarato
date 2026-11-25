<?php

require_once __DIR__ . '/../config/Database.php';

class ProdutoFavorito
{
    private PDO $conexao;

    public function __construct()
    {
        $this->conexao = (new Database())->conectar();
    }

    public function existe(int $idUsuario, int $idItemProduto): bool
    {
        $stmt = $this->conexao->prepare(
            'SELECT 1 FROM tb_produto_favorito
             WHERE id_usuario = :u AND id_item_produto = :i'
        );
        $stmt->bindValue(':u', $idUsuario, PDO::PARAM_INT);
        $stmt->bindValue(':i', $idItemProduto, PDO::PARAM_INT);
        $stmt->execute();
        return (bool) $stmt->fetch();
    }

    public function adicionar(int $idUsuario, int $idItemProduto): void
    {
        $stmt = $this->conexao->prepare(
            'INSERT INTO tb_produto_favorito (id_usuario, id_item_produto)
             VALUES (:u, :i)
             ON CONFLICT (id_usuario, id_item_produto) DO NOTHING'
        );
        $stmt->bindValue(':u', $idUsuario, PDO::PARAM_INT);
        $stmt->bindValue(':i', $idItemProduto, PDO::PARAM_INT);
        $stmt->execute();
    }

    public function remover(int $idUsuario, int $idItemProduto): void
    {
        $stmt = $this->conexao->prepare(
            'DELETE FROM tb_produto_favorito
             WHERE id_usuario = :u AND id_item_produto = :i'
        );
        $stmt->bindValue(':u', $idUsuario, PDO::PARAM_INT);
        $stmt->bindValue(':i', $idItemProduto, PDO::PARAM_INT);
        $stmt->execute();
    }
}
