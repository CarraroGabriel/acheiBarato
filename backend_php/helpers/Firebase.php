<?php

class Firebase
{
    private const CAMINHO_CHAVE = __DIR__ . '/../config/firebase-chave.json';
    private const ESCOPO = 'https://www.googleapis.com/auth/firebase.messaging';

    public static function enviarParaTopicos(
        array $topicos,
        string $titulo,
        string $mensagem,
        array $dados = []
    ): void {
        $chave = self::lerChave();
        $topicos = array_values(array_unique($topicos));

        $destino = count($topicos) === 1
            ? ['topic' => $topicos[0]]
            : ['condition' => implode(' || ', array_map(
                fn(string $t) => "'{$t}' in topics",
                $topicos
            ))];

        $corpo = [
            'message' => $destino + [
                'notification' => ['title' => $titulo, 'body' => $mensagem],
                // O FCM só aceita textos nos dados extras; (object) evita que
                // um array vazio vire lista "[]" no JSON.
                'data' => (object) array_map('strval', $dados),
                'android' => ['priority' => 'high'],
            ],
        ];

        [$status, $resposta] = self::post(
            "https://fcm.googleapis.com/v1/projects/{$chave['project_id']}/messages:send",
            json_encode($corpo, JSON_UNESCAPED_UNICODE),
            [
                'Content-Type: application/json; charset=UTF-8',
                'Authorization: Bearer ' . self::tokenDeAcesso($chave),
            ]
        );

        if ($status !== 200) {
            throw new RuntimeException("Firebase recusou o envio (HTTP {$status}): {$resposta}");
        }
    }

    private static function lerChave(): array
    {
        if (!is_readable(self::CAMINHO_CHAVE)) {
            throw new RuntimeException('Chave do Firebase não encontrada em config/firebase-chave.json.');
        }

        $chave = json_decode((string) file_get_contents(self::CAMINHO_CHAVE), true);

        if (!is_array($chave) || empty($chave['private_key']) || empty($chave['client_email'])) {
            throw new RuntimeException('Chave do Firebase inválida.');
        }

        return $chave;
    }

    // Token OAuth do Google (vale 1 hora). Fica em cache num arquivo temporário
    // para não pedir um token novo a cada notificação.
    private static function tokenDeAcesso(array $chave): string
    {
        $cache = sys_get_temp_dir() . '/acheibarato_fcm_' . md5($chave['client_email']) . '.json';

        if (is_readable($cache)) {
            $salvo = json_decode((string) file_get_contents($cache), true);
            if (is_array($salvo) && ($salvo['expira'] ?? 0) > time() + 60) {
                return $salvo['token'];
            }
        }

        [$status, $resposta] = self::post(
            'https://oauth2.googleapis.com/token',
            http_build_query([
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => self::jwt($chave),
            ]),
            ['Content-Type: application/x-www-form-urlencoded']
        );

        $json = json_decode($resposta, true);
        if ($status !== 200 || empty($json['access_token'])) {
            throw new RuntimeException("Falha ao autenticar no Google (HTTP {$status}).");
        }

        @file_put_contents($cache, json_encode([
            'token' => $json['access_token'],
            'expira' => time() + (int) ($json['expires_in'] ?? 3600),
        ]), LOCK_EX);

        return $json['access_token'];
    }

    // JWT assinado com a chave privada (RS256), trocado pelo token de acesso.
    private static function jwt(array $chave): string
    {
        $agora = time();
        $cabecalho = self::base64Url(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
        $conteudo = self::base64Url(json_encode([
            'iss' => $chave['client_email'],
            'scope' => self::ESCOPO,
            'aud' => 'https://oauth2.googleapis.com/token',
            'iat' => $agora,
            'exp' => $agora + 3600,
        ]));

        $assinatura = '';
        if (!openssl_sign("{$cabecalho}.{$conteudo}", $assinatura, $chave['private_key'], OPENSSL_ALGO_SHA256)) {
            throw new RuntimeException('Não foi possível assinar o token do Firebase.');
        }

        return "{$cabecalho}.{$conteudo}." . self::base64Url($assinatura);
    }

    private static function base64Url(string $texto): string
    {
        return rtrim(strtr(base64_encode($texto), '+/', '-_'), '=');
    }

    private static function post(string $url, string $corpo, array $cabecalhos): array
    {
        $curl = curl_init($url);
        curl_setopt_array($curl, [
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => $corpo,
            CURLOPT_HTTPHEADER => $cabecalhos,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_CONNECTTIMEOUT => 5,
            CURLOPT_TIMEOUT => 10,
        ]);

        $resposta = curl_exec($curl);
        $erro = curl_error($curl);
        $status = (int) curl_getinfo($curl, CURLINFO_HTTP_CODE);
        curl_close($curl);

        if ($resposta === false) {
            throw new RuntimeException("Falha de conexão com {$url}: {$erro}");
        }

        return [$status, (string) $resposta];
    }
}
