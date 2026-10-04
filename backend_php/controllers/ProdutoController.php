<?php

require_once __DIR__ . '/../models/Produto.php';
require_once __DIR__ . '/../models/ProdutoMercado.php';
require_once __DIR__ . '/../helpers/Response.php';

class ProdutoController
{
    private Produto $produto;

    public function __construct()
    {
        $this->produto = new Produto();
    }

    public function listar(): void
    {
        try {
            Response::json(true, 'Produtos encontrados.', $this->produto->listar(), 200);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao consultar produtos.', null, 500);
        }
    }

    public function buscar(): void
    {
        try {
            $busca = trim((string) ($_GET['busca'] ?? ''));

            if (strlen($busca) > 200) {
                throw new InvalidArgumentException('Texto de busca muito longo.');
            }

            $filtros = [
                'busca' => $busca,
                'id_categoria' => $this->lerInteiro('categoria'),
                'id_marca' => $this->lerInteiro('marca'),
                'preco_min' => $this->lerPreco('preco_min'),
                'preco_max' => $this->lerPreco('preco_max'),
                'promocao' => in_array($_GET['promocao'] ?? '', ['sim', 'nao'], true)
                    ? $_GET['promocao']
                    : null,
                'ordem' => in_array($_GET['ordem'] ?? '', ['menor_preco', 'maior_preco', 'nome'], true)
                    ? $_GET['ordem']
                    : 'relevancia',
            ];

            Response::json(
                true,
                'Busca de produtos realizada.',
                (new ProdutoMercado())->buscarItens($filtros),
                200
            );
        } catch (InvalidArgumentException $e) {
            Response::json(false, $e->getMessage(), null, 400);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao buscar produtos.', null, 500);
        }
    }

    private function lerInteiro(string $campo): ?int
    {
        $valor = trim((string) ($_GET[$campo] ?? ''));

        if ($valor === '') {
            return null;
        }

        if (!ctype_digit($valor)) {
            throw new InvalidArgumentException("Parâmetro {$campo} inválido.");
        }

        return (int) $valor;
    }

    private function lerPreco(string $campo): ?float
    {
        $valor = str_replace(',', '.', trim((string) ($_GET[$campo] ?? '')));

        if ($valor === '') {
            return null;
        }

        if (!is_numeric($valor) || (float) $valor < 0) {
            throw new InvalidArgumentException("Parâmetro {$campo} inválido.");
        }

        return (float) $valor;
    }

    public function consultar(int $idProduto): void
    {
        try {
            $produto = $this->produto->consultarPorId($idProduto);

            if ($produto === null) {
                Response::json(false, 'Produto não encontrado.', null, 404);
            }

            Response::json(true, 'Produto encontrado.', $produto, 200);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao consultar produto.', null, 500);
        }
    }
}
