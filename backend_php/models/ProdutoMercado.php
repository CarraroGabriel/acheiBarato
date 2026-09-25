<?php

require_once __DIR__ . '/../config/Database.php';

class ProdutoMercado
{
    private PDO $conexao;

    public function __construct()
    {
        $database = new Database();
        $this->conexao = $database->conectar();
    }

    public function listar(?int $idMercado = null): array
    {
        $sql = 'SELECT pm.id_produto_mercado, pm.id_produto, pm.id_mercado,
                       p.nm_produto, p.nm_marca, p.ds_categoria, p.ds_foto_produto,
                       m.nm_mercado,
                       pm.nu_valor, pm.nu_qtde, pm.fl_promocao, pm.fl_disponivel,
                       pm.dt_atualizacao
                FROM tb_produto_mercado pm
                INNER JOIN tb_produto p ON p.id_produto = pm.id_produto
                INNER JOIN tb_mercado m ON m.id_mercado = pm.id_mercado';

        if ($idMercado !== null) {
            $sql .= ' WHERE pm.id_mercado = :id_mercado';
        }

        $sql .= ' ORDER BY p.nm_produto';

        $stmt = $this->conexao->prepare($sql);

        if ($idMercado !== null) {
            $stmt->bindValue(':id_mercado', $idMercado, PDO::PARAM_INT);
        }

        $stmt->execute();
        return $stmt->fetchAll();
    }

    public function consultarPorId(int $idProdutoMercado): ?array
    {
        $sql = 'SELECT pm.id_produto_mercado, pm.id_produto, pm.id_mercado,
                       p.nm_produto, p.nm_marca, p.ds_categoria, p.ds_foto_produto,
                       m.nm_mercado,
                       pm.nu_valor, pm.nu_qtde, pm.fl_promocao, pm.fl_disponivel,
                       pm.dt_atualizacao
                FROM tb_produto_mercado pm
                INNER JOIN tb_produto p ON p.id_produto = pm.id_produto
                INNER JOIN tb_mercado m ON m.id_mercado = pm.id_mercado
                WHERE pm.id_produto_mercado = :id_produto_mercado';

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':id_produto_mercado', $idProdutoMercado, PDO::PARAM_INT);
        $stmt->execute();

