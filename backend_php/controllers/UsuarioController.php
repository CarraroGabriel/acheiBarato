<?php

require_once __DIR__ . "/../repositories/UsuarioRepository.php";
require_once __DIR__ . "/../helpers/Response.php";

class UsuarioController
{
    private UsuarioRepository $repository;

    public function __construct(UsuarioRepository $repository)
    {
        $this->repository = $repository;
    }

    public function listar(): void
    {
        try {
            $usuarios = $this->repository->listar();
            Response::json(true, "Usuários consultados com sucesso.", $usuarios, 200);
        } catch (Exception $e) {
            Response::json(false, "Erro ao consultar usuários.", $e->getMessage(), 500);
        }
    }

    public function consultar(int $id_usuario): void
    {
        try {
            $usuario = $this->repository->consultarPorId($id_usuario);

            if (!$usuario) {
                Response::json(false, "Usuário não encontrado.", null, 404);
            }

            Response::json(true, "Usuário consultado com sucesso.", $usuario, 200);
        } catch (Exception $e) {
            Response::json(false, "Erro ao consultar usuário.", $e->getMessage(), 500);
        }
    }

    public function inserir(array $dados): void
    {
        try {
            $this->validarDadosObrigatorios($dados);
            $usuario = Usuario::fromArray($dados);
            $usuarioInserido = $this->repository->inserir($usuario);

            Response::json(true, "Usuário inserido com sucesso.", $usuarioInserido, 201);
        } catch (Exception $e) {
            Response::json(false, "Erro ao inserir usuário.", $e->getMessage(), 400);
        }
    }

    public function alterar(int $id_usuario, array $dados): void
    {
        try {
            $this->validarDadosObrigatorios($dados);

            $usuario = Usuario::fromArray([
                "id_usuario" => $id_usuario,
                "nm_login" => $dados["nm_login"],
                "ds_senha" => $dados["ds_senha"]
            ]);

            $usuarioAlterado = $this->repository->alterar($usuario);

            if (!$usuarioAlterado) {
                Response::json(false, "Usuário não encontrado para alteração.", null, 404);
            }

            Response::json(true, "Usuário alterado com sucesso.", $usuarioAlterado, 200);
        } catch (Exception $e) {
            Response::json(false, "Erro ao alterar usuário.", $e->getMessage(), 400);
        }
    }

    public function excluir(int $id_usuario): void
    {
        try {
            $excluiu = $this->repository->excluir($id_usuario);

            if (!$excluiu) {
                Response::json(false, "Usuário não encontrado para exclusão.", null, 404);
            }

            Response::json(true, "Usuário excluído com sucesso.", null, 200);
        } catch (Exception $e) {
            Response::json(false, "Erro ao excluir usuário.", $e->getMessage(), 500);
        }
    }

    private function validarDadosObrigatorios(array $dados): void
    {
        if (!isset($dados["nm_login"]) || trim($dados["nm_login"]) === "") {
            throw new Exception("O campo nm_login é obrigatório.");
        }

        if (!isset($dados["ds_senha"]) || trim($dados["ds_senha"]) === "") {
            throw new Exception("O campo ds_senha é obrigatório.");
        }

        if (strlen($dados["nm_login"]) > 30) {
            throw new Exception("O campo nm_login deve possuir no máximo 30 caracteres.");
        }

        if (strlen($dados["ds_senha"]) > 50) {
            throw new Exception("O campo ds_senha deve possuir no máximo 50 caracteres.");
        }
    }
}
