<?php

require_once __DIR__ . '/../config/Database.php';

class UnidadeMedida
{
    private PDO $conexao;

    public function __construct()
    {
        $database = new Database();
        $this->conexao = $database->conectar();
    }

    public function listar(): array
    {
        $sql = 'SELECT id_unidade, nm_unidade, sg_unidade, ds_grandeza, nu_fator
                FROM tb_unidade_medida
                ORDER BY ds_grandeza, nu_fator';

        return $this->conexao->query($sql)->fetchAll();
    }
}
