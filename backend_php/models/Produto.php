<?php

class Produto
{
    public ?int $id_produto;
    public string $nm_produto;
    public string $nm_marca;
    public string $ds_categoria;
    public string $ds_foto_produto;

    public function __construct(
        ?int $id_produto,
        string $nm_produto,
        string $nm_marca,
        string $ds_categoria,
        string $ds_foto_produto
    ) {
        $this->id_produto      = $id_produto;
        $this->nm_produto      = $nm_produto;
        $this->nm_marca        = $nm_marca;
        $this->ds_categoria    = $ds_categoria;
        $this->ds_foto_produto = $ds_foto_produto;
    }

    public static function fromArray(array $dados): Produto
    {
        return new Produto(
            isset($dados["id_produto"]) ? (int) $dados["id_produto"] : null,
            trim($dados["nm_produto"] ?? ""),
            trim($dados["nm_marca"] ?? ""),
            trim($dados["ds_categoria"] ?? ""),
            trim($dados["ds_foto_produto"] ?? "")
        );
    }
}