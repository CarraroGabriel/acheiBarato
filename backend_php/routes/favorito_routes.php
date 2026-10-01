<?php

require_once __DIR__ . '/../controllers/FavoritoController.php';
require_once __DIR__ . '/../helpers/Response.php';

function tratarRotaFavorito(string $metodo, array $rota): void
{
    if ($metodo !== 'GET') {
        Response::json(false, 'Método não permitido.', null, 405);
    }

    if (!isset($_GET['id_usuario']) || !ctype_digit((string) $_GET['id_usuario'])) {
        Response::json(false, 'Informe o id_usuario na consulta.', null, 400);
    }

    $idUsuario = (int) $_GET['id_usuario'];
    $controller = new FavoritoController();

    switch ($rota[1] ?? null) {
        case null:
            $controller->listar($idUsuario);
            break;
        case 'mercados':
            $controller->listarMercados($idUsuario);
            break;
        case 'produtos':
            $controller->listarProdutos($idUsuario);
            break;
        default:
            Response::json(false, 'Rota não encontrada.', null, 404);
    }
}
