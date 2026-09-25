<?php

require_once __DIR__ . '/../controllers/ProdutoMercadoController.php';
require_once __DIR__ . '/../helpers/Response.php';

function tratarRotaPromocao(string $metodo): void
{
    if ($metodo !== 'GET') {
        Response::json(false, 'Método não permitido.', null, 405);
    }

    $idUsuario = isset($_GET['id_usuario']) && ctype_digit((string) $_GET['id_usuario'])
        ? (int) $_GET['id_usuario']
        : null;

    $controller = new ProdutoMercadoController();
    $controller->listarPromocoes($idUsuario);
}
