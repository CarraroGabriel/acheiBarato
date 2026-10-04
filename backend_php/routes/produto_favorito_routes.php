<?php

require_once __DIR__ . '/../controllers/ProdutoFavoritoController.php';
require_once __DIR__ . '/../helpers/Response.php';

function tratarRotaProdutoFavorito(string $metodo): void
{
    $controller = new ProdutoFavoritoController();

    switch ($metodo) {
        case 'GET':    $controller->consultar(); break;
        case 'POST':   $controller->adicionar(); break;
        case 'DELETE': $controller->remover();   break;
        default: Response::json(false, 'Método não permitido.', null, 405);
    }
}
