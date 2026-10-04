<?php

require_once __DIR__ . '/../config/Database.php';
require_once __DIR__ . '/ProdutoMercado.php';

class Favorito
{
    private PDO $conexao;

    public function __construct()
    {
        $database = new Database();
        $this->conexao = $database->conectar();
    }

    public function listarMercados(int $idUsuario): array
    {
        $sql = 'SELECT m.id_mercado, m.nm_mercado, m.nm_endereco, m.ds_foto_mercado,
                       m.fl_motoboy, m.nu_taxa_entrega, m.nu_avg_nota, m.nul_avaliacoes,
                       m.nu_latitude, m.nu_longitude,
                       (SELECT COUNT(*)
                          FROM tb_produto_mercado pm
                         WHERE pm.id_mercado = m.id_mercado
                           AND ' . ProdutoMercado::SQL_PROMOCAO_ATIVA . '
                           AND pm.fl_disponivel = TRUE) AS qt_promocoes
                FROM tb_mercado m
                WHERE EXISTS (
                    SELECT 1
                      FROM tb_mercado_favorito mf
                     WHERE mf.id_mercado = m.id_mercado
                       AND mf.id_usuario = :id_usuario
                )
                ORDER BY m.nm_mercado';

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':id_usuario', $idUsuario, PDO::PARAM_INT);
        $stmt->execute();
        $mercados = $stmt->fetchAll();

        $horarios = $this->horariosPorMercado(array_column($mercados, 'id_mercado'));
        $agora = new DateTime('now', new DateTimeZone('America/Sao_Paulo'));

        $resultado = [];
        foreach ($mercados as $m) {
            $id = (int) $m['id_mercado'];
            $faixas = $horarios[$id] ?? [];
            $situacao = $this->situacaoHorario($faixas, $agora);

            $resultado[] = [
                'id_mercado'      => $id,
                'nm_mercado'      => $m['nm_mercado'],
                'nm_endereco'     => $m['nm_endereco'],
                'ds_foto_mercado' => $m['ds_foto_mercado'],
                'fl_motoboy'      => $this->paraBool($m['fl_motoboy']),
                'nu_taxa_entrega' => (float) $m['nu_taxa_entrega'],
                'nu_avg_nota'     => (float) $m['nu_avg_nota'],
                'nul_avaliacoes'  => (int) $m['nul_avaliacoes'],
                'nu_latitude'     => (float) $m['nu_latitude'],
                'nu_longitude'    => (float) $m['nu_longitude'],
                'qt_promocoes'    => (int) $m['qt_promocoes'],
                'horario_hoje'    => $situacao['horario_hoje'],
                'aberto_agora'    => $situacao['aberto_agora'],
                'horarios'        => $faixas,
            ];
        }

