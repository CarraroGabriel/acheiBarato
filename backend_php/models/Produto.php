<?php

require_once __DIR__ . '/../config/Database.php';

class Produto
{
    private PDO $conexao;

    public function __construct()
    {
        $database = new Database();
        $this->conexao = $database->conectar();
    }

    public function listar(): array
    {
        $sql = 'SELECT id_produto, nm_produto, nm_marca, ds_categoria, ds_foto_produto
                FROM tb_produto
                ORDER BY nm_produto';

        $stmt = $this->conexao->prepare($sql);
        $stmt->execute();
        return $stmt->fetchAll();
    }

    public function consultarPorId(int $idProduto): ?array
    {
        $sql = 'SELECT id_produto, nm_produto, nm_marca, ds_categoria, ds_foto_produto
                FROM tb_produto
                WHERE id_produto = :id_produto';

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':id_produto', $idProduto, PDO::PARAM_INT);
        $stmt->execute();

        $produto = $stmt->fetch();
        return $produto ?: null;
    }
}
