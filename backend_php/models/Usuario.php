<?php

class Usuario
{
    public ?int $id_usuario;
    public string $nm_login;
    public string $ds_senha;

    public function __construct(
        ?int $id_usuario,
        string $nm_login,
        string $ds_senha
    ) {
        $this->id_usuario = $id_usuario;
        $this->nm_login = $nm_login;
        $this->ds_senha = $ds_senha;
    }

    public static function fromArray(array $dados): Usuario
    {
        return new Usuario(
            isset($dados["id_usuario"]) ? (int) $dados["id_usuario"] : null,
            trim($dados["nm_login"] ?? ""),
            trim($dados["ds_senha"] ?? "")
        );
    }
}
