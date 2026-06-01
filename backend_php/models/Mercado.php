<?php

class Mercado
{
    public ?int $id_mercado;
    public string $nu_cnpj;
    public string $nm_mercado;
    public string $ds_email;
    public int $nu_cep;
    public string $nm_endereco;
    public string $ds_senha;
    public bool $fl_motoboy;
    public string $ds_foto_mercado;
    public float $nu_latitude;
    public float $nu_longitude;
    public float $nu_avg_nota;
    public int $nul_avaliacoes;

    public function __construct(
        ?int $id_mercado,
        string $nu_cnpj,
        string $nm_mercado,
        string $ds_email,
        int $nu_cep,
        string $nm_endereco,
        string $ds_senha,
        bool $fl_motoboy,
        string $ds_foto_mercado,
        float $nu_latitude,
        float $nu_longitude,
        float $nu_avg_nota,
        int $nul_avaliacoes
    ) {
        $this->id_mercado      = $id_mercado;
        $this->nu_cnpj         = $nu_cnpj;
        $this->nm_mercado      = $nm_mercado;
        $this->ds_email        = $ds_email;
        $this->nu_cep          = $nu_cep;
        $this->nm_endereco     = $nm_endereco;
        $this->ds_senha        = $ds_senha;
        $this->fl_motoboy      = $fl_motoboy;
        $this->ds_foto_mercado = $ds_foto_mercado;
        $this->nu_latitude     = $nu_latitude;
        $this->nu_longitude    = $nu_longitude;
        $this->nu_avg_nota     = $nu_avg_nota;
        $this->nul_avaliacoes  = $nul_avaliacoes;
    }

    public static function fromArray(array $dados): Mercado
    {
        return new Mercado(
            isset($dados["id_mercado"]) ? (int) $dados["id_mercado"] : null,
            trim($dados["nu_cnpj"] ?? ""),
            trim($dados["nm_mercado"] ?? ""),
            trim($dados["ds_email"] ?? ""),
            (int) ($dados["nu_cep"] ?? 0),
            trim($dados["nm_endereco"] ?? ""),
            trim($dados["ds_senha"] ?? ""),
            (bool) ($dados["fl_motoboy"] ?? false),
            trim($dados["ds_foto_mercado"] ?? ""),
            (float) ($dados["nu_latitude"] ?? 0.0),
            (float) ($dados["nu_longitude"] ?? 0.0),
            (float) ($dados["nu_avg_nota"] ?? 0.0),
            (int) ($dados["nul_avaliacoes"] ?? 0)
        );
    }
}