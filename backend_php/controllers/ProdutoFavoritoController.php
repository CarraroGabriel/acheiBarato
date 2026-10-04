<?php

require_once __DIR__ . '/../models/ProdutoFavorito.php';
require_once __DIR__ . '/../helpers/Response.php';

class ProdutoFavoritoController
{
    private ProdutoFavorito $favorito;

    public function __construct()
    {
        $this->favorito = new ProdutoFavorito();
    }

    public function consultar(): void
    {
        [$u, $i] = $this->ids($_GET);
        try {
            Response::json(true, 'Consulta realizada.',
                ['favorito' => $this->favorito->existe($u, $i)], 200);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao consultar favorito.', null, 500);
        }
    }

    public function adicionar(): void
    {
        $dados = json_decode(file_get_contents('php://input'), true);
        [$u, $i] = $this->ids(is_array($dados) ? $dados : []);
        try {
            $this->favorito->adicionar($u, $i);
            Response::json(true, 'Produto favoritado.', ['favorito' => true], 201);
        } catch (PDOException $e) {
            // 23503 = FK: usuário ou produto inexistente.
            if ($e->getCode() === '23503') {
                Response::json(false, 'Usuário ou produto não encontrado.', null, 404);
            }
            Response::json(false, 'Erro ao favoritar produto.', null, 500);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao favoritar produto.', null, 500);
        }
    }

    public function remover(): void
    {
        [$u, $i] = $this->ids($_GET);
        try {
            $this->favorito->remover($u, $i);
            Response::json(true, 'Favorito removido.', ['favorito' => false], 200);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao remover favorito.', null, 500);
        }
    }

    private function ids(array $origem): array
    {
        $u = (int) ($origem['id_usuario'] ?? 0);
        $i = (int) ($origem['id_item_produto'] ?? 0);

        if ($u <= 0 || $i <= 0) {
            Response::json(false, 'Informe id_usuario e id_item_produto.', null, 400);
        }
        return [$u, $i];
    }
}
