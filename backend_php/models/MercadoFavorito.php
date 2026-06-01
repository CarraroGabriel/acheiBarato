<?php

class MercadoFavorito
{
    public ?int $id_mercado_fav;
    public int $id_mercado;
    public int $id_usuario;

    public function __construct(
        ?int $id_mercado_fav,
        int $id_mercado,
        int $id_usuario
    ) {
        $this->id_mercado_fav = $id_mercado_fav;
        $this->id_mercado     = $id_mercado;
        $this->id_usuario     = $id_usuario;
    }

    public static function fromArray(array $dados): MercadoFavorito
    {
        return new MercadoFavorito(
            isset($dados["id_mercado_fav"]) ? (int) $dados["id_mercado_fav"] : null,
            (int) ($dados["id_mercado"] ?? 0),
            (int) ($dados["id_usuario"] ?? 0)
        );
    }
}