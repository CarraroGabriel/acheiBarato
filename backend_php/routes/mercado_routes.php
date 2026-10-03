<?php

require_once __DIR__ . '/../controllers/MercadoController.php';
require_once __DIR__ . '/../helpers/Response.php';

function tratarRotasMercado(string $metodo, array $rota): void
{
    $controller = new MercadoController();
    $idMercado = isset($rota[1]) && ctype_digit((string) $rota[1]) ? (int) $rota[1] : null;
    $subrota = $rota[2] ?? null;

    if ($metodo === 'GET' && $idMercado !== null && $subrota === 'promocoes') {
        $controller->listarPromocoes($idMercado);
        return;
    }

    if ($metodo === 'GET' && $idMercado !== null && $subrota === 'resumo') {
        $controller->resumo($idMercado);
        return;
    }

    if ($idMercado !== null && $subrota === 'avaliacao') {
        match ($metodo) {
            'GET' => $controller->consultarAvaliacao($idMercado),
            'POST' => $controller->avaliar($idMercado),
            default => Response::json(false, 'Método não permitido.', null, 405),
        };
        return;
    }

    switch ($metodo) {
        case 'GET':
            $idMercado === null ? $controller->listar() : $controller->consultar($idMercado);
            break;
        case 'POST':
            $controller->inserir();
            break;
        case 'PUT':
            if ($idMercado === null) {
                Response::json(false, 'Informe o id_mercado na URL.', null, 400);
            }

            if ($subrota === 'perfil') {
                $controller->alterarPerfil($idMercado);
            } else {
                $controller->alterar($idMercado);
            }
            break;
        case 'DELETE':
            if ($idMercado === null) {
                Response::json(false, 'Informe o id_mercado na URL.', null, 400);
            }
            $controller->excluir($idMercado);
            break;
        default:
            Response::json(false, 'Método não permitido.', null, 405);
    }
}
