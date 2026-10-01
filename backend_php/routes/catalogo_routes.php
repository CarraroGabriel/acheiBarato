<?php

require_once __DIR__ . '/../controllers/CatalogoController.php';
require_once __DIR__ . '/../helpers/Response.php';

function tratarRotaCatalogo(string $metodo, string $rotaPrincipal): void
{
    if ($metodo !== 'GET') {
        Response::json(false, 'Método não permitido.', null, 405);
    }

    $controller = new CatalogoController();

    switch ($rotaPrincipal) {
        case 'categorias':
            $controller->listarCategorias();
            break;
        case 'marcas':
            $controller->listarMarcas();
            break;
        case 'unidades':
            $controller->listarUnidades();
            break;
        default:
            Response::json(false, 'Rota não encontrada.', null, 404);
    }
}
