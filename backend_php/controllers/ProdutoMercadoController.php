<?php

require_once __DIR__ . '/../models/ProdutoMercado.php';
require_once __DIR__ . '/../helpers/Response.php';

class ProdutoMercadoController
{
    private ProdutoMercado $produtoMercado;

    public function __construct()
    {
        $this->produtoMercado = new ProdutoMercado();
    }

    public function listar(?int $idMercado = null): void
    {
        try {
            Response::json(
                true,
                'Produtos do mercado encontrados.',
                $this->produtoMercado->listar($idMercado),
                200
            );
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao consultar produtos do mercado.', null, 500);
        }
    }

    public function consultar(int $idProdutoMercado): void
    {
        try {
            $produto = $this->produtoMercado->consultarPorId($idProdutoMercado);

            if ($produto === null) {
                Response::json(false, 'Produto do mercado não encontrado.', null, 404);
            }

            Response::json(true, 'Produto do mercado encontrado.', $produto, 200);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao consultar produto do mercado.', null, 500);
        }
    }

    public function inserir(): void
    {
        $dados = $this->lerJson();

        try {
            $dados = $this->normalizarEValidar($dados);
            $resultado = $this->produtoMercado->registrar($dados);
            Response::json(true, 'Produto registrado no mercado com sucesso.', $resultado, 201);
        } catch (InvalidArgumentException|RuntimeException $e) {
            Response::json(false, $e->getMessage(), null, 400);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao registrar produto no mercado.', null, 500);
        }
    }

    public function alterar(int $idProdutoMercado): void
    {
        $dados = $this->lerJson();

        try {
            foreach (['nu_valor', 'nu_qtde', 'fl_promocao', 'fl_disponivel'] as $campo) {
                if (!array_key_exists($campo, $dados)) {
                    throw new InvalidArgumentException("O campo {$campo} é obrigatório.");
                }
            }

            $dados['nu_valor'] = $this->normalizarNumeroDecimal($dados['nu_valor']);
            $dados['nu_qtde'] = (int) $dados['nu_qtde'];
            $dados['fl_promocao'] = (bool) $dados['fl_promocao'];
            $dados['fl_disponivel'] = (bool) $dados['fl_disponivel'];

            $dados['nu_desconto'] = $dados['fl_promocao']
                ? (int) ($dados['nu_desconto'] ?? 0)
                : 0;

            if ($dados['nu_valor'] < 0 || $dados['nu_qtde'] < 0) {
                throw new InvalidArgumentException('Valor e quantidade não podem ser negativos.');
            }

            if ($dados['nu_desconto'] < 0 || $dados['nu_desconto'] > 100) {
                throw new InvalidArgumentException('Desconto inválido.');
            }

            if ($dados['fl_promocao'] && $dados['nu_desconto'] === 0) {
                throw new InvalidArgumentException('Informe o percentual de desconto da promoção.');
            }

            $dados['dt_fim_promocao'] = $dados['fl_promocao']
                ? $this->lerFimPromocao($dados['dt_fim_promocao'] ?? null)
                : null;

            $resultado = $this->produtoMercado->alterar($idProdutoMercado, $dados);

            if ($resultado === null) {
                Response::json(false, 'Produto do mercado não encontrado.', null, 404);
            }

            Response::json(true, 'Produto alterado com sucesso.', $resultado, 200);
        } catch (InvalidArgumentException $e) {
            Response::json(false, $e->getMessage(), null, 400);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao alterar produto.', null, 500);
        }
    }

    public function excluir(int $idProdutoMercado): void
    {
        try {
            if (!$this->produtoMercado->excluir($idProdutoMercado)) {
                Response::json(false, 'Produto do mercado não encontrado.', null, 404);
            }

            Response::json(
                true,
                'Produto removido do mercado com sucesso.',
                ['id_produto_mercado' => $idProdutoMercado],
                200
            );
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao remover produto do mercado.', null, 500);
        }
    }

