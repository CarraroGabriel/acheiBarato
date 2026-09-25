<?php

require_once __DIR__ . '/../controllers/ProdutoMercadoController.php';
require_once __DIR__ . '/../helpers/Response.php';

function tratarRotasProdutoMercado(string $metodo, array $rota): void
{
    $controller = new ProdutoMercadoController();
    $idProdutoMercado = isset($rota[1]) && ctype_digit((string) $rota[1]) ? (int) $rota[1] : null;

    switch ($metodo) {
        case 'GET':
            if ($idProdutoMercado !== null) {
                $controller->consultar($idProdutoMercado);
            } else {
                $idMercado = isset($_GET['mercado']) && ctype_digit((string) $_GET['mercado'])
                    ? (int) $_GET['mercado']
                    : null;
                $controller->listar($idMercado);
            }
            break;
        case 'POST':
            $controller->inserir();
            break;
        case 'PUT':
            if ($idProdutoMercado === null) {
                Response::json(false, 'Informe o id_produto_mercado na URL.', null, 400);
            }
            $controller->alterar($idProdutoMercado);
            break;
        case 'DELETE':
            if ($idProdutoMercado === null) {
                Response::json(false, 'Informe o id_produto_mercado na URL.', null, 400);
            }
            $controller->excluir($idProdutoMercado);
            break;
        default:
            Response::json(false, 'Método não permitido.', null, 405);
    }
}
