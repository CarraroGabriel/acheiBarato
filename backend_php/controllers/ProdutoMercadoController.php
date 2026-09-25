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

            if ($dados['nu_valor'] < 0 || $dados['nu_qtde'] < 0) {
                throw new InvalidArgumentException('Valor e quantidade não podem ser negativos.');
            }

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

    private function lerJson(): array
    {
        $dados = json_decode(file_get_contents('php://input'), true);
        return is_array($dados) ? $dados : [];
    }

    private function normalizarEValidar(array $dados): array
    {
        foreach (['id_mercado', 'nm_produto', 'nm_marca', 'ds_categoria', 'nu_valor', 'nu_qtde'] as $campo) {
            if (!isset($dados[$campo]) || trim((string) $dados[$campo]) === '') {
                throw new InvalidArgumentException("O campo {$campo} é obrigatório.");
            }
        }

        $dados['id_mercado'] = (int) $dados['id_mercado'];
        $dados['nu_valor'] = $this->normalizarNumeroDecimal($dados['nu_valor']);
        $dados['nu_qtde'] = (int) $dados['nu_qtde'];
        $dados['fl_promocao'] = (bool) ($dados['fl_promocao'] ?? false);
        $dados['fl_disponivel'] = (bool) ($dados['fl_disponivel'] ?? true);
        $dados['ds_foto_produto'] = (string) ($dados['ds_foto_produto'] ?? '');

        if ($dados['id_mercado'] <= 0) {
            throw new InvalidArgumentException('id_mercado inválido.');
        }

        if ($dados['nu_valor'] < 0 || $dados['nu_qtde'] < 0) {
            throw new InvalidArgumentException('Valor e quantidade não podem ser negativos.');
        }

        return $dados;
    }

    private function normalizarNumeroDecimal(mixed $valor): float
    {
        return (float) str_replace(',', '.', trim((string) $valor));
    }
}
