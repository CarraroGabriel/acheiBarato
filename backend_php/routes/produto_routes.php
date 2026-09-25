<?php

require_once __DIR__ . '/../controllers/ProdutoController.php';
require_once __DIR__ . '/../helpers/Response.php';

function tratarRotasProduto(string $metodo, array $rota): void
{
    if ($metodo !== 'GET') {
        Response::json(false, 'Método não permitido.', null, 405);
    }

    $controller = new ProdutoController();
    $idProduto = isset($rota[1]) && ctype_digit((string) $rota[1]) ? (int) $rota[1] : null;

    $idProduto === null ? $controller->listar() : $controller->consultar($idProduto);
}
