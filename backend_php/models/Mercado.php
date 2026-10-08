<?php

require_once __DIR__ . '/../config/Database.php';
require_once __DIR__ . '/ProdutoMercado.php';
require_once __DIR__ . '/../helpers/Busca.php';

class Mercado
{
    private PDO $conexao;

    public function __construct()
    {
        $database = new Database();
        $this->conexao = $database->conectar();
    }

    public function listar(?string $busca = null, ?bool $motoboy = null): array
    {
        $where = [];
        $parametros = [];

        $palavras = Busca::palavras($busca);

        if ($palavras) {
            [$condicao, $parametrosBusca] = Busca::condicao('m.nm_mercado', $palavras, 'palavra');
            $where[] = $condicao;
            $parametros += $parametrosBusca;
        }

        if ($motoboy !== null) {
            $where[] = $motoboy ? 'm.fl_motoboy = TRUE' : 'm.fl_motoboy = FALSE';
        }

        $sql = 'SELECT m.id_mercado, m.nu_cnpj, m.nm_mercado, m.ds_email, m.nu_cep, m.nm_endereco, m.nu_numero, m.nm_bairro, m.nm_cidade, m.sg_uf,
                       m.fl_motoboy, m.nu_taxa_entrega, m.ds_foto_mercado, m.nu_latitude, m.nu_longitude,
                       m.nu_avg_nota, m.nul_avaliacoes,
                       (SELECT COUNT(*)
                          FROM tb_produto_mercado pm
                         WHERE pm.id_mercado = m.id_mercado
                           AND pm.fl_disponivel = TRUE
                           AND ' . ProdutoMercado::SQL_PROMOCAO_ATIVA . ') AS qt_promocoes
                FROM tb_mercado m'
                . ($where ? ' WHERE ' . implode(' AND ', $where) : '') . '
                ORDER BY m.nm_mercado';

        $stmt = $this->conexao->prepare($sql);
        $stmt->execute($parametros);
        $mercados = $stmt->fetchAll();

        $horarios = $this->horariosPorMercado(array_column($mercados, 'id_mercado'));

        foreach ($mercados as &$mercado) {
            $mercado['horarios'] = $horarios[(int) $mercado['id_mercado']] ?? [];
        }
        unset($mercado);

        return $mercados;
    }

    public function consultarPorId(int $idMercado): ?array
    {
        $sql = 'SELECT id_mercado, nu_cnpj, nm_mercado, ds_email, nu_cep, nm_endereco, nu_numero, nm_bairro, nm_cidade, sg_uf,
                       fl_motoboy, nu_taxa_entrega, ds_foto_mercado, nu_latitude, nu_longitude,
                       nu_avg_nota, nul_avaliacoes
                FROM tb_mercado
                WHERE id_mercado = :id_mercado';

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':id_mercado', $idMercado, PDO::PARAM_INT);
        $stmt->execute();

        $mercado = $stmt->fetch();

        if (!$mercado) {
            return null;
        }

