<?php

class ProdutoMercado
{
    public ?int $id_produto_mercado;
    public int $id_produto;
    public int $id_mercado;
    public float $nu_valor;
    public int $nu_qtde;
    public bool $fl_promocao;
    public bool $fl_disponivel;
    public string $dt_atualizacao;

    public function __construct(
        ?int $id_produto_mercado,
        int $id_produto,
        int $id_mercado,
        float $nu_valor,
        int $nu_qtde,
        bool $fl_promocao,
        bool $fl_disponivel,
        string $dt_atualizacao
    ) {
        $this->id_produto_mercado = $id_produto_mercado;
        $this->id_produto         = $id_produto;
        $this->id_mercado         = $id_mercado;
        $this->nu_valor           = $nu_valor;
        $this->nu_qtde            = $nu_qtde;
        $this->fl_promocao        = $fl_promocao;
        $this->fl_disponivel      = $fl_disponivel;
        $this->dt_atualizacao     = $dt_atualizacao;
    }

    public static function fromArray(array $dados): ProdutoMercado
    {
        return new ProdutoMercado(
            isset($dados["id_produto_mercado"]) ? (int) $dados["id_produto_mercado"] : null,
            (int) ($dados["id_produto"] ?? 0),
            (int) ($dados["id_mercado"] ?? 0),
            (float) ($dados["nu_valor"] ?? 0.0),
            (int) ($dados["nu_qtde"] ?? 0),
            (bool) ($dados["fl_promocao"] ?? false),
            (bool) ($dados["fl_disponivel"] ?? false),
            trim($dados["dt_atualizacao"] ?? "")
        );
    }
}