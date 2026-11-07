<?php

require_once __DIR__ . '/../controllers/ProdutoMercadoController.php';
require_once __DIR__ . '/../helpers/Response.php';
require_once __DIR__ . '/../helpers/Autenticacao.php';
require_once __DIR__ . '/../models/ProdutoMercado.php';

// Só o mercado dono da oferta pode alterá-la, trocar a foto ou excluí-la.
function exigirMercadoDaOferta(int $idProdutoMercado): void
{
    Autenticacao::exigir();

    $oferta = (new ProdutoMercado())->consultarPorId($idProdutoMercado);
    if ($oferta === null) {
        Response::json(false, 'Produto do mercado não encontrado.', null, 404);
    }

    Autenticacao::exigirMercado((int) $oferta['id_mercado']);
}

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
            if ($idProdutoMercado !== null && ($rota[2] ?? null) === 'foto') {
                exigirMercadoDaOferta($idProdutoMercado);
                $controller->enviarFoto($idProdutoMercado);
            } else {
                $corpo = json_decode(file_get_contents('php://input'), true);
                Autenticacao::exigirMercado((int) (is_array($corpo) ? ($corpo['id_mercado'] ?? 0) : 0));
                $controller->inserir();
            }
            break;
        case 'PUT':
            if ($idProdutoMercado === null) {
                Response::json(false, 'Informe o id_produto_mercado na URL.', null, 400);
            }
            exigirMercadoDaOferta($idProdutoMercado);
            $controller->alterar($idProdutoMercado);
            break;
        case 'DELETE':
            if ($idProdutoMercado === null) {
                Response::json(false, 'Informe o id_produto_mercado na URL.', null, 400);
            }
            exigirMercadoDaOferta($idProdutoMercado);
            $controller->excluir($idProdutoMercado);
            break;
        default:
            Response::json(false, 'Método não permitido.', null, 405);
    }
}
