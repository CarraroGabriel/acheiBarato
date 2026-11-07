<?php

require_once __DIR__ . '/../config/Env.php';
require_once __DIR__ . '/Response.php';

/**
 * Token de acesso da API.
 *
 * No login, a API devolve um token assinado (HMAC-SHA256) com o perfil
 * (usuario ou mercado), o id da conta e a validade. O aplicativo envia o
 * token no cabeçalho "Authorization: Bearer <token>" e cada rota confere se
 * a conta do token é a dona do recurso pedido. O token não é guardado no
 * banco: a assinatura, feita com a chave AUTH_SECRET do arquivo .env, é o
 * que garante que ele foi emitido pela própria API.
 */
class Autenticacao
{
    private const VALIDADE_SEGUNDOS = 12 * 60 * 60;

    public static function gerarToken(string $tipo, int $id): string
    {
        $payload = self::base64Url(json_encode([
            'tipo' => $tipo,
            'id' => $id,
            'exp' => time() + self::VALIDADE_SEGUNDOS,
        ]));

        return $payload . '.' . self::assinar($payload);
    }

    /** Devolve ['tipo' => ..., 'id' => ...] da conta do token ou encerra com 401. */
    public static function exigir(): array
    {
        $token = self::tokenDaRequisicao();

        if ($token === null) {
            Response::json(false, 'Faça login para continuar.', null, 401);
        }

        $partes = explode('.', $token);
        if (count($partes) !== 2 || !hash_equals(self::assinar($partes[0]), $partes[1])) {
            Response::json(false, 'Sessão inválida. Entre novamente.', null, 401);
        }

        $dados = json_decode((string) self::decodificarBase64Url($partes[0]), true);
        if (
            !is_array($dados)
            || !in_array($dados['tipo'] ?? null, ['usuario', 'mercado'], true)
            || !is_int($dados['id'] ?? null)
            || !is_int($dados['exp'] ?? null)
        ) {
            Response::json(false, 'Sessão inválida. Entre novamente.', null, 401);
        }

        if ($dados['exp'] < time()) {
            Response::json(false, 'Sessão expirada. Entre novamente.', null, 401);
        }

        return ['tipo' => $dados['tipo'], 'id' => $dados['id']];
    }

    /** Só o próprio consumidor pode acessar os dados da sua conta. */
    public static function exigirUsuario(int $idUsuario): void
    {
        self::exigirDono('usuario', $idUsuario);
    }

    /** Só o próprio mercado pode alterar os seus dados e as suas ofertas. */
    public static function exigirMercado(int $idMercado): void
    {
        self::exigirDono('mercado', $idMercado);
    }

    private static function exigirDono(string $tipo, int $id): void
    {
        $conta = self::exigir();

        if ($conta['tipo'] !== $tipo || $conta['id'] !== $id) {
            Response::json(false, 'Acesso negado.', null, 403);
        }
    }

    private static function tokenDaRequisicao(): ?string
    {
        $cabecalho = $_SERVER['HTTP_AUTHORIZATION']
            ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION']
            ?? null;

        if ($cabecalho === null && function_exists('apache_request_headers')) {
            foreach (apache_request_headers() as $nome => $valor) {
                if (strcasecmp($nome, 'Authorization') === 0) {
                    $cabecalho = $valor;
                    break;
                }
            }
        }

        if ($cabecalho === null || !preg_match('/^Bearer\s+(\S+)$/i', trim($cabecalho), $m)) {
            return null;
        }

        return $m[1];
    }

    private static function assinar(string $payload): string
    {
        return self::base64Url(hash_hmac('sha256', $payload, self::segredo(), true));
    }

    private static function segredo(): string
    {
        Env::carregar();
        $segredo = getenv('AUTH_SECRET') ?: '';

        // Sem uma chave forte configurada, nenhuma rota protegida é liberada.
        if (strlen($segredo) < 32) {
            Response::json(false, 'Autenticação não configurada no servidor.', null, 500);
        }

        return $segredo;
    }

    private static function base64Url(string $dados): string
    {
        return rtrim(strtr(base64_encode($dados), '+/', '-_'), '=');
    }

    private static function decodificarBase64Url(string $dados): string|false
    {
        return base64_decode(strtr($dados, '-_', '+/'), true);
    }
}
