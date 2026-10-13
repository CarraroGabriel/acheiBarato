<?php

require_once __DIR__ . '/../models/Notificacao.php';
require_once __DIR__ . '/../helpers/Response.php';

class NotificacaoController
{
    private Notificacao $notificacao;

    public function __construct()
    {
        $this->notificacao = new Notificacao();
    }

    public function listar(string $campo, int $id): void
    {
        try {
            Response::json(true, 'Notificações consultadas.', $this->notificacao->listar($campo, $id), 200);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao consultar notificações.', null, 500);
        }
    }

    public function contarNaoLidas(string $campo, int $id): void
    {
        try {
            Response::json(true, 'Notificações não lidas.', [
                'nao_lidas' => $this->notificacao->contarNaoLidas($campo, $id),
            ], 200);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao consultar notificações.', null, 500);
        }
    }

    public function marcarTodasLidas(string $campo, int $id): void
    {
        try {
            Response::json(true, 'Notificações marcadas como lidas.', [
                'atualizadas' => $this->notificacao->marcarTodasLidas($campo, $id),
            ], 200);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao atualizar notificações.', null, 500);
        }
    }

    public function excluir(string $campo, int $id, int $idNotificacao): void
    {
        try {
            if (!$this->notificacao->excluir($campo, $id, $idNotificacao)) {
                Response::json(false, 'Notificação não encontrada.', null, 404);
            }

            Response::json(true, 'Notificação excluída.', ['id_notificacao' => $idNotificacao], 200);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao excluir notificação.', null, 500);
        }
    }

    public function excluirTodas(string $campo, int $id): void
    {
        try {
            Response::json(true, 'Notificações excluídas.', [
                'excluidas' => $this->notificacao->excluirTodas($campo, $id),
            ], 200);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao excluir notificações.', null, 500);
        }
    }
}