        $produtoMercado = $stmt->fetch();
        return $produtoMercado ?: null;
    }

    public function registrar(array $dados): array
    {
        // Reutiliza o produto cadastrado ou cria um novo, para nao duplicar.
        $idProduto = $this->buscarOuCriarProduto($dados);

        if ($this->jaRegistrado($idProduto, $dados['id_mercado'])) {
            throw new RuntimeException('Este produto ja esta registrado neste mercado.');
        }

        $sql = 'INSERT INTO tb_produto_mercado
                    (id_produto, id_mercado, nu_valor, nu_qtde, fl_promocao, fl_disponivel)
                VALUES
                    (:id_produto, :id_mercado, :nu_valor, :nu_qtde, :fl_promocao, :fl_disponivel)
                RETURNING id_produto_mercado, id_produto, id_mercado,
                          nu_valor, nu_qtde, fl_promocao, fl_disponivel, dt_atualizacao';

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':id_produto', $idProduto, PDO::PARAM_INT);
        $stmt->bindValue(':id_mercado', $dados['id_mercado'], PDO::PARAM_INT);
        $stmt->bindValue(':nu_valor', $dados['nu_valor']);
        $stmt->bindValue(':nu_qtde', $dados['nu_qtde'], PDO::PARAM_INT);
        $stmt->bindValue(':fl_promocao', $dados['fl_promocao'], PDO::PARAM_BOOL);
        $stmt->bindValue(':fl_disponivel', $dados['fl_disponivel'], PDO::PARAM_BOOL);
        $stmt->execute();

        return $stmt->fetch();
    }

    public function alterar(int $idProdutoMercado, array $dados): ?array
    {
        $sql = 'UPDATE tb_produto_mercado
                SET nu_valor = :nu_valor,
                    nu_qtde = :nu_qtde,
                    fl_promocao = :fl_promocao,
                    fl_disponivel = :fl_disponivel,
                    dt_atualizacao = CURRENT_TIMESTAMP
                WHERE id_produto_mercado = :id_produto_mercado
                RETURNING id_produto_mercado, id_produto, id_mercado,
                          nu_valor, nu_qtde, fl_promocao, fl_disponivel, dt_atualizacao';

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':nu_valor', $dados['nu_valor']);
        $stmt->bindValue(':nu_qtde', $dados['nu_qtde'], PDO::PARAM_INT);
        $stmt->bindValue(':fl_promocao', $dados['fl_promocao'], PDO::PARAM_BOOL);
        $stmt->bindValue(':fl_disponivel', $dados['fl_disponivel'], PDO::PARAM_BOOL);
        $stmt->bindValue(':id_produto_mercado', $idProdutoMercado, PDO::PARAM_INT);
        $stmt->execute();

        $produtoMercado = $stmt->fetch();
        return $produtoMercado ?: null;
    }

    public function excluir(int $idProdutoMercado): bool
    {
        $sql = 'DELETE FROM tb_produto_mercado WHERE id_produto_mercado = :id_produto_mercado';
        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':id_produto_mercado', $idProdutoMercado, PDO::PARAM_INT);
        $stmt->execute();
        return $stmt->rowCount() > 0;
    }

    public function listarPromocoes(?int $idMercado = null, ?int $idUsuario = null): array
    {
        $sql = 'SELECT pm.id_produto_mercado, pm.id_produto, pm.id_mercado,
                       p.nm_produto, p.nm_marca, p.ds_categoria, p.ds_foto_produto,
                       m.nm_mercado,
                       pm.nu_valor, pm.nu_qtde, pm.fl_promocao, pm.fl_disponivel,
                       pm.dt_atualizacao
                FROM tb_produto_mercado pm
                INNER JOIN tb_produto p ON p.id_produto = pm.id_produto
                INNER JOIN tb_mercado m ON m.id_mercado = pm.id_mercado
                WHERE pm.fl_promocao = TRUE
                  AND pm.fl_disponivel = TRUE';

        if ($idMercado !== null) {
            $sql .= ' AND pm.id_mercado = :id_mercado';
        }

        if ($idUsuario !== null) {
            $sql .= ' AND pm.id_mercado IN (
                          SELECT id_mercado
                          FROM tb_mercado_favorito
                          WHERE id_usuario = :id_usuario
                      )';
        }

        $sql .= ' ORDER BY pm.dt_atualizacao DESC';

        $stmt = $this->conexao->prepare($sql);

        if ($idMercado !== null) {
            $stmt->bindValue(':id_mercado', $idMercado, PDO::PARAM_INT);
        }

        if ($idUsuario !== null) {
            $stmt->bindValue(':id_usuario', $idUsuario, PDO::PARAM_INT);
        }

        $stmt->execute();
        return $stmt->fetchAll();
    }

    private function buscarOuCriarProduto(array $dados): int
    {
        $sql = 'SELECT id_produto
                FROM tb_produto
                WHERE nm_produto = :nm_produto
                  AND nm_marca = :nm_marca
                  AND ds_categoria = :ds_categoria';

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':nm_produto', $dados['nm_produto']);
        $stmt->bindValue(':nm_marca', $dados['nm_marca']);
        $stmt->bindValue(':ds_categoria', $dados['ds_categoria']);
        $stmt->execute();

        $produto = $stmt->fetch();

        if ($produto) {
            return (int) $produto['id_produto'];
        }

        $sql = 'INSERT INTO tb_produto
                    (nm_produto, nm_marca, ds_categoria, ds_foto_produto)
                VALUES
                    (:nm_produto, :nm_marca, :ds_categoria, :ds_foto_produto)
                RETURNING id_produto';

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':nm_produto', $dados['nm_produto']);
        $stmt->bindValue(':nm_marca', $dados['nm_marca']);
        $stmt->bindValue(':ds_categoria', $dados['ds_categoria']);
        $stmt->bindValue(':ds_foto_produto', $dados['ds_foto_produto']);
        $stmt->execute();

        return (int) $stmt->fetch()['id_produto'];
    }

    private function jaRegistrado(int $idProduto, int $idMercado): bool
    {
        $sql = 'SELECT 1
                FROM tb_produto_mercado
                WHERE id_produto = :id_produto
                  AND id_mercado = :id_mercado';

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':id_produto', $idProduto, PDO::PARAM_INT);
        $stmt->bindValue(':id_mercado', $idMercado, PDO::PARAM_INT);
        $stmt->execute();

        return (bool) $stmt->fetch();
    }
}
