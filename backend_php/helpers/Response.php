<?php

class Response
{
    public static function json(
        bool $sucesso,
        string $mensagem,
        mixed $dados = null,
        int $statusCode = 200
    ): void {
        http_response_code($statusCode);
        header("Content-Type: application/json; charset=UTF-8");

        echo json_encode([
            "sucesso" => $sucesso,
            "mensagem" => $mensagem,
            "dados" => $dados
        ], JSON_UNESCAPED_UNICODE);

        exit;
    }
}
