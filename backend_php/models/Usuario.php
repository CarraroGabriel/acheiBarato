<?php

require_once __DIR__ . '/../config/Database.php';
require_once __DIR__ . '/AvaliacaoMercado.php';

class Usuario
{
    private PDO $conexao;

    public function __construct()
    {
        $database = new Database();
        $this->conexao = $database->conectar();
    }

    public function listar(): array
    {
        $sql = 'SELECT id_usuario, nu_cpf, nm_usuario, ds_email, dt_nascimento
                FROM tb_usuario
                ORDER BY nm_usuario';

        $stmt = $this->conexao->prepare($sql);
        $stmt->execute();
        return $stmt->fetchAll();
    }

    public function consultarPorId(int $idUsuario): ?array
    {
        $sql = 'SELECT id_usuario, nu_cpf, nm_usuario, ds_email, dt_nascimento
                FROM tb_usuario
                WHERE id_usuario = :id_usuario';

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':id_usuario', $idUsuario, PDO::PARAM_INT);
        $stmt->execute();

        $usuario = $stmt->fetch();
        return $usuario ?: null;
    }

    public function inserir(array $dados): array
    {
        $sql = 'INSERT INTO tb_usuario
                    (nu_cpf, nm_usuario, ds_email, dt_nascimento, ds_senha)
                VALUES
                    (:nu_cpf, :nm_usuario, :ds_email, :dt_nascimento, :ds_senha)
                RETURNING id_usuario, nu_cpf, nm_usuario, ds_email, dt_nascimento';

        $senhaHash = password_hash($dados['ds_senha'], PASSWORD_DEFAULT);

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':nu_cpf', $dados['nu_cpf']);
        $stmt->bindValue(':nm_usuario', $dados['nm_usuario']);
        $stmt->bindValue(':ds_email', $dados['ds_email']);
        $stmt->bindValue(':dt_nascimento', $dados['dt_nascimento']);
        $stmt->bindValue(':ds_senha', $senhaHash);
        $stmt->execute();

        return $stmt->fetch();
    }

    public function alterar(int $idUsuario, array $dados): ?array
    {
        $campos = [
            'nu_cpf = :nu_cpf',
            'nm_usuario = :nm_usuario',
            'ds_email = :ds_email',
            'dt_nascimento = :dt_nascimento',
        ];

        if (!empty($dados['ds_senha'])) {
            $campos[] = 'ds_senha = :ds_senha';
        }

        $sql = 'UPDATE tb_usuario
                SET ' . implode(', ', $campos) . '
                WHERE id_usuario = :id_usuario
                RETURNING id_usuario, nu_cpf, nm_usuario, ds_email, dt_nascimento';

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':nu_cpf', $dados['nu_cpf']);
        $stmt->bindValue(':nm_usuario', $dados['nm_usuario']);
        $stmt->bindValue(':ds_email', $dados['ds_email']);
        $stmt->bindValue(':dt_nascimento', $dados['dt_nascimento']);
        $stmt->bindValue(':id_usuario', $idUsuario, PDO::PARAM_INT);

        if (!empty($dados['ds_senha'])) {
            $stmt->bindValue(':ds_senha', password_hash($dados['ds_senha'], PASSWORD_DEFAULT));
        }

        $stmt->execute();
        $usuario = $stmt->fetch();
        return $usuario ?: null;
    }

    public function alterarPerfil(int $idUsuario, array $dados): ?array
    {
        $sql = 'UPDATE tb_usuario
                SET nm_usuario = :nm_usuario,
                    ds_email = :ds_email
                WHERE id_usuario = :id_usuario
                RETURNING id_usuario, nm_usuario, ds_email';

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':nm_usuario', $dados['nm_usuario']);
        $stmt->bindValue(':ds_email', $dados['ds_email']);
        $stmt->bindValue(':id_usuario', $idUsuario, PDO::PARAM_INT);
        $stmt->execute();

        $usuario = $stmt->fetch();
        return $usuario ?: null;
    }

    public function excluir(int $idUsuario): bool
    {
        $this->conexao->beginTransaction();

        try {
            $stmt = $this->conexao->prepare(
                'SELECT DISTINCT id_mercado FROM tb_avaliacao_mercado WHERE id_usuario = :id_usuario'
            );
            $stmt->bindValue(':id_usuario', $idUsuario, PDO::PARAM_INT);
            $stmt->execute();
            $mercadosAvaliados = $stmt->fetchAll(PDO::FETCH_COLUMN);

            foreach (['tb_produto_favorito', 'tb_mercado_favorito', 'tb_avaliacao_mercado'] as $tabela) {
                $stmt = $this->conexao->prepare("DELETE FROM {$tabela} WHERE id_usuario = :id_usuario");
                $stmt->bindValue(':id_usuario', $idUsuario, PDO::PARAM_INT);
                $stmt->execute();
            }

            if ($mercadosAvaliados) {
                $ids = implode(',', array_map('intval', $mercadosAvaliados));
                $this->conexao->exec(AvaliacaoMercado::SQL_RECALCULAR_MEDIA . " WHERE id_mercado IN ({$ids})");
            }

            $stmt = $this->conexao->prepare('DELETE FROM tb_usuario WHERE id_usuario = :id_usuario');
            $stmt->bindValue(':id_usuario', $idUsuario, PDO::PARAM_INT);
            $stmt->execute();
            $excluiu = $stmt->rowCount() > 0;

            $this->conexao->commit();
            return $excluiu;
        } catch (Throwable $e) {
            $this->conexao->rollBack();
            throw $e;
        }
    }
}
