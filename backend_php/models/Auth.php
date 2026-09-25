<?php

require_once __DIR__ . '/../config/Database.php';

class Auth
{
    private PDO $conexao;

    public function __construct()
    {
        $database = new Database();
        $this->conexao = $database->conectar();
    }

    public function loginUsuario(string $email, string $senha): ?array
    {
        $sql = 'SELECT id_usuario, nu_cpf, nm_usuario, ds_email, dt_nascimento, ds_senha
                FROM tb_usuario
                WHERE LOWER(ds_email) = LOWER(:email)
                LIMIT 1';

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':email', $email);
        $stmt->execute();
        $usuario = $stmt->fetch();

        if (!$usuario || !$this->senhaValida($senha, (string) $usuario['ds_senha'])) {
            return null;
        }

        unset($usuario['ds_senha']);
        $usuario['tipo'] = 'usuario';
        return $usuario;
    }

    public function loginMercado(string $cnpj, string $senha): ?array
    {
        $sql = 'SELECT id_mercado, nu_cnpj, nm_mercado, ds_email, nu_cep, nm_endereco,
                       fl_motoboy, ds_foto_mercado, nu_latitude, nu_longitude,
                       nu_avg_nota, nul_avaliacoes, ds_senha
                FROM tb_mercado
                WHERE nu_cnpj = :cnpj
                LIMIT 1';

        $stmt = $this->conexao->prepare($sql);
        $stmt->bindValue(':cnpj', $cnpj);
        $stmt->execute();
        $mercado = $stmt->fetch();

        if (!$mercado || !$this->senhaValida($senha, (string) $mercado['ds_senha'])) {
            return null;
        }

        unset($mercado['ds_senha']);
        $mercado['tipo'] = 'mercado';
        return $mercado;
    }

    private function senhaValida(string $senhaInformada, string $senhaArmazenada): bool
    {
        $info = password_get_info($senhaArmazenada);

        if (($info['algoName'] ?? 'unknown') !== 'unknown') {
            return password_verify($senhaInformada, $senhaArmazenada);
        }

        // Compatibilidade temporária com registros antigos que ainda estejam em texto puro.
        return hash_equals($senhaArmazenada, $senhaInformada);
    }
}
