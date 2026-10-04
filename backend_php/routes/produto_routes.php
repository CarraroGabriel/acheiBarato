<?php

require_once __DIR__ . '/../controllers/ProdutoController.php';
require_once __DIR__ . '/../helpers/Response.php';

function tratarRotasProduto(string $metodo, array $rota): void
{
    if ($metodo !== 'GET') {
        Response::json(false, 'Método não permitido.', null, 405);
    }

    $controller = new ProdutoController();

    if (($rota[1] ?? null) === 'busca') {
        $controller->buscar();
        return;
    }
    
    if (($rota[1] ?? null) === 'item') {
        if (!isset($rota[2]) || !ctype_digit((string) $rota[2])) {
            Response::json(false, 'Informe o id do produto na URL.', null, 400);
        }
        $controller->compararItem((int) $rota[2]);
        return;
    }

    $idProduto = isset($rota[1]) && ctype_digit((string) $rota[1]) ? (int) $rota[1] : null;

    $idProduto === null ? $controller->listar() : $controller->consultar($idProduto);
}