        return $resultado;
    }

    public function listarProdutos(int $idUsuario): array
    {
        $sql = 'SELECT ip.id_item_produto, ip.id_produto, ip.nm_produto, ip.nm_marca,
                       ip.nm_categoria AS ds_categoria, ip.ds_foto_produto, ip.ds_item_produto,
                       pm.id_produto_mercado, pm.nu_valor, pm.nu_qtde,
                       pm.fl_disponivel, pm.dt_atualizacao,
                       ' . ProdutoMercado::SQL_CAMPOS_PROMOCAO . ',
                       m.id_mercado, m.nm_mercado, m.nu_latitude, m.nu_longitude, m.fl_motoboy
                FROM tb_produto_favorito pf
                INNER JOIN vw_item_produto ip ON ip.id_item_produto = pf.id_item_produto
                LEFT JOIN tb_produto_mercado pm ON pm.id_item_produto = ip.id_item_produto
                LEFT JOIN tb_mercado m ON m.id_mercado = pm.id_mercado
                WHERE pf.id_usuario = :id_usuario
                ORDER BY ip.ds_item_produto, ip.nm_marca, ip.id_item_produto, pm.nu_valor, m.nm_mercado';

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':id_usuario', $idUsuario, PDO::PARAM_INT);
        $stmt->execute();

        $produtos = [];

        foreach ($stmt->fetchAll() as $linha) {
            $idItem = (int) $linha['id_item_produto'];

            if (!isset($produtos[$idItem])) {
                $produtos[$idItem] = [
                    'id_item_produto' => $idItem,
                    'id_produto'      => (int) $linha['id_produto'],
                    'nm_produto'      => $linha['nm_produto'],
                    'ds_item_produto' => $linha['ds_item_produto'],
                    'nm_marca'        => $linha['nm_marca'],
                    'ds_categoria'    => $linha['ds_categoria'],
                    'ds_foto_produto' => $linha['ds_foto_produto'],
                    'mercados'        => [],
                ];
            }

            if ($linha['id_mercado'] === null) {
                continue;
            }

            $produtos[$idItem]['mercados'][] = [
                'id_produto_mercado' => (int) $linha['id_produto_mercado'],
                'id_mercado'         => (int) $linha['id_mercado'],
                'nm_mercado'         => $linha['nm_mercado'],
                'nu_valor'           => (float) $linha['nu_valor'],
                'nu_desconto'        => (int) $linha['nu_desconto'],
                'nu_valor_final'     => (float) $linha['nu_valor_final'],
                'nu_qtde'            => (int) $linha['nu_qtde'],
                'fl_promocao'        => $this->paraBool($linha['fl_promocao']),
                'nu_segundos_restantes' => $linha['nu_segundos_restantes'] === null
                    ? null
                    : (int) $linha['nu_segundos_restantes'],
                'fl_disponivel'      => $this->paraBool($linha['fl_disponivel']),
                'fl_motoboy'         => $this->paraBool($linha['fl_motoboy']),
                'dt_atualizacao'     => $linha['dt_atualizacao'],
                'nu_latitude'        => (float) $linha['nu_latitude'],
                'nu_longitude'       => (float) $linha['nu_longitude'],
                'melhor_preco'       => false,
            ];
        }

        foreach ($produtos as &$produto) {
            $produto['mercados'] = ProdutoMercado::marcarMelhorPreco($produto['mercados']);
        }
        unset($produto);

        return array_values($produtos);
    }

    private function horariosPorMercado(array $idsMercado): array
    {
        if (count($idsMercado) === 0) {
            return [];
        }

        $lista = implode(',', array_map('intval', $idsMercado)); 

        $sql = "SELECT id_mercado, nu_dia_semana, hr_abertura, hr_fechamento
                FROM tb_horario_mercado
                WHERE id_mercado IN ($lista)
                ORDER BY id_mercado, nu_dia_semana, hr_abertura";

        try {
            $linhas = $this->conexao->query($sql)->fetchAll();
        } catch (PDOException $e) {
            // 42P01 = tabela inexistente (migração de horários ainda não aplicada).
            if ($e->getCode() === '42P01') {
                return [];
            }
            throw $e;
        }

        $resultado = [];
        foreach ($linhas as $l) {
            $resultado[(int) $l['id_mercado']][] = [
                'nu_dia_semana' => (int) $l['nu_dia_semana'],
                'hr_abertura'   => substr((string) $l['hr_abertura'], 0, 5),
                'hr_fechamento' => substr((string) $l['hr_fechamento'], 0, 5),
            ];
        }

        return $resultado;
    }

    private function situacaoHorario(array $faixas, DateTime $agora): array
    {
        if (count($faixas) === 0) {
            return ['horario_hoje' => null, 'aberto_agora' => null];
        }

        $dia = (int) $agora->format('w');
        $hora = $agora->format('H:i');
        $hoje = array_values(array_filter($faixas, fn(array $f) => $f['nu_dia_semana'] === $dia));

        if (count($hoje) === 0) {
            return ['horario_hoje' => null, 'aberto_agora' => false];
        }

        $aberto = false;
        $textos = [];
        foreach ($hoje as $f) {
            $textos[] = $f['hr_abertura'] . ' - ' . $f['hr_fechamento'];
            if ($hora >= $f['hr_abertura'] && $hora < $f['hr_fechamento']) {
                $aberto = true;
            }
        }

        return ['horario_hoje' => implode(' / ', $textos), 'aberto_agora' => $aberto];
    }

    private function paraBool(mixed $valor): bool
    {
        if (is_bool($valor)) {
            return $valor;
        }
        return in_array(strtolower((string) $valor), ['t', 'true', '1'], true);
    }
}
