<?php

require_once __DIR__ . '/../controllers/AuthController.php';
require_once __DIR__ . '/../helpers/Response.php';

function tratarRotaLogin(string $metodo): void
{
    if ($metodo !== 'POST') {
        Response::json(false, 'Método não permitido.', null, 405);
    }

    $controller = new AuthController();
    $controller->login();
}
