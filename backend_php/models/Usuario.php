<?php

class Usuario
{
    public ?int $id_usuario;
    public string $nu_cpf;
    public string $nm_usuario;
    public string $ds_email;
    public string $dt_nascimento;
    public string $ds_senha;

    public function __construct(
        ?int $id_usuario,
        string $nu_cpf,
        string $nm_usuario,
        string $ds_email,
        string $dt_nascimento,
        string $ds_senha
    ) {
        $this->id_usuario    = $id_usuario;
        $this->nu_cpf        = $nu_cpf;
        $this->nm_usuario    = $nm_usuario;
        $this->ds_email      = $ds_email;
        $this->dt_nascimento = $dt_nascimento;
        $this->ds_senha      = $ds_senha;
    }

    public static function fromArray(array $dados): Usuario
    {
        return new Usuario(
            isset($dados["id_usuario"]) ? (int) $dados["id_usuario"] : null,
            trim($dados["nu_cpf"] ?? ""),
            trim($dados["nm_usuario"] ?? ""),
            trim($dados["ds_email"] ?? ""),
            trim($dados["dt_nascimento"] ?? ""),
            trim($dados["ds_senha"] ?? "")
        );
    }
}