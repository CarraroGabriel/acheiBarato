<?php

require_once __DIR__ . '/../models/Usuario.php';
require_once __DIR__ . '/../helpers/Response.php';

class UsuarioController
{
    private Usuario $usuario;

    public function __construct()
    {
        $this->usuario = new Usuario();
    }

    public function listar(): void
    {
        try {
            Response::json(true, 'Usuários encontrados.', $this->usuario->listar(), 200);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao consultar usuários.', null, 500);
        }
    }

    public function consultar(int $idUsuario): void
    {
        try {
            $dados = $this->usuario->consultarPorId($idUsuario);

            if ($dados === null) {
                Response::json(false, 'Usuário não encontrado.', null, 404);
            }

            Response::json(true, 'Usuário encontrado.', $dados, 200);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao consultar usuário.', null, 500);
        }
    }

    public function inserir(): void
    {
        $dados = $this->lerJson();

        try {
            $dados = $this->validar($dados, true);
            $resultado = $this->usuario->inserir($dados);
            Response::json(true, 'Usuário cadastrado com sucesso.', $resultado, 201);
        } catch (PDOException $e) {
            if ($e->getCode() === '23505') {
                Response::json(false, 'CPF ou e-mail já cadastrado.', null, 409);
            }
            Response::json(false, 'Erro ao cadastrar usuário.', null, 500);
        } catch (InvalidArgumentException $e) {
            Response::json(false, $e->getMessage(), null, 400);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao cadastrar usuário.', null, 500);
        }
    }

    public function alterar(int $idUsuario): void
    {
        $dados = $this->lerJson();

        try {
            $dados = $this->validar($dados, false);
            $resultado = $this->usuario->alterar($idUsuario, $dados);

            if ($resultado === null) {
                Response::json(false, 'Usuário não encontrado.', null, 404);
            }

            Response::json(true, 'Usuário alterado com sucesso.', $resultado, 200);
        } catch (InvalidArgumentException $e) {
            Response::json(false, $e->getMessage(), null, 400);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao alterar usuário.', null, 500);
        }
    }

    public function excluir(int $idUsuario): void
    {
        try {
            if (!$this->usuario->excluir($idUsuario)) {
                Response::json(false, 'Usuário não encontrado.', null, 404);
            }

            Response::json(true, 'Usuário removido com sucesso.', ['id_usuario' => $idUsuario], 200);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao remover usuário.', null, 500);
        }
    }

    private function lerJson(): array
    {
        $dados = json_decode(file_get_contents('php://input'), true);
        return is_array($dados) ? $dados : [];
    }

    private function validar(array $dados, bool $senhaObrigatoria): array
    {
        $obrigatorios = ['nu_cpf', 'nm_usuario', 'ds_email', 'dt_nascimento'];

        foreach ($obrigatorios as $campo) {
            if (!isset($dados[$campo]) || trim((string) $dados[$campo]) === '') {
                throw new InvalidArgumentException("O campo {$campo} é obrigatório.");
            }
        }

        if ($senhaObrigatoria && (!isset($dados['ds_senha']) || trim((string) $dados['ds_senha']) === '')) {
            throw new InvalidArgumentException('O campo ds_senha é obrigatório.');
        }

        $cpf = preg_replace('/\D/', '', (string) $dados['nu_cpf']);
        if (strlen($cpf) !== 11) {
            throw new InvalidArgumentException('O CPF deve possuir 11 dígitos.');
        }
        $dados['nu_cpf'] = $cpf;

        if (!filter_var($dados['ds_email'], FILTER_VALIDATE_EMAIL)) {
            throw new InvalidArgumentException('Informe um e-mail válido.');
        }

        if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', (string) $dados['dt_nascimento'])) {
            throw new InvalidArgumentException('A data de nascimento deve estar no formato AAAA-MM-DD.');
        }

        return $dados;
    }
}
