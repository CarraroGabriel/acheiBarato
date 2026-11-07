<?php

class Env
{
    private static bool $carregado = false;

    // Lê o arquivo .env da API uma única vez por requisição.
    public static function carregar(): void
    {
        if (self::$carregado) {
            return;
        }
        self::$carregado = true;

        $caminho = __DIR__ . '/../.env';
        if (!file_exists($caminho)) {
            return;
        }

        $linhas = file($caminho, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);

        foreach ($linhas as $linha) {
            $linha = trim($linha);

            if ($linha === '' || str_starts_with($linha, '#') || !str_contains($linha, '=')) {
                continue;
            }

            [$chave, $valor] = explode('=', $linha, 2);
            $chave = trim($chave);
            $valor = trim($valor, " \t\n\r\0\x0B\"'");

            putenv("{$chave}={$valor}");
        }
    }
}
