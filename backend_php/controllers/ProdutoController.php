<?php

require_once __DIR__ . '/../models/Produto.php';
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
