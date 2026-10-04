<?php

require_once __DIR__ . '/../config/Database.php';
require_once __DIR__ . '/../helpers/Busca.php';

class ProdutoMercado
{
    // produto disponível com até 5 unidades está com estoque baixo.
    public const LIMITE_ESTOQUE_BAIXO = 5;

    public const SQL_PROMOCAO_ATIVA =
        '(pm.fl_promocao AND (pm.dt_fim_promocao IS NULL OR pm.dt_fim_promocao > NOW()))';

    // Preço que o cliente paga: com desconto só enquanto a promoção estiver ativa.
    public const SQL_VALOR_FINAL =
        '(CASE WHEN ' . self::SQL_PROMOCAO_ATIVA . '
              THEN ROUND(pm.nu_valor * (1 - pm.nu_desconto / 100.0), 2)
              ELSE pm.nu_valor
         END)';

    public const SQL_CAMPOS_PROMOCAO =
        self::SQL_PROMOCAO_ATIVA . ' AS fl_promocao,
        COALESCE(pm.fl_promocao AND pm.dt_fim_promocao <= NOW(), FALSE) AS fl_promocao_expirada,
        pm.nu_desconto,
        ' . self::SQL_VALOR_FINAL . ' AS nu_valor_final,
        TO_CHAR(pm.dt_fim_promocao AT TIME ZONE \'UTC\', \'YYYY-MM-DD"T"HH24:MI:SS"Z"\') AS dt_fim_promocao,
        CASE WHEN ' . self::SQL_PROMOCAO_ATIVA . ' AND pm.dt_fim_promocao IS NOT NULL
             THEN FLOOR(EXTRACT(EPOCH FROM pm.dt_fim_promocao - NOW()))::INTEGER
        END AS nu_segundos_restantes';

    private const SELECT_BASE = 'SELECT pm.id_produto_mercado, pm.id_item_produto, pm.id_mercado,
                       ip.id_produto, ip.nm_produto, ip.nm_tipo, ip.nm_marca,
                       ip.id_categoria, ip.nm_categoria AS ds_categoria, ip.ds_foto_produto,
                       ip.nu_medida, ip.sg_unidade, ip.ds_item_produto,
                       m.nm_mercado,
                       pm.nu_valor, pm.nu_qtde, pm.fl_disponivel,
                       (pm.fl_disponivel AND pm.nu_qtde <= ' . self::LIMITE_ESTOQUE_BAIXO . ') AS fl_estoque_baixo,
                       pm.dt_atualizacao, '
                       . self::SQL_CAMPOS_PROMOCAO . '
                FROM tb_produto_mercado pm
                INNER JOIN vw_item_produto ip ON ip.id_item_produto = pm.id_item_produto
                INNER JOIN tb_mercado m ON m.id_mercado = pm.id_mercado';

    private PDO $conexao;

    public function __construct()
    {
        $database = new Database();
        $this->conexao = $database->conectar();
    }

    public function listar(?int $idMercado = null): array
    {
        $sql = self::SELECT_BASE;

        if ($idMercado !== null) {
            $sql .= ' WHERE pm.id_mercado = :id_mercado';
        }

        $sql .= ' ORDER BY ' . self::SQL_PROMOCAO_ATIVA . ' DESC,
                  ip.nm_categoria, ip.ds_item_produto, ip.nm_marca';

        $stmt = $this->conexao->prepare($sql);

        if ($idMercado !== null) {
            $stmt->bindValue(':id_mercado', $idMercado, PDO::PARAM_INT);
        }

        $stmt->execute();
        return $stmt->fetchAll();
    }

    public function consultarPorId(int $idProdutoMercado): ?array
    {
        $sql = self::SELECT_BASE . ' WHERE pm.id_produto_mercado = :id_produto_mercado';

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':id_produto_mercado', $idProdutoMercado, PDO::PARAM_INT);
        $stmt->execute();

        $produtoMercado = $stmt->fetch();
        return $produtoMercado ?: null;
    }

    public function registrar(array $dados): array
    {
        $this->conexao->beginTransaction();

        try {
            $idProduto = $dados['id_produto'] !== null
                ? $this->validarProduto($dados['id_produto'])
                : $this->buscarOuCriarProduto($dados['nm_produto'], $dados['id_categoria']);

            $idTipo = $dados['id_tipo'] !== null
                ? $this->validarTipo($dados['id_tipo'], $idProduto)
                : $this->buscarOuCriarTipo($idProduto, $dados['nm_tipo']);

            $idMarca = $dados['id_marca'] !== null
                ? $this->validarMarca($dados['id_marca'])
                : $this->buscarOuCriarMarca($dados['nm_marca']);

            $this->vincularMarcaProduto($idProduto, $idMarca);
            $this->validarUnidade($dados['id_unidade']);

            $idItem = $this->buscarOuCriarItem($idTipo, $idMarca, $dados['nu_medida'], $dados['id_unidade']);

            if ($this->jaRegistrado($idItem, $dados['id_mercado'])) {
                throw new RuntimeException('Este produto já está registrado neste mercado.');
            }

            $sql = 'INSERT INTO tb_produto_mercado
                        (id_item_produto, id_mercado, nu_valor, nu_qtde, fl_promocao, fl_disponivel, dt_atualizacao)
                    VALUES
                        (:id_item_produto, :id_mercado, :nu_valor, :nu_qtde, :fl_promocao, :fl_disponivel, CURRENT_DATE)
                    RETURNING id_produto_mercado';

            $stmt = $this->conexao->prepare($sql);
            $stmt->bindValue(':id_item_produto', $idItem, PDO::PARAM_INT);
            $stmt->bindValue(':id_mercado', $dados['id_mercado'], PDO::PARAM_INT);
            $stmt->bindValue(':nu_valor', $dados['nu_valor']);
            $stmt->bindValue(':nu_qtde', $dados['nu_qtde'], PDO::PARAM_INT);
            $stmt->bindValue(':fl_promocao', $dados['fl_promocao'], PDO::PARAM_BOOL);
            $stmt->bindValue(':fl_disponivel', $dados['fl_disponivel'], PDO::PARAM_BOOL);
            $stmt->execute();

            $idProdutoMercado = (int) $stmt->fetch()['id_produto_mercado'];

            $this->conexao->commit();
        } catch (Throwable $e) {
            $this->conexao->rollBack();
            throw $e;
        }

        return $this->consultarPorId($idProdutoMercado);
    }

    public function alterar(int $idProdutoMercado, array $dados): ?array
    {
        $sql = 'UPDATE tb_produto_mercado
                SET nu_valor = :nu_valor,
                    nu_qtde = :nu_qtde,
                    fl_promocao = :fl_promocao,
                    fl_disponivel = :fl_disponivel,
                    dt_atualizacao = CURRENT_TIMESTAMP,
                    nu_desconto = :nu_desconto,
                    dt_fim_promocao = CAST(:dt_fim_promocao AS TIMESTAMPTZ)
                WHERE id_produto_mercado = :id_produto_mercado';

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':nu_valor', $dados['nu_valor']);
        $stmt->bindValue(':nu_qtde', $dados['nu_qtde'], PDO::PARAM_INT);
        $stmt->bindValue(':fl_promocao', $dados['fl_promocao'], PDO::PARAM_BOOL);
        $stmt->bindValue(':fl_disponivel', $dados['fl_disponivel'], PDO::PARAM_BOOL);
        $stmt->bindValue(':id_produto_mercado', $idProdutoMercado, PDO::PARAM_INT);
        $stmt->bindValue(':nu_desconto', $dados['nu_desconto'], PDO::PARAM_INT);
        $stmt->bindValue(':dt_fim_promocao', $dados['dt_fim_promocao']);
        $stmt->execute();

        if ($stmt->rowCount() === 0) {
            return null;
        }

        return $this->consultarPorId($idProdutoMercado);
    }

    public function excluir(int $idProdutoMercado): bool
    {
        $sql = 'DELETE FROM tb_produto_mercado WHERE id_produto_mercado = :id_produto_mercado';
        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':id_produto_mercado', $idProdutoMercado, PDO::PARAM_INT);
        $stmt->execute();
        return $stmt->rowCount() > 0;
    }

    public function buscarItens(array $filtros): array
    {
        $valorFinal = self::SQL_VALOR_FINAL;
        $promocaoAtiva = self::SQL_PROMOCAO_ATIVA;

        $where = ['pm.fl_disponivel = TRUE'];
        $having = [];
        $parametros = [];

        $palavras = Busca::palavras($filtros['busca'] ?? null);

        if ($palavras) {
            [$condicao, $parametrosBusca] = Busca::condicao(
                "ip.ds_item_produto || ' ' || ip.nm_marca",
                $palavras,
                'palavra'
            );
            $where[] = $condicao;
            $parametros += $parametrosBusca;
        }

        if ($filtros['id_categoria'] !== null) {
            $where[] = 'ip.id_categoria = :id_categoria';
            $parametros[':id_categoria'] = $filtros['id_categoria'];
        }

        if ($filtros['id_marca'] !== null) {
            $where[] = 'ip.id_marca = :id_marca';
            $parametros[':id_marca'] = $filtros['id_marca'];
        }

        if ($filtros['promocao'] === 'sim') {
            $having[] = "BOOL_OR({$promocaoAtiva})";
        } elseif ($filtros['promocao'] === 'nao') {
            $having[] = "NOT BOOL_OR({$promocaoAtiva})";
        }

        if ($filtros['preco_min'] !== null) {
            $having[] = "MIN({$valorFinal}) >= :preco_min";
            $parametros[':preco_min'] = $filtros['preco_min'];
        }

        if ($filtros['preco_max'] !== null) {
            $having[] = "MIN({$valorFinal}) <= :preco_max";
            $parametros[':preco_max'] = $filtros['preco_max'];
        }

        $ordem = match ($filtros['ordem']) {
            'menor_preco' => 'nu_menor_preco ASC, ip.ds_item_produto',
            'maior_preco' => 'nu_menor_preco DESC, ip.ds_item_produto',
            'nome' => 'ip.ds_item_produto, ip.nm_marca',
            default => $this->ordemRelevancia($palavras, $parametros),
        };

        $sql = "SELECT ip.id_item_produto, ip.id_produto, ip.ds_item_produto, ip.nm_marca,
                       ip.nm_categoria AS ds_categoria, ip.ds_foto_produto,
                       MIN({$valorFinal}) AS nu_menor_preco,
                       COUNT(DISTINCT pm.id_mercado) AS qt_mercados,
                       BOOL_OR({$promocaoAtiva}) AS fl_promocao
                FROM vw_item_produto ip
                INNER JOIN tb_produto_mercado pm ON pm.id_item_produto = ip.id_item_produto
                WHERE " . implode(' AND ', $where) . '
                GROUP BY ip.id_item_produto, ip.id_produto, ip.ds_item_produto, ip.nm_marca,
                         ip.nm_categoria, ip.ds_foto_produto'
                . ($having ? ' HAVING ' . implode(' AND ', $having) : '') . "
                ORDER BY {$ordem}
                LIMIT 100";

        $stmt = $this->conexao->prepare($sql);
        $stmt->execute($parametros);
        return $stmt->fetchAll();
    }

    // Relevância simples: itens que começam com a primeira palavra buscada,
    // depois os vendidos em mais mercados, depois por nome.
    private function ordemRelevancia(array $palavras, array &$parametros): string
    {
        if (!$palavras) {
            return 'qt_mercados DESC, ip.ds_item_produto';
        }

        $parametros[':inicio'] = Busca::escaparLike($palavras[0]);

        return '(' . Busca::semAcento('ip.ds_item_produto') . " LIKE "
            . Busca::semAcento(':inicio') . " || '%') DESC,
                qt_mercados DESC, ip.ds_item_produto";
    }

    public function listarPromocoes(?int $idMercado = null, ?int $idUsuario = null): array
    {
        $sql = self::SELECT_BASE . '
                WHERE ' . self::SQL_PROMOCAO_ATIVA . '
                  AND pm.fl_disponivel = TRUE';

        if ($idMercado !== null) {
            $sql .= ' AND pm.id_mercado = :id_mercado';
        }

        $ordem = 'pm.dt_atualizacao DESC';

        if ($idUsuario !== null) {
            $ordem = '(pm.id_mercado IN (
                          SELECT id_mercado
                          FROM tb_mercado_favorito
                          WHERE id_usuario = :id_usuario
                      )) DESC, ' . $ordem;
        }

        $sql .= ' ORDER BY ' . $ordem;

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

    private function buscarOuCriarProduto(string $nome, ?int $idCategoria): int
    {
        if ($idCategoria !== null) {
            $this->exigirRegistro(
                'SELECT 1 FROM tb_categoria WHERE id_categoria = :id',
                [':id' => $idCategoria],
                'Categoria não encontrada.'
            );
        }

        return $this->buscarOuCriar(
            'SELECT id_produto AS id FROM tb_produto WHERE UPPER(nm_produto) = UPPER(:nome)',
            "INSERT INTO tb_produto (nm_produto, id_categoria)
             VALUES (UPPER(:nome), COALESCE(
                 CAST(:id_categoria AS INTEGER),
                 (SELECT id_categoria FROM tb_categoria WHERE nm_categoria = 'OUTRO')
             ))
             RETURNING id_produto AS id",
            [':nome' => $nome],
            [':id_categoria' => $idCategoria]
        );
    }

    private function buscarOuCriarTipo(int $idProduto, string $nome): int
    {
        return $this->buscarOuCriar(
            'SELECT id_tipo AS id FROM tb_tipo_produto
             WHERE id_produto = :id_produto AND UPPER(nm_tipo) = UPPER(:nome)',
            'INSERT INTO tb_tipo_produto (id_produto, nm_tipo)
             VALUES (:id_produto, UPPER(:nome))
             RETURNING id_tipo AS id',
            [':id_produto' => $idProduto, ':nome' => $nome]
        );
    }

    private function buscarOuCriarMarca(string $nome): int
    {
        return $this->buscarOuCriar(
            'SELECT id_marca AS id FROM tb_marca WHERE UPPER(nm_marca) = UPPER(:nome)',
            'INSERT INTO tb_marca (nm_marca) VALUES (UPPER(:nome)) RETURNING id_marca AS id',
            [':nome' => $nome]
        );
    }

    private function buscarOuCriarItem(int $idTipo, int $idMarca, float $medida, int $idUnidade): int
    {
        return $this->buscarOuCriar(
            'SELECT id_item_produto AS id FROM tb_item_produto
             WHERE id_tipo = :id_tipo AND id_marca = :id_marca
               AND nu_medida = :nu_medida AND id_unidade = :id_unidade',
            'INSERT INTO tb_item_produto (id_tipo, id_marca, nu_medida, id_unidade)
             VALUES (:id_tipo, :id_marca, :nu_medida, :id_unidade)
             RETURNING id_item_produto AS id',
            [
                ':id_tipo'    => $idTipo,
                ':id_marca'   => $idMarca,
                ':nu_medida'  => (string) $medida,
                ':id_unidade' => $idUnidade,
            ]
        );
    }
    
    private function buscarOuCriar(
        string $sqlBusca,
        string $sqlInsercao,
        array $parametros,
        array $parametrosInsercao = []
    ): int {
        $stmt = $this->conexao->prepare($sqlBusca);
        $stmt->execute($parametros);
        $registro = $stmt->fetch();

        if ($registro) {
            return (int) $registro['id'];
        }

        $stmt = $this->conexao->prepare($sqlInsercao);
        $stmt->execute(array_merge($parametros, $parametrosInsercao));
        return (int) $stmt->fetch()['id'];
    }

    private function vincularMarcaProduto(int $idProduto, int $idMarca): void
    {
        $stmt = $this->conexao->prepare(
            'INSERT INTO tb_marca_produto (id_produto, id_marca)
             VALUES (:id_produto, :id_marca)
             ON CONFLICT (id_produto, id_marca) DO NOTHING'
        );
        $stmt->execute([':id_produto' => $idProduto, ':id_marca' => $idMarca]);
    }

    private function validarProduto(int $idProduto): int
    {
        $this->exigirRegistro(
            'SELECT 1 FROM tb_produto WHERE id_produto = :id',
            [':id' => $idProduto],
            'Produto não encontrado.'
        );
        return $idProduto;
    }

    private function validarTipo(int $idTipo, int $idProduto): int
    {
        $this->exigirRegistro(
            'SELECT 1 FROM tb_tipo_produto WHERE id_tipo = :id AND id_produto = :id_produto',
            [':id' => $idTipo, ':id_produto' => $idProduto],
            'Tipo não encontrado para este produto.'
        );
        return $idTipo;
    }

    private function validarMarca(int $idMarca): int
    {
        $this->exigirRegistro(
            'SELECT 1 FROM tb_marca WHERE id_marca = :id',
            [':id' => $idMarca],
            'Marca não encontrada.'
        );
        return $idMarca;
    }

    private function validarUnidade(int $idUnidade): void
    {
        $this->exigirRegistro(
            'SELECT 1 FROM tb_unidade_medida WHERE id_unidade = :id',
            [':id' => $idUnidade],
            'Unidade de medida não encontrada.'
        );
    }

    private function exigirRegistro(string $sql, array $parametros, string $mensagemErro): void
    {
        $stmt = $this->conexao->prepare($sql);
        $stmt->execute($parametros);

        if (!$stmt->fetch()) {
            throw new InvalidArgumentException($mensagemErro);
        }
    }

    private function jaRegistrado(int $idItemProduto, int $idMercado): bool
    {
        $sql = 'SELECT 1
                FROM tb_produto_mercado
                WHERE id_item_produto = :id_item_produto
                  AND id_mercado = :id_mercado';

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':id_item_produto', $idItemProduto, PDO::PARAM_INT);
        $stmt->bindValue(':id_mercado', $idMercado, PDO::PARAM_INT);
        $stmt->execute();

        return (bool) $stmt->fetch();
    }
}
