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
        $sql = 'SELECT p.id_produto, p.nm_produto, p.id_categoria, c.nm_categoria
                FROM tb_produto p
                INNER JOIN tb_categoria c ON c.id_categoria = p.id_categoria
                ORDER BY p.nm_produto';

        $stmt = $this->conexao->prepare($sql);
        $stmt->execute();
        return $stmt->fetchAll();
    }

    // Produto com os tipos e as marcas sugeridas, usados no cadastro do mercado.
    public function consultarPorId(int $idProduto): ?array
    {
        $sql = 'SELECT p.id_produto, p.nm_produto, p.id_categoria, c.nm_categoria
                FROM tb_produto p
                INNER JOIN tb_categoria c ON c.id_categoria = p.id_categoria
                WHERE p.id_produto = :id_produto';

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':id_produto', $idProduto, PDO::PARAM_INT);
        $stmt->execute();

        $produto = $stmt->fetch();

        if (!$produto) {
            return null;
        }

        $stmt = $this->conexao->prepare(
            'SELECT id_tipo, nm_tipo
             FROM tb_tipo_produto
             WHERE id_produto = :id_produto
             ORDER BY nm_tipo'
        );
        $stmt->bindValue(':id_produto', $idProduto, PDO::PARAM_INT);
        $stmt->execute();
        $produto['tipos'] = $stmt->fetchAll();

        $stmt = $this->conexao->prepare(
            'SELECT m.id_marca, m.nm_marca
             FROM tb_marca_produto mp
             INNER JOIN tb_marca m ON m.id_marca = mp.id_marca
             WHERE mp.id_produto = :id_produto
             ORDER BY m.nm_marca'
        );
        $stmt->bindValue(':id_produto', $idProduto, PDO::PARAM_INT);
        $stmt->execute();
        $produto['marcas'] = $stmt->fetchAll();

        return $produto;
    }
}
