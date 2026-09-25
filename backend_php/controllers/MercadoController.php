<?php

require_once __DIR__ . '/../models/Mercado.php';
require_once __DIR__ . '/../models/ProdutoMercado.php';
require_once __DIR__ . '/../helpers/Response.php';

class MercadoController
{
    private Mercado $mercado;
    private ProdutoMercado $produtoMercado;

    public function __construct()
    {
        $this->mercado = new Mercado();
        $this->produtoMercado = new ProdutoMercado();
    }

    public function listar(): void
    {
        try {
            Response::json(true, 'Mercados encontrados.', $this->mercado->listar(), 200);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao consultar mercados.', null, 500);
        }
    }

    public function consultar(int $idMercado): void
    {
        try {
            $dados = $this->mercado->consultarPorId($idMercado);

            if ($dados === null) {
                Response::json(false, 'Mercado não encontrado.', null, 404);
            }

            Response::json(true, 'Mercado encontrado.', $dados, 200);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao consultar mercado.', null, 500);
        }
    }

    public function listarPromocoes(int $idMercado): void
    {
        try {
            Response::json(
                true,
                'Promoções do mercado encontradas.',
                $this->produtoMercado->listarPromocoes($idMercado),
                200
            );
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao consultar promoções do mercado.', null, 500);
        }
    }

    public function inserir(): void
    {
        $dados = $this->lerJson();

        try {
            $dados = $this->normalizarEValidar($dados, true);
            $resultado = $this->mercado->inserir($dados);
            Response::json(true, 'Mercado cadastrado com sucesso.', $resultado, 201);
        } catch (PDOException $e) {
            if ($e->getCode() === '23505') {
                Response::json(false, 'CNPJ ou e-mail já cadastrado.', null, 409);
            }
            Response::json(false, 'Erro ao cadastrar mercado.', null, 500);
        } catch (InvalidArgumentException $e) {
            Response::json(false, $e->getMessage(), null, 400);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao cadastrar mercado.', null, 500);
        }
    }

    public function alterar(int $idMercado): void
    {
        $dados = $this->lerJson();

        try {
            $dados = $this->normalizarEValidar($dados, false);
            $resultado = $this->mercado->alterar($idMercado, $dados);

            if ($resultado === null) {
                Response::json(false, 'Mercado não encontrado.', null, 404);
            }

            Response::json(true, 'Mercado alterado com sucesso.', $resultado, 200);
        } catch (InvalidArgumentException $e) {
            Response::json(false, $e->getMessage(), null, 400);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao alterar mercado.', null, 500);
        }
    }

    public function excluir(int $idMercado): void
    {
        try {
            if (!$this->mercado->excluir($idMercado)) {
                Response::json(false, 'Mercado não encontrado.', null, 404);
            }

            Response::json(true, 'Mercado removido com sucesso.', ['id_mercado' => $idMercado], 200);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao remover mercado.', null, 500);
        }
    }

    private function lerJson(): array
    {
        $dados = json_decode(file_get_contents('php://input'), true);
        return is_array($dados) ? $dados : [];
    }

    private function normalizarEValidar(array $dados, bool $senhaObrigatoria): array
    {
        $obrigatorios = ['nu_cnpj', 'nm_mercado', 'ds_email', 'nu_cep', 'nm_endereco'];

        foreach ($obrigatorios as $campo) {
            if (!isset($dados[$campo]) || trim((string) $dados[$campo]) === '') {
                throw new InvalidArgumentException("O campo {$campo} é obrigatório.");
            }
        }

        if ($senhaObrigatoria && (!isset($dados['ds_senha']) || trim((string) $dados['ds_senha']) === '')) {
            throw new InvalidArgumentException('O campo ds_senha é obrigatório.');
        }

        $dados['nu_cnpj'] = preg_replace('/\D/', '', (string) $dados['nu_cnpj']);
        $dados['nu_cep'] = (int) preg_replace('/\D/', '', (string) $dados['nu_cep']);

        if (strlen($dados['nu_cnpj']) !== 14) {
            throw new InvalidArgumentException('O CNPJ deve possuir 14 dígitos.');
        }

        if (!filter_var($dados['ds_email'], FILTER_VALIDATE_EMAIL)) {
            throw new InvalidArgumentException('Informe um e-mail válido.');
        }

        $dados['fl_motoboy'] = (bool) ($dados['fl_motoboy'] ?? false);
        $dados['ds_foto_mercado'] = (string) ($dados['ds_foto_mercado'] ?? '');
        $dados['nu_latitude'] = (float) ($dados['nu_latitude'] ?? 0);
        $dados['nu_longitude'] = (float) ($dados['nu_longitude'] ?? 0);
        $dados['nu_avg_nota'] = (float) ($dados['nu_avg_nota'] ?? 0);
        $dados['nul_avaliacoes'] = (int) ($dados['nul_avaliacoes'] ?? 0);

        return $dados;
    }
}
