<?php

class ItemCarrinho
{
    public ?int $id_item_carrinho;
    public int $id_carrinho;
    public int $id_produto;
    public float $vl_total;
    public int $nu_qtde;
    public string $dt_compra;

    public function __construct(
        ?int $id_item_carrinho,
        int $id_carrinho,
        int $id_produto,
        float $vl_total,
        int $nu_qtde,
        string $dt_compra
    ) {
        $this->id_item_carrinho = $id_item_carrinho;
        $this->id_carrinho      = $id_carrinho;
        $this->id_produto       = $id_produto;
        $this->vl_total         = $vl_total;
        $this->nu_qtde          = $nu_qtde;
        $this->dt_compra        = $dt_compra;
    }

    public static function fromArray(array $dados): ItemCarrinho
    {
        return new ItemCarrinho(
            isset($dados["id_item_carrinho"]) ? (int) $dados["id_item_carrinho"] : null,
            (int) ($dados["id_carrinho"] ?? 0),
            (int) ($dados["id_produto"] ?? 0),
            (float) ($dados["vl_total"] ?? 0.0),
            (int) ($dados["nu_qtde"] ?? 0),
            trim($dados["dt_compra"] ?? "")
        );
    }
}