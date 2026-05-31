<?php

require_once __DIR__ . "/../models/Usuario.php";

class UsuarioRepository
{
    private PDO $conexao;

    public function __construct(PDO $conexao)
    {
        $this->conexao = $conexao;
    }

    public function listar(): array
    {
        $sql = "
            SELECT
                id_usuario,
                nm_login,
                ds_senha
            FROM tb_usuario
            ORDER BY id_usuario
        ";

        $stmt = $this->conexao->prepare($sql);
        $stmt->execute();

        return $stmt->fetchAll();
    }

    public function consultarPorId(int $id_usuario): ?array
    {
        $sql = "
            SELECT
                id_usuario,
                nm_login,
                ds_senha
            FROM tb_usuario
            WHERE id_usuario = :id_usuario
        ";

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(":id_usuario", $id_usuario, PDO::PARAM_INT);
        $stmt->execute();

        $usuario = $stmt->fetch();

        return $usuario ?: null;
    }

    public function inserir(Usuario $usuario): array
    {
        $sql = "
            INSERT INTO tb_usuario (
                nm_login,
                ds_senha
            ) VALUES (
                :nm_login,
                :ds_senha
            )
            RETURNING id_usuario, nm_login, ds_senha
        ";

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(":nm_login", $usuario->nm_login, PDO::PARAM_STR);
        $stmt->bindValue(":ds_senha", $usuario->ds_senha, PDO::PARAM_STR);
        $stmt->execute();

        return $stmt->fetch();
    }

    public function alterar(Usuario $usuario): ?array
    {
        $sql = "
            UPDATE tb_usuario
            SET
                nm_login = :nm_login,
                ds_senha = :ds_senha
            WHERE id_usuario = :id_usuario
            RETURNING id_usuario, nm_login, ds_senha
        ";

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(":id_usuario", $usuario->id_usuario, PDO::PARAM_INT);
        $stmt->bindValue(":nm_login", $usuario->nm_login, PDO::PARAM_STR);
        $stmt->bindValue(":ds_senha", $usuario->ds_senha, PDO::PARAM_STR);
        $stmt->execute();

        $usuarioAlterado = $stmt->fetch();

        return $usuarioAlterado ?: null;
    }

    public function excluir(int $id_usuario): bool
    {
        $sql = "
            DELETE FROM tb_usuario
            WHERE id_usuario = :id_usuario
        ";

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(":id_usuario", $id_usuario, PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->rowCount() > 0;
    }
}