        $mercado['horarios'] = $this->listarHorarios($idMercado);
        return $mercado;
    }

    public function alterarFoto(int $idMercado, string $caminho): void
    {
        $stmt = $this->conexao->prepare(
            'UPDATE tb_mercado SET ds_foto_mercado = :caminho WHERE id_mercado = :id_mercado'
        );
        $stmt->bindValue(':caminho', $caminho);
        $stmt->bindValue(':id_mercado', $idMercado, PDO::PARAM_INT);
        $stmt->execute();
    }

    public function listarHorarios(int $idMercado): array
    {
        return $this->horariosPorMercado([$idMercado])[$idMercado] ?? [];
    }

    private function horariosPorMercado(array $idsMercado): array
    {
        if (!$idsMercado) {
            return [];
        }

        $lista = implode(',', array_map('intval', $idsMercado));

        $sql = "SELECT id_mercado, nu_dia_semana,
                       TO_CHAR(hr_abertura, 'HH24:MI') AS hr_abertura,
                       TO_CHAR(hr_fechamento, 'HH24:MI') AS hr_fechamento
                FROM tb_horario_mercado
                WHERE id_mercado IN ({$lista})
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
        foreach ($linhas as $linha) {
            $resultado[(int) $linha['id_mercado']][] = [
                'nu_dia_semana' => (int) $linha['nu_dia_semana'],
                'hr_abertura' => $linha['hr_abertura'],
                'hr_fechamento' => $linha['hr_fechamento'],
            ];
        }

        return $resultado;
    }

    public function resumo(int $idMercado): ?array
    {
        $stmt = $this->conexao->prepare(
            'SELECT nm_mercado, ds_foto_mercado, nu_avg_nota, nul_avaliacoes
             FROM tb_mercado
             WHERE id_mercado = :id_mercado'
        );
        $stmt->bindValue(':id_mercado', $idMercado, PDO::PARAM_INT);
        $stmt->execute();
        $mercado = $stmt->fetch();

        if (!$mercado) {
            return null;
        }

        $stmt = $this->conexao->prepare(
            'SELECT COUNT(*) AS produtos_cadastrados,
                    COUNT(*) FILTER (WHERE ' . ProdutoMercado::SQL_PROMOCAO_ATIVA . ') AS produtos_promocao,
                    COUNT(*) FILTER (WHERE pm.fl_disponivel) AS produtos_disponiveis,
                    COUNT(*) FILTER (WHERE NOT pm.fl_disponivel) AS produtos_indisponiveis,
                    COUNT(*) FILTER (
                        WHERE pm.fl_disponivel AND pm.nu_qtde <= :limite
                    ) AS produtos_estoque_baixo
             FROM tb_produto_mercado pm
             WHERE pm.id_mercado = :id_mercado'
        );
        $stmt->bindValue(':limite', ProdutoMercado::LIMITE_ESTOQUE_BAIXO, PDO::PARAM_INT);
        $stmt->bindValue(':id_mercado', $idMercado, PDO::PARAM_INT);
        $stmt->execute();
        $produtos = array_map('intval', $stmt->fetch());

        $stmt = $this->conexao->prepare(
            'SELECT COUNT(DISTINCT id_usuario) FROM tb_mercado_favorito WHERE id_mercado = :id_mercado'
        );
        $stmt->bindValue(':id_mercado', $idMercado, PDO::PARAM_INT);
        $stmt->execute();
        $favoritos = (int) $stmt->fetchColumn();

        return array_merge(['nm_mercado' => $mercado['nm_mercado']], $produtos, [
            'limite_estoque_baixo' => ProdutoMercado::LIMITE_ESTOQUE_BAIXO,
            'nota_media' => (float) $mercado['nu_avg_nota'],
            'quantidade_avaliacoes' => (int) $mercado['nul_avaliacoes'],
            'quantidade_favoritos' => $favoritos,
            'informacoes_faltantes' => [
                'horario' => count($this->listarHorarios($idMercado)) === 0,
                'foto' => trim((string) $mercado['ds_foto_mercado']) === '',
            ],
        ]);
    }

    public function inserir(array $dados): array
    {
        $sql = 'INSERT INTO tb_mercado
                    (nu_cnpj, nm_mercado, ds_email, nu_cep, nm_endereco, nu_numero, nm_bairro, nm_cidade, sg_uf, ds_senha,
                     fl_motoboy, ds_foto_mercado, nu_latitude, nu_longitude,
                     nu_avg_nota, nul_avaliacoes)
                VALUES
                    (:nu_cnpj, :nm_mercado, :ds_email, :nu_cep, :nm_endereco, :nu_numero, :nm_bairro, :nm_cidade, :sg_uf, :ds_senha,
                     :fl_motoboy, :ds_foto_mercado, :nu_latitude, :nu_longitude,
                     :nu_avg_nota, :nul_avaliacoes)
                RETURNING id_mercado, nu_cnpj, nm_mercado, ds_email, nu_cep, nm_endereco, nu_numero, nm_bairro, nm_cidade, sg_uf,
                          fl_motoboy, ds_foto_mercado, nu_latitude, nu_longitude,
                          nu_avg_nota, nul_avaliacoes';

        $senhaHash = password_hash($dados['ds_senha'], PASSWORD_DEFAULT);

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':nu_cnpj', $dados['nu_cnpj']);
        $stmt->bindValue(':nm_mercado', $dados['nm_mercado']);
        $stmt->bindValue(':ds_email', $dados['ds_email']);
        $stmt->bindValue(':nu_cep', $dados['nu_cep'], PDO::PARAM_INT);
        $stmt->bindValue(':nm_endereco', $dados['nm_endereco']);
        $stmt->bindValue(':nu_numero', $dados['nu_numero']);
        $stmt->bindValue(':nm_bairro', $dados['nm_bairro']);
        $stmt->bindValue(':nm_cidade', $dados['nm_cidade']);
        $stmt->bindValue(':sg_uf', $dados['sg_uf']);
        $stmt->bindValue(':ds_senha', $senhaHash);
        $stmt->bindValue(':fl_motoboy', $dados['fl_motoboy'], PDO::PARAM_BOOL);
        $stmt->bindValue(':ds_foto_mercado', $dados['ds_foto_mercado']);
        $stmt->bindValue(':nu_latitude', $dados['nu_latitude']);
        $stmt->bindValue(':nu_longitude', $dados['nu_longitude']);
        $stmt->bindValue(':nu_avg_nota', $dados['nu_avg_nota']);
        $stmt->bindValue(':nul_avaliacoes', $dados['nul_avaliacoes'], PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->fetch();
    }

    public function alterar(int $idMercado, array $dados): ?array
    {
        $campos = [
            'nu_cnpj = :nu_cnpj',
            'nm_mercado = :nm_mercado',
            'ds_email = :ds_email',
            'nu_cep = :nu_cep',
            'nm_endereco = :nm_endereco',
            'nu_numero = :nu_numero',
            'nm_bairro = :nm_bairro',
            'nm_cidade = :nm_cidade',
            'sg_uf = :sg_uf',
            'fl_motoboy = :fl_motoboy',
            'ds_foto_mercado = :ds_foto_mercado',
            'nu_latitude = :nu_latitude',
            'nu_longitude = :nu_longitude',
            'nu_avg_nota = :nu_avg_nota',
            'nul_avaliacoes = :nul_avaliacoes',
        ];

        if (!empty($dados['ds_senha'])) {
            $campos[] = 'ds_senha = :ds_senha';
        }

        $sql = 'UPDATE tb_mercado
                SET ' . implode(', ', $campos) . '
                WHERE id_mercado = :id_mercado
                RETURNING id_mercado, nu_cnpj, nm_mercado, ds_email, nu_cep, nm_endereco, nu_numero, nm_bairro, nm_cidade, sg_uf,
                          fl_motoboy, ds_foto_mercado, nu_latitude, nu_longitude,
                          nu_avg_nota, nul_avaliacoes';

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':nu_cnpj', $dados['nu_cnpj']);
        $stmt->bindValue(':nm_mercado', $dados['nm_mercado']);
        $stmt->bindValue(':ds_email', $dados['ds_email']);
        $stmt->bindValue(':nu_cep', $dados['nu_cep'], PDO::PARAM_INT);
        $stmt->bindValue(':nm_endereco', $dados['nm_endereco']);
        $stmt->bindValue(':nu_numero', $dados['nu_numero']);
        $stmt->bindValue(':nm_bairro', $dados['nm_bairro']);
        $stmt->bindValue(':nm_cidade', $dados['nm_cidade']);
        $stmt->bindValue(':sg_uf', $dados['sg_uf']);
        $stmt->bindValue(':fl_motoboy', $dados['fl_motoboy'], PDO::PARAM_BOOL);
        $stmt->bindValue(':ds_foto_mercado', $dados['ds_foto_mercado']);
        $stmt->bindValue(':nu_latitude', $dados['nu_latitude']);
        $stmt->bindValue(':nu_longitude', $dados['nu_longitude']);
        $stmt->bindValue(':nu_avg_nota', $dados['nu_avg_nota']);
        $stmt->bindValue(':nul_avaliacoes', $dados['nul_avaliacoes'], PDO::PARAM_INT);
        $stmt->bindValue(':id_mercado', $idMercado, PDO::PARAM_INT);

        if (!empty($dados['ds_senha'])) {
            $stmt->bindValue(':ds_senha', password_hash($dados['ds_senha'], PASSWORD_DEFAULT));
        }

        $stmt->execute();
        $mercado = $stmt->fetch();
        return $mercado ?: null;
    }

    public function alterarPerfil(int $idMercado, array $dados): ?array
    {
        $sql = 'UPDATE tb_mercado
                SET nm_mercado = :nm_mercado,
                    ds_email = :ds_email,
                    nu_cep = :nu_cep,
                    nm_endereco = :nm_endereco,
                    nu_numero = :nu_numero,
                    nm_bairro = :nm_bairro,
                    nm_cidade = :nm_cidade,
                    sg_uf = :sg_uf,
                    nu_latitude = :nu_latitude,
                    nu_longitude = :nu_longitude,
                    fl_motoboy = :fl_motoboy,
                    nu_taxa_entrega = :nu_taxa_entrega
                WHERE id_mercado = :id_mercado
                RETURNING id_mercado, nm_mercado, ds_email, nu_cep, nm_endereco, nu_numero, nm_bairro, nm_cidade, sg_uf,
                          nu_latitude, nu_longitude, fl_motoboy, nu_taxa_entrega, ds_foto_mercado';

        $this->conexao->beginTransaction();

        try {
            $stmt = $this->conexao->prepare($sql);
            $stmt->bindValue(':nm_mercado', $dados['nm_mercado']);
            $stmt->bindValue(':ds_email', $dados['ds_email']);
            $stmt->bindValue(':nu_cep', $dados['nu_cep'], PDO::PARAM_INT);
            $stmt->bindValue(':nm_endereco', $dados['nm_endereco']);
            $stmt->bindValue(':nu_numero', $dados['nu_numero']);
            $stmt->bindValue(':nm_bairro', $dados['nm_bairro']);
            $stmt->bindValue(':nm_cidade', $dados['nm_cidade']);
            $stmt->bindValue(':sg_uf', $dados['sg_uf']);
            $stmt->bindValue(':nu_latitude', $dados['nu_latitude']);
            $stmt->bindValue(':nu_longitude', $dados['nu_longitude']);
            $stmt->bindValue(':fl_motoboy', $dados['fl_motoboy'], PDO::PARAM_BOOL);
            $stmt->bindValue(':nu_taxa_entrega', $dados['nu_taxa_entrega']);
            $stmt->bindValue(':id_mercado', $idMercado, PDO::PARAM_INT);
            $stmt->execute();

            $mercado = $stmt->fetch();

            if (!$mercado) {
                $this->conexao->rollBack();
                return null;
            }

            if ($dados['horarios'] !== null) {
                $this->substituirHorarios($idMercado, $dados['horarios']);
            }

            $this->conexao->commit();
        } catch (Throwable $e) {
            $this->conexao->rollBack();
            throw $e;
        }

        $mercado['horarios'] = $this->listarHorarios($idMercado);
        return $mercado;
    }

    private function substituirHorarios(int $idMercado, array $horarios): void
    {
        $stmt = $this->conexao->prepare('DELETE FROM tb_horario_mercado WHERE id_mercado = :id_mercado');
        $stmt->bindValue(':id_mercado', $idMercado, PDO::PARAM_INT);
        $stmt->execute();

        $stmt = $this->conexao->prepare(
            'INSERT INTO tb_horario_mercado (id_mercado, nu_dia_semana, hr_abertura, hr_fechamento)
             VALUES (:id_mercado, :nu_dia_semana, :hr_abertura, :hr_fechamento)'
        );

        foreach ($horarios as $faixa) {
            $stmt->bindValue(':id_mercado', $idMercado, PDO::PARAM_INT);
            $stmt->bindValue(':nu_dia_semana', $faixa['nu_dia_semana'], PDO::PARAM_INT);
            $stmt->bindValue(':hr_abertura', $faixa['hr_abertura']);
            $stmt->bindValue(':hr_fechamento', $faixa['hr_fechamento']);
            $stmt->execute();
        }
    }

    public function excluir(int $idMercado): bool
    {
        $this->conexao->beginTransaction();

        try {
            $dependentes = ['tb_produto_mercado', 'tb_mercado_favorito', 'tb_avaliacao_mercado', 'tb_horario_mercado'];

            foreach ($dependentes as $tabela) {
                $stmt = $this->conexao->prepare("DELETE FROM {$tabela} WHERE id_mercado = :id_mercado");
                $stmt->bindValue(':id_mercado', $idMercado, PDO::PARAM_INT);
                $stmt->execute();
            }

            $stmt = $this->conexao->prepare('DELETE FROM tb_mercado WHERE id_mercado = :id_mercado');
            $stmt->bindValue(':id_mercado', $idMercado, PDO::PARAM_INT);
            $stmt->execute();
            $excluiu = $stmt->rowCount() > 0;

            $this->conexao->commit();
            return $excluiu;
        } catch (Throwable $e) {
            $this->conexao->rollBack();
            throw $e;
        }
    }
}
