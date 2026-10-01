<?php

require_once __DIR__ . '/../controllers/UsuarioController.php';
require_once __DIR__ . '/../helpers/Response.php';

function tratarRotasUsuario(string $metodo, array $partesUri): void
{
    $controller = new UsuarioController();

    $id_usuario = null;

    if (isset($partesUri[1]) && ctype_digit((string) $partesUri[1])) {
        $id_usuario = (int) $partesUri[1];
    }

    switch ($metodo) {
        case 'GET':
            if ($id_usuario !== null) {
                $controller->consultar($id_usuario);
            } else {
                $controller->listar();
            }
            break;

        case 'POST':
            $controller->inserir();
            break;

        case 'PUT':
            if ($id_usuario === null) {
                Response::json(false, 'Informe o id_usuario na URL para alterar.', null, 400);
            }

            if (($partesUri[2] ?? null) === 'perfil') {
                $controller->alterarPerfil($id_usuario);
            } else {
                $controller->alterar($id_usuario);
            }
            break;

        case 'DELETE':
            if ($id_usuario === null) {
                Response::json(false, 'Informe o id_usuario na URL para excluir.', null, 400);
            }
            $controller->excluir($id_usuario);
            break;

        default:
            Response::json(false, 'Método HTTP não permitido.', null, 405);
    }
}
