<?php

class ProdutoFavorito
{
    public ?int $id_prod_fav;
    public int $id_usuario;
    public int $id_produto;

    public function __construct(
        ?int $id_prod_fav,
        int $id_usuario,
        int $id_produto
    ) {
        $this->id_prod_fav = $id_prod_fav;
        $this->id_usuario  = $id_usuario;
        $this->id_produto  = $id_produto;
    }

    public static function fromArray(array $dados): ProdutoFavorito
    {
        return new ProdutoFavorito(
            isset($dados["id_prod_fav"]) ? (int) $dados["id_prod_fav"] : null,
            (int) ($dados["id_usuario"] ?? 0),
            (int) ($dados["id_produto"] ?? 0)
        );
    }
}