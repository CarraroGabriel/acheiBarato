<?php

require_once __DIR__ . '/../config/Database.php';

class Categoria
{
    private PDO $conexao;

    public function __construct()
    {
        $database = new Database();
        $this->conexao = $database->conectar();
    }

    public function listar(): array
    {
        $sql = 'SELECT id_categoria, nm_categoria
                FROM tb_categoria
                ORDER BY nm_categoria';

        return $this->conexao->query($sql)->fetchAll();
    }
}
