<?php

require_once __DIR__ . '/../config/Database.php';

class Marca
{
    private PDO $conexao;

    public function __construct()
    {
        $database = new Database();
        $this->conexao = $database->conectar();
    }

    public function listar(): array
    {
        $sql = 'SELECT id_marca, nm_marca
                FROM tb_marca
                ORDER BY nm_marca';

        return $this->conexao->query($sql)->fetchAll();
    }
}
