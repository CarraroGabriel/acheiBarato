<?php

require_once __DIR__ . '/../config/Database.php';

class Notificacao
{
    private const LIMITE_LISTA = 50;
    private const DIAS_HISTORICO = 30;

    private PDO $conexao;

    public function __construct()
    {
        $database = new Database();
        $this->conexao = $database->conectar();
    }

    public function criarPromocao(array $oferta, string $titulo, string $mensagem): int
    {
        $sql = "INSERT INTO tb_notificacao
                    (id_usuario, tp_notificacao, id_produto_mercado, ds_titulo, ds_mensagem)
                SELECT u.id_usuario,
                       CASE WHEN EXISTS (SELECT 1 FROM tb_produto_favorito pf
                                          WHERE pf.id_usuario = u.id_usuario
                                            AND pf.id_item_produto = :id_item_tipo)
                            THEN 'PROMOCAO_PRODUTO_FAVORITO'
                            ELSE 'PROMOCAO_MERCADO_FAVORITO'
                       END,
                       :id_produto_mercado, :titulo, :mensagem
                FROM tb_usuario u
                WHERE EXISTS (SELECT 1 FROM tb_mercado_favorito mf
                               WHERE mf.id_usuario = u.id_usuario
                                 AND mf.id_mercado = :id_mercado)
                   OR EXISTS (SELECT 1 FROM tb_produto_favorito pf
                               WHERE pf.id_usuario = u.id_usuario
                                 AND pf.id_item_produto = :id_item_filtro)";

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':id_item_tipo', (int) $oferta['id_item_produto'], PDO::PARAM_INT);
        $stmt->bindValue(':id_item_filtro', (int) $oferta['id_item_produto'], PDO::PARAM_INT);
        $stmt->bindValue(':id_mercado', (int) $oferta['id_mercado'], PDO::PARAM_INT);
        $stmt->bindValue(':id_produto_mercado', (int) $oferta['id_produto_mercado'], PDO::PARAM_INT);
        $stmt->bindValue(':titulo', $titulo);
        $stmt->bindValue(':mensagem', $mensagem);
        $stmt->execute();

        return $stmt->rowCount();
    }

    public function criarParaMercado(
        int $idMercado,
        string $tipo,
        int $idProdutoMercado,
        string $titulo,
        string $mensagem
    ): void {
        $sql = 'INSERT INTO tb_notificacao
                    (id_mercado, tp_notificacao, id_produto_mercado, ds_titulo, ds_mensagem)
                VALUES (:id_mercado, :tipo, :id_produto_mercado, :titulo, :mensagem)';

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':id_mercado', $idMercado, PDO::PARAM_INT);
        $stmt->bindValue(':tipo', $tipo);
        $stmt->bindValue(':id_produto_mercado', $idProdutoMercado, PDO::PARAM_INT);
        $stmt->bindValue(':titulo', $titulo);
        $stmt->bindValue(':mensagem', $mensagem);
        $stmt->execute();
    }

    public function listar(string $campo, int $id): array
    {
        $this->validarCampo($campo);
        $this->removerAntigas($campo, $id);

        $sql = "SELECT n.id_notificacao, n.tp_notificacao, n.ds_titulo, n.ds_mensagem,
                       n.fl_lida, n.id_produto_mercado, pm.id_item_produto,
                       TO_CHAR(n.dt_criacao AT TIME ZONE 'UTC', 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"') AS dt_criacao
                FROM tb_notificacao n
                LEFT JOIN tb_produto_mercado pm ON pm.id_produto_mercado = n.id_produto_mercado
                WHERE n.{$campo} = :id
                ORDER BY n.dt_criacao DESC, n.id_notificacao DESC
                LIMIT " . self::LIMITE_LISTA;

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':id', $id, PDO::PARAM_INT);
        $stmt->execute();

        $notificacoes = array_map(fn(array $n) => [
            'id_notificacao'     => (int) $n['id_notificacao'],
            'tp_notificacao'     => $n['tp_notificacao'],
            'ds_titulo'          => $n['ds_titulo'],
            'ds_mensagem'        => $n['ds_mensagem'],
            'fl_lida'            => in_array(strtolower((string) $n['fl_lida']), ['t', 'true', '1'], true),
            'id_produto_mercado' => $n['id_produto_mercado'] === null ? null : (int) $n['id_produto_mercado'],
            'id_item_produto'    => $n['id_item_produto'] === null ? null : (int) $n['id_item_produto'],
            'dt_criacao'         => $n['dt_criacao'],
        ], $stmt->fetchAll());

        return [
            'nao_lidas' => $this->contarNaoLidas($campo, $id),
            'notificacoes' => $notificacoes,
        ];
    }

    public function contarNaoLidas(string $campo, int $id): int
    {
        $this->validarCampo($campo);

        $stmt = $this->conexao->prepare(
            "SELECT COUNT(*) FROM tb_notificacao WHERE {$campo} = :id AND fl_lida = FALSE"
        );
        $stmt->bindValue(':id', $id, PDO::PARAM_INT);
        $stmt->execute();

        return (int) $stmt->fetchColumn();
    }

    public function marcarTodasLidas(string $campo, int $id): int
    {
        $this->validarCampo($campo);

        $stmt = $this->conexao->prepare(
            "UPDATE tb_notificacao SET fl_lida = TRUE WHERE {$campo} = :id AND fl_lida = FALSE"
        );
        $stmt->bindValue(':id', $id, PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->rowCount();
    }

    public function excluir(string $campo, int $id, int $idNotificacao): bool
    {
        $this->validarCampo($campo);

        $stmt = $this->conexao->prepare(
            "DELETE FROM tb_notificacao WHERE id_notificacao = :id_notificacao AND {$campo} = :id"
        );
        $stmt->bindValue(':id_notificacao', $idNotificacao, PDO::PARAM_INT);
        $stmt->bindValue(':id', $id, PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->rowCount() > 0;
    }

    public function excluirTodas(string $campo, int $id): int
    {
        $this->validarCampo($campo);

        $stmt = $this->conexao->prepare("DELETE FROM tb_notificacao WHERE {$campo} = :id");
        $stmt->bindValue(':id', $id, PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->rowCount();
    }

    private function removerAntigas(string $campo, int $id): void
    {
        $stmt = $this->conexao->prepare(
            "DELETE FROM tb_notificacao
             WHERE {$campo} = :id
               AND dt_criacao < NOW() - INTERVAL '" . self::DIAS_HISTORICO . " days'"
        );
        $stmt->bindValue(':id', $id, PDO::PARAM_INT);
        $stmt->execute();
    }

    private function validarCampo(string $campo): void
    {
        if (!in_array($campo, ['id_usuario', 'id_mercado'], true)) {
            throw new InvalidArgumentException('Destinatário inválido.');
        }
    }
}
