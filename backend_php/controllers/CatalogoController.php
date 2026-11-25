<?php

require_once __DIR__ . '/../models/Categoria.php';
require_once __DIR__ . '/../models/Marca.php';
require_once __DIR__ . '/../models/UnidadeMedida.php';
require_once __DIR__ . '/../helpers/Response.php';

class CatalogoController
{
    public function listarCategorias(): void
    {
        try {
            Response::json(true, 'Categorias encontradas.', (new Categoria())->listar(), 200);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao consultar categorias.', null, 500);
        }
    }

    public function listarMarcas(): void
    {
        try {
            Response::json(true, 'Marcas encontradas.', (new Marca())->listar(), 200);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao consultar marcas.', null, 500);
        }
    }

    public function listarUnidades(): void
    {
        try {
            Response::json(true, 'Unidades encontradas.', (new UnidadeMedida())->listar(), 200);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao consultar unidades.', null, 500);
        }
    }
}
