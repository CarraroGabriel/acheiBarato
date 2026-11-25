<?php

require_once __DIR__ . '/../config/Database.php';

class AvaliacaoMercado
{
    public const SQL_RECALCULAR_MEDIA = 'UPDATE tb_mercado
        SET nu_avg_nota = COALESCE((
                SELECT ROUND(AVG(a.nu_nota), 2)
                FROM tb_avaliacao_mercado a
                WHERE a.id_mercado = tb_mercado.id_mercado
            ), 0),
            nul_avaliacoes = (
                SELECT COUNT(*)
                FROM tb_avaliacao_mercado a
                WHERE a.id_mercado = tb_mercado.id_mercado
            )';

    private PDO $conexao;

    public function __construct()
    {
        $this->conexao = (new Database())->conectar();
    }

    public function consultarNota(int $idUsuario, int $idMercado): ?int
    {
        $stmt = $this->conexao->prepare(
            'SELECT nu_nota FROM tb_avaliacao_mercado
             WHERE id_usuario = :id_usuario AND id_mercado = :id_mercado'
        );
        $stmt->bindValue(':id_usuario', $idUsuario, PDO::PARAM_INT);
        $stmt->bindValue(':id_mercado', $idMercado, PDO::PARAM_INT);
        $stmt->execute();

        $nota = $stmt->fetchColumn();
        return $nota === false ? null : (int) $nota;
    }

    public function avaliar(int $idUsuario, int $idMercado, int $nota): array
    {
        $this->conexao->beginTransaction();

        try {
            $stmt = $this->conexao->prepare(
                'INSERT INTO tb_avaliacao_mercado (id_usuario, id_mercado, dt_avaliacao, nu_nota)
                 VALUES (:id_usuario, :id_mercado, CURRENT_DATE, :nu_nota)
                 ON CONFLICT (id_usuario, id_mercado)
                 DO UPDATE SET nu_nota = EXCLUDED.nu_nota, dt_avaliacao = CURRENT_DATE'
            );
            $stmt->bindValue(':id_usuario', $idUsuario, PDO::PARAM_INT);
            $stmt->bindValue(':id_mercado', $idMercado, PDO::PARAM_INT);
            $stmt->bindValue(':nu_nota', $nota, PDO::PARAM_INT);
            $stmt->execute();

            $stmt = $this->conexao->prepare(
                self::SQL_RECALCULAR_MEDIA . '
                WHERE id_mercado = :id_mercado
                RETURNING nu_avg_nota, nul_avaliacoes'
            );
            $stmt->bindValue(':id_mercado', $idMercado, PDO::PARAM_INT);
            $stmt->execute();
            $resultado = $stmt->fetch();

            $this->conexao->commit();
        } catch (Throwable $e) {
            $this->conexao->rollBack();
            throw $e;
        }

        return [
            'nu_nota' => $nota,
            'nu_avg_nota' => (float) $resultado['nu_avg_nota'],
            'nul_avaliacoes' => (int) $resultado['nul_avaliacoes'],
        ];
    }
}
