<?php

class AvaliacaoMercado
{
    public ?int $id_avaliacao;
    public int $id_usuario;
    public int $id_mercado;
    public string $dt_avaliacao;
    public int $nu_nota;

    public function __construct(
        ?int $id_avaliacao,
        int $id_usuario,
        int $id_mercado,
        string $dt_avaliacao,
        int $nu_nota
    ) {
        $this->id_avaliacao  = $id_avaliacao;
        $this->id_usuario    = $id_usuario;
        $this->id_mercado    = $id_mercado;
        $this->dt_avaliacao  = $dt_avaliacao;
        $this->nu_nota       = $nu_nota;
    }

    public static function fromArray(array $dados): AvaliacaoMercado
    {
        return new AvaliacaoMercado(
            isset($dados["id_avaliacao"]) ? (int) $dados["id_avaliacao"] : null,
            (int) ($dados["id_usuario"] ?? 0),
            (int) ($dados["id_mercado"] ?? 0),
            trim($dados["dt_avaliacao"] ?? ""),
            (int) ($dados["nu_nota"] ?? 0)
        );
    }
}