<?php

require_once __DIR__ . '/../config/Database.php';

class MercadoFavorito
{
    private PDO $conexao;

    public function __construct()
    {
        $this->conexao = (new Database())->conectar();
    }

    public function existe(int $idUsuario, int $idMercado): bool
    {
        $stmt = $this->conexao->prepare(
            'SELECT 1 FROM tb_mercado_favorito
             WHERE id_usuario = :u AND id_mercado = :m'
        );
        $stmt->bindValue(':u', $idUsuario, PDO::PARAM_INT);
        $stmt->bindValue(':m', $idMercado, PDO::PARAM_INT);
        $stmt->execute();
        return (bool) $stmt->fetch();
    }

    public function adicionar(int $idUsuario, int $idMercado): void
    {
        $stmt = $this->conexao->prepare(
            'INSERT INTO tb_mercado_favorito (id_usuario, id_mercado)
             VALUES (:u, :m)
             ON CONFLICT (id_usuario, id_mercado) DO NOTHING'
        );
        $stmt->bindValue(':u', $idUsuario, PDO::PARAM_INT);
        $stmt->bindValue(':m', $idMercado, PDO::PARAM_INT);
        $stmt->execute();
    }

    public function remover(int $idUsuario, int $idMercado): void
    {
        $stmt = $this->conexao->prepare(
            'DELETE FROM tb_mercado_favorito
             WHERE id_usuario = :u AND id_mercado = :m'
        );
        $stmt->bindValue(':u', $idUsuario, PDO::PARAM_INT);
        $stmt->bindValue(':m', $idMercado, PDO::PARAM_INT);
        $stmt->execute();
    }
}