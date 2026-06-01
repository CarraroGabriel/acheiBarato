<?php

class Carrinho
{
    public ?int $id_carrinho;
    public bool $fl_ativo;
    public int $id_usuario;

    public function __construct(
        ?int $id_carrinho,
        bool $fl_ativo,
        int $id_usuario
    ) {
        $this->id_carrinho = $id_carrinho;
        $this->fl_ativo    = $fl_ativo;
        $this->id_usuario  = $id_usuario;
    }

    public static function fromArray(array $dados): Carrinho
    {
        return new Carrinho(
            isset($dados["id_carrinho"]) ? (int) $dados["id_carrinho"] : null,
            (bool) ($dados["fl_ativo"] ?? false),
            (int) ($dados["id_usuario"] ?? 0)
        );
    }
}