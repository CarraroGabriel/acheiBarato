<?php

require_once __DIR__ . '/../models/Favorito.php';
require_once __DIR__ . '/../helpers/Response.php';

class FavoritoController
{
    private Favorito $favorito;

    public function __construct()
    {
        $this->favorito = new Favorito();
    }

    public function listar(int $idUsuario): void
    {
        try {
            Response::json(true, 'Favoritos consultados com sucesso.', [
                'mercados' => $this->favorito->listarMercados($idUsuario),
                'produtos' => $this->favorito->listarProdutos($idUsuario),
            ], 200);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao consultar favoritos.', null, 500);
        }
    }

    public function listarMercados(int $idUsuario): void
    {
        try {
            Response::json(
                true,
                'Mercados favoritos consultados com sucesso.',
                $this->favorito->listarMercados($idUsuario),
                200
            );
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao consultar mercados favoritos.', null, 500);
        }
    }

    public function listarProdutos(int $idUsuario): void
    {
        try {
            Response::json(
                true,
                'Produtos favoritos consultados com sucesso.',
                $this->favorito->listarProdutos($idUsuario),
                200
            );
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao consultar produtos favoritos.', null, 500);
        }
    }
}
