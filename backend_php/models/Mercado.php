<?php

require_once __DIR__ . '/../config/Database.php';

class Mercado
{
    private PDO $conexao;

    public function __construct()
    {
        $database = new Database();
        $this->conexao = $database->conectar();
    }

    public function listar(): array
    {
        $sql = 'SELECT id_mercado, nu_cnpj, nm_mercado, ds_email, nu_cep, nm_endereco,
                       fl_motoboy, ds_foto_mercado, nu_latitude, nu_longitude,
                       nu_avg_nota, nul_avaliacoes
                FROM tb_mercado
                ORDER BY nm_mercado';

        $stmt = $this->conexao->prepare($sql);
        $stmt->execute();
        return $stmt->fetchAll();
    }

    public function consultarPorId(int $idMercado): ?array
    {
        $sql = 'SELECT id_mercado, nu_cnpj, nm_mercado, ds_email, nu_cep, nm_endereco,
                       fl_motoboy, ds_foto_mercado, nu_latitude, nu_longitude,
                       nu_avg_nota, nul_avaliacoes
                FROM tb_mercado
                WHERE id_mercado = :id_mercado';

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':id_mercado', $idMercado, PDO::PARAM_INT);
        $stmt->execute();

        $mercado = $stmt->fetch();
        return $mercado ?: null;
    }

    public function inserir(array $dados): array
    {
        $sql = 'INSERT INTO tb_mercado
                    (nu_cnpj, nm_mercado, ds_email, nu_cep, nm_endereco, ds_senha,
                     fl_motoboy, ds_foto_mercado, nu_latitude, nu_longitude,
                     nu_avg_nota, nul_avaliacoes)
                VALUES
                    (:nu_cnpj, :nm_mercado, :ds_email, :nu_cep, :nm_endereco, :ds_senha,
                     :fl_motoboy, :ds_foto_mercado, :nu_latitude, :nu_longitude,
                     :nu_avg_nota, :nul_avaliacoes)
                RETURNING id_mercado, nu_cnpj, nm_mercado, ds_email, nu_cep, nm_endereco,
                          fl_motoboy, ds_foto_mercado, nu_latitude, nu_longitude,
                          nu_avg_nota, nul_avaliacoes';

        $senhaHash = password_hash($dados['ds_senha'], PASSWORD_DEFAULT);

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':nu_cnpj', $dados['nu_cnpj']);
        $stmt->bindValue(':nm_mercado', $dados['nm_mercado']);
        $stmt->bindValue(':ds_email', $dados['ds_email']);
        $stmt->bindValue(':nu_cep', $dados['nu_cep'], PDO::PARAM_INT);
        $stmt->bindValue(':nm_endereco', $dados['nm_endereco']);
        $stmt->bindValue(':ds_senha', $senhaHash);
        $stmt->bindValue(':fl_motoboy', $dados['fl_motoboy'], PDO::PARAM_BOOL);
        $stmt->bindValue(':ds_foto_mercado', $dados['ds_foto_mercado']);
        $stmt->bindValue(':nu_latitude', $dados['nu_latitude']);
        $stmt->bindValue(':nu_longitude', $dados['nu_longitude']);
        $stmt->bindValue(':nu_avg_nota', $dados['nu_avg_nota']);
        $stmt->bindValue(':nul_avaliacoes', $dados['nul_avaliacoes'], PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->fetch();
    }

    public function alterar(int $idMercado, array $dados): ?array
    {
        $campos = [
            'nu_cnpj = :nu_cnpj',
            'nm_mercado = :nm_mercado',
            'ds_email = :ds_email',
            'nu_cep = :nu_cep',
            'nm_endereco = :nm_endereco',
            'fl_motoboy = :fl_motoboy',
            'ds_foto_mercado = :ds_foto_mercado',
            'nu_latitude = :nu_latitude',
            'nu_longitude = :nu_longitude',
            'nu_avg_nota = :nu_avg_nota',
            'nul_avaliacoes = :nul_avaliacoes',
        ];

        if (!empty($dados['ds_senha'])) {
            $campos[] = 'ds_senha = :ds_senha';
        }

        $sql = 'UPDATE tb_mercado
                SET ' . implode(', ', $campos) . '
                WHERE id_mercado = :id_mercado
                RETURNING id_mercado, nu_cnpj, nm_mercado, ds_email, nu_cep, nm_endereco,
                          fl_motoboy, ds_foto_mercado, nu_latitude, nu_longitude,
                          nu_avg_nota, nul_avaliacoes';

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':nu_cnpj', $dados['nu_cnpj']);
        $stmt->bindValue(':nm_mercado', $dados['nm_mercado']);
        $stmt->bindValue(':ds_email', $dados['ds_email']);
        $stmt->bindValue(':nu_cep', $dados['nu_cep'], PDO::PARAM_INT);
        $stmt->bindValue(':nm_endereco', $dados['nm_endereco']);
        $stmt->bindValue(':fl_motoboy', $dados['fl_motoboy'], PDO::PARAM_BOOL);
        $stmt->bindValue(':ds_foto_mercado', $dados['ds_foto_mercado']);
        $stmt->bindValue(':nu_latitude', $dados['nu_latitude']);
        $stmt->bindValue(':nu_longitude', $dados['nu_longitude']);
        $stmt->bindValue(':nu_avg_nota', $dados['nu_avg_nota']);
        $stmt->bindValue(':nul_avaliacoes', $dados['nul_avaliacoes'], PDO::PARAM_INT);
        $stmt->bindValue(':id_mercado', $idMercado, PDO::PARAM_INT);

        if (!empty($dados['ds_senha'])) {
            $stmt->bindValue(':ds_senha', password_hash($dados['ds_senha'], PASSWORD_DEFAULT));
        }

        $stmt->execute();
        $mercado = $stmt->fetch();
        return $mercado ?: null;
    }

    public function excluir(int $idMercado): bool
    {
        $sql = 'DELETE FROM tb_mercado WHERE id_mercado = :id_mercado';
        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':id_mercado', $idMercado, PDO::PARAM_INT);
        $stmt->execute();
        return $stmt->rowCount() > 0;
    }
}
