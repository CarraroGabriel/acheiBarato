<?php

require_once __DIR__ . '/../models/Auth.php';
require_once __DIR__ . '/../helpers/Response.php';

class AuthController
{
    private Auth $auth;

    public function __construct()
    {
        $this->auth = new Auth();
    }

    public function login(): void
    {
        $dados = json_decode(file_get_contents('php://input'), true);
        $dados = is_array($dados) ? $dados : [];

        $tipo = strtolower(trim((string) ($dados['tipo'] ?? '')));
        $identificador = trim((string) ($dados['identificador'] ?? ''));
        $senha = (string) ($dados['ds_senha'] ?? '');

        if (!in_array($tipo, ['usuario', 'mercado'], true)) {
            Response::json(false, 'O campo tipo deve ser usuario ou mercado.', null, 400);
        }

        if ($identificador === '' || $senha === '') {
            Response::json(false, 'Identificador e senha são obrigatórios.', null, 400);
        }

        try {
            if ($tipo === 'usuario') {
                $resultado = $this->auth->loginUsuario($identificador, $senha);
            } else {
                $cnpj = preg_replace('/\D/', '', $identificador);
                $resultado = $this->auth->loginMercado($cnpj, $senha);
            }

            if ($resultado === null) {
                Response::json(false, 'Credenciais inválidas.', null, 401);
            }

            Response::json(true, 'Login realizado com sucesso.', $resultado, 200);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao realizar login.', null, 500);
        }
    }
}
