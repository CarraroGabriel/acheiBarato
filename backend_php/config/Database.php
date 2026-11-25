<?php

require_once __DIR__ . '/Env.php';

class Database
{
    private string $host;
    private string $port;
    private string $dbname;
    private string $user;
    private string $password;
    private string $dbschema;

    public function __construct()
    {
        Env::carregar();

        $this->host     = getenv('DB_HOST')     ?: '';
        $this->port     = getenv('DB_PORT')     ?: '';
        $this->dbname   = getenv('DB_NAME')     ?: '';
        $this->user     = getenv('DB_USER')     ?: '';
        $this->password = getenv('DB_PASSWORD') ?: '';
        $this->dbschema = getenv('DB_SCHEMA')   ?: '';
    }

    public function conectar(): PDO
    {
        try {
            if ($this->host === '' || $this->dbname === '' || $this->user === '') {
                throw new RuntimeException('As variáveis de conexão com o banco não foram configuradas.');
            }

            $dsn = "pgsql:host={$this->host};port={$this->port};dbname={$this->dbname}";

            $pdo = new PDO($dsn, $this->user, $this->password, [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
            ]);

            if ($this->dbschema !== '') {
                if (!preg_match('/^[A-Za-z_][A-Za-z0-9_]*$/', $this->dbschema)) {
                    throw new RuntimeException('DB_SCHEMA possui um nome inválido.');
                }

                $pdo->exec('SET search_path TO "' . $this->dbschema . '"');
            }

            return $pdo;
        } catch (Throwable $e) {
            http_response_code(500);
            header('Content-Type: application/json; charset=UTF-8');
            echo json_encode([
                'sucesso' => false,
                'mensagem' => 'Erro ao conectar ao banco de dados.',
                'dados' => null,
            ], JSON_UNESCAPED_UNICODE);
            exit;
        }
    }
}