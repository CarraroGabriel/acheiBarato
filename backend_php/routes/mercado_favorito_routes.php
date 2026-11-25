<?php

require_once __DIR__ . '/../controllers/MercadoFavoritoController.php';
require_once __DIR__ . '/../helpers/Response.php';

function tratarRotaMercadoFavorito(string $metodo): void
{
    $controller = new MercadoFavoritoController();

    switch ($metodo) {
        case 'GET':    $controller->consultar(); break;
        case 'POST':   $controller->adicionar(); break;
        case 'DELETE': $controller->remover();   break;
        default: Response::json(false, 'Método não permitido.', null, 405);
    }
}