    public function listarPromocoes(?int $idUsuario = null): void
    {
        try {
            Response::json(
                true,
                'Promoções encontradas.',
                $this->produtoMercado->listarPromocoes(null, $idUsuario),
                200
            );
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao consultar promoções.', null, 500);
        }
    }

    /**
     * Término da promoção, em data/hora ISO 8601 com fuso (ex.: 2026-10-02T23:59:00-03:00).
     * Vazio/nulo = promoção sem prazo. Retorna a data no formato aceito pelo PostgreSQL.
     */
    private function lerFimPromocao(mixed $valor): ?string
    {
        if ($valor === null || trim((string) $valor) === '') {
            return null;
        }

        try {
            $fim = new DateTimeImmutable((string) $valor);
        } catch (Exception $e) {
            throw new InvalidArgumentException('Data de término da promoção inválida.');
        }

        if ($fim <= new DateTimeImmutable('now')) {
            throw new InvalidArgumentException('O término da promoção deve ser depois de agora.');
        }

        return $fim->format(DATE_ATOM);
    }

    private function lerJson(): array
    {
        $dados = json_decode(file_get_contents('php://input'), true);
        return is_array($dados) ? $dados : [];
    }

    private function normalizarEValidar(array $dados): array
    {
        foreach (['id_mercado', 'nu_medida', 'id_unidade', 'nu_valor', 'nu_qtde'] as $campo) {
            if (!isset($dados[$campo]) || trim((string) $dados[$campo]) === '') {
                throw new InvalidArgumentException("O campo {$campo} é obrigatório.");
            }
        }

        [$dados['id_produto'], $dados['nm_produto']] = $this->lerReferencia($dados, 'produto', 50);
        [$dados['id_tipo'], $dados['nm_tipo']] = $this->lerReferencia($dados, 'tipo', 30);
        [$dados['id_marca'], $dados['nm_marca']] = $this->lerReferencia($dados, 'marca', 40);

        $dados['id_mercado'] = (int) $dados['id_mercado'];
        $dados['id_categoria'] = (int) ($dados['id_categoria'] ?? 0) ?: null;
        $dados['id_unidade'] = (int) $dados['id_unidade'];
        $dados['nu_medida'] = $this->normalizarNumeroDecimal($dados['nu_medida']);
        $dados['nu_valor'] = $this->normalizarNumeroDecimal($dados['nu_valor']);
        $dados['nu_qtde'] = (int) $dados['nu_qtde'];
        $dados['fl_promocao'] = (bool) ($dados['fl_promocao'] ?? false);
        $dados['fl_disponivel'] = (bool) ($dados['fl_disponivel'] ?? true);

        if ($dados['id_mercado'] <= 0) {
            throw new InvalidArgumentException('id_mercado inválido.');
        }

        if ($dados['id_unidade'] <= 0) {
            throw new InvalidArgumentException('Selecione a unidade de medida.');
        }

        if ($dados['nu_medida'] <= 0 || $dados['nu_medida'] >= 10000000) {
            throw new InvalidArgumentException('Conteúdo da embalagem inválido.');
        }

        if ($dados['nu_valor'] < 0 || $dados['nu_qtde'] < 0) {
            throw new InvalidArgumentException('Valor e quantidade não podem ser negativos.');
        }

        return $dados;
    }

    private function lerReferencia(array $dados, string $campo, int $tamanhoMaximo): array
    {
        $id = (int) ($dados["id_{$campo}"] ?? 0);

        if ($id > 0) {
            return [$id, null];
        }

        $nome = preg_replace('/\s+/u', ' ', trim((string) ($dados["nm_{$campo}"] ?? '')));

        if ($nome === '') {
            throw new InvalidArgumentException("Informe o {$campo}.");
        }

        if (!preg_match('/^.{1,' . $tamanhoMaximo . '}$/u', $nome)) {
            throw new InvalidArgumentException("O {$campo} deve ter no máximo {$tamanhoMaximo} caracteres.");
        }

        return [null, $nome];
    }

    private function normalizarNumeroDecimal(mixed $valor): float
    {
        return (float) str_replace(',', '.', trim((string) $valor));
    }
}
