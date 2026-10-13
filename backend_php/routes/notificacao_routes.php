<?php

require_once __DIR__ . '/../controllers/NotificacaoController.php';
require_once __DIR__ . '/../helpers/Response.php';

function tratarRotaNotificacao(string $metodo, array $rota): void
{
    if (isset($_GET['id_usuario']) && ctype_digit((string) $_GET['id_usuario'])) {
        $campo = 'id_usuario';
        $id = (int) $_GET['id_usuario'];
    } elseif (isset($_GET['id_mercado']) && ctype_digit((string) $_GET['id_mercado'])) {
        $campo = 'id_mercado';
        $id = (int) $_GET['id_mercado'];
    } else {
        Response::json(false, 'Informe o id_usuario ou o id_mercado na consulta.', null, 400);
    }

    $controller = new NotificacaoController();
    $subrota = $rota[1] ?? null;

    if ($metodo === 'GET' && $subrota === null) {
        $controller->listar($campo, $id);
    } elseif ($metodo === 'GET' && $subrota === 'nao_lidas') {
        $controller->contarNaoLidas($campo, $id);
    } elseif ($metodo === 'PUT' && $subrota === 'lidas') {
        $controller->marcarTodasLidas($campo, $id);
    } elseif ($metodo === 'DELETE' && $subrota === null) {
        $controller->excluirTodas($campo, $id);
    } elseif ($metodo === 'DELETE' && ctype_digit((string) $subrota)) {
        $controller->excluir($campo, $id, (int) $subrota);
    } else {
        Response::json(false, 'Rota não encontrada.', null, 404);
    }
}
