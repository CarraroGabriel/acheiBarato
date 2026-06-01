<?php

require_once __DIR__ . "/../config/Database.php";
require_once __DIR__ . "/../controllers/UsuarioController.php";
require_once __DIR__ . "/../helpers/Response.php";

function tratarRotasUsuario(string $metodo, array $partesUri): void
{
    $database = new Database();
    $conexao = $database->conectar();

    $repository = new UsuarioRepository($conexao);
    $controller = new UsuarioController($repository);

    $dados = json_decode(file_get_contents("php://input"), true);

    if ($dados === null) {
        $dados = [];
    }

    $id_usuario = null;

    if (isset($partesUri[1]) && is_numeric($partesUri[1])) {
        $id_usuario = (int) $partesUri[1];
    }

    switch ($metodo) {
        case "GET":
            if ($id_usuario !== null) {
                $controller->consultar($id_usuario);
            } else {
                $controller->listar();
            }
            break;

        case "POST":
            $controller->inserir($dados);
            break;

        case "PUT":
            if ($id_usuario === null) {
                Response::json(false, "Informe o id_usuario na URL para alterar.", null, 400);
            }

            $controller->alterar($id_usuario, $dados);
            break;

        case "DELETE":
            if ($id_usuario === null) {
                Response::json(false, "Informe o id_usuario na URL para excluir.", null, 400);
            }

            $controller->excluir($id_usuario);
            break;

        default:
            Response::json(false, "Método HTTP não permitido.", null, 405);
    }
}
