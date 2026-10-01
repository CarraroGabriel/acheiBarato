<?php

require_once __DIR__ . '/../models/MercadoFavorito.php';
require_once __DIR__ . '/../helpers/Response.php';

class MercadoFavoritoController
{
    private MercadoFavorito $favorito;

    public function __construct()
    {
        $this->favorito = new MercadoFavorito();
    }

    public function consultar(): void
    {
        [$u, $m] = $this->ids($_GET);
        try {
            Response::json(true, 'Consulta realizada.',
                ['favorito' => $this->favorito->existe($u, $m)], 200);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao consultar favorito.', null, 500);
        }
    }

    public function adicionar(): void
    {
        $dados = json_decode(file_get_contents('php://input'), true);
        [$u, $m] = $this->ids(is_array($dados) ? $dados : []);
        try {
            $this->favorito->adicionar($u, $m);
            Response::json(true, 'Mercado favoritado.', ['favorito' => true], 201);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao favoritar mercado.', null, 500);
        }
    }

    public function remover(): void
    {
        [$u, $m] = $this->ids($_GET);
        try {
            $this->favorito->remover($u, $m);
            Response::json(true, 'Favorito removido.', ['favorito' => false], 200);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao remover favorito.', null, 500);
        }
    }

    private function ids(array $origem): array
    {
        $u = (int) ($origem['id_usuario'] ?? 0);
        $m = (int) ($origem['id_mercado'] ?? 0);

        if ($u <= 0 || $m <= 0) {
            Response::json(false, 'Informe id_usuario e id_mercado.', null, 400);
        }
        return [$u, $m];
    }
}