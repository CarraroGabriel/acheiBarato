<?php

require_once __DIR__ . '/../models/Mercado.php';
require_once __DIR__ . '/../models/ProdutoMercado.php';
require_once __DIR__ . '/../models/AvaliacaoMercado.php';
require_once __DIR__ . '/../helpers/Response.php';
require_once __DIR__ . '/../helpers/Imagem.php';

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
        $busca = trim((string) ($_GET['busca'] ?? ''));

        if (strlen($busca) > 200) {
            Response::json(false, 'Texto de busca muito longo.', null, 400);
        }

        $motoboy = match ($_GET['motoboy'] ?? '') {
            'sim' => true,
            'nao' => false,
            default => null,
        };

        try {
            Response::json(true, 'Mercados encontrados.', $this->mercado->listar($busca, $motoboy), 200);
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

    public function resumo(int $idMercado): void
    {
        try {
            $resumo = $this->mercado->resumo($idMercado);

            if ($resumo === null) {
                Response::json(false, 'Mercado não encontrado.', null, 404);
            }

            Response::json(true, 'Resumo do mercado consultado com sucesso.', $resumo, 200);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao consultar o resumo do mercado.', null, 500);
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

    public function alterarPerfil(int $idMercado): void
    {
        $dados = $this->lerJson();

        try {
            $perfil = [
                'nm_mercado' => trim((string) ($dados['nm_mercado'] ?? '')),
                'ds_email' => trim((string) ($dados['ds_email'] ?? '')),
                'nu_cep' => preg_replace('/\D/', '', (string) ($dados['nu_cep'] ?? '')),
                'nm_endereco' => trim((string) ($dados['nm_endereco'] ?? '')),
                'nu_numero' => trim((string) ($dados['nu_numero'] ?? '')),
                'fl_motoboy' => (bool) ($dados['fl_motoboy'] ?? false),
                'horarios' => $this->lerHorarios($dados),
            ];

            if (!preg_match('/^.{1,30}$/u', $perfil['nm_mercado'])) {
                throw new InvalidArgumentException('Informe um nome com até 30 caracteres.');
            }

            if (!filter_var($perfil['ds_email'], FILTER_VALIDATE_EMAIL) || strlen($perfil['ds_email']) > 50) {
                throw new InvalidArgumentException('Informe um e-mail válido.');
            }

            if (strlen($perfil['nu_cep']) !== 8) {
                throw new InvalidArgumentException('O CEP deve possuir 8 dígitos.');
            }
            $perfil['nu_cep'] = (int) $perfil['nu_cep'];

            if (!preg_match('/^.{1,50}$/u', $perfil['nm_endereco'])) {
                throw new InvalidArgumentException('Informe um endereço com até 50 caracteres.');
            }

            if (!preg_match('/^.{1,10}$/u', $perfil['nu_numero'])) {
                throw new InvalidArgumentException('Informe o número com até 10 caracteres (use S/N se não houver).');
            }

            $perfil = array_merge($perfil, $this->lerComplementoEndereco($dados));

            $perfil['nu_taxa_entrega'] = 0.0;

            if ($perfil['fl_motoboy']) {
                $taxa = str_replace(',', '.', trim((string) ($dados['nu_taxa_entrega'] ?? '')));

                if ($taxa === '' || !is_numeric($taxa) || (float) $taxa < 0 || (float) $taxa > 999.99) {
                    throw new InvalidArgumentException('Informe a taxa de entrega (use 0 para entrega grátis).');
                }

                $perfil['nu_taxa_entrega'] = round((float) $taxa, 2);
            }

            $resultado = $this->mercado->alterarPerfil($idMercado, $perfil);

            if ($resultado === null) {
                Response::json(false, 'Mercado não encontrado.', null, 404);
            }

            Response::json(true, 'Perfil atualizado com sucesso.', $resultado, 200);
        } catch (InvalidArgumentException $e) {
            Response::json(false, $e->getMessage(), null, 400);
        } catch (PDOException $e) {
            if ($e->getCode() === '23505') {
                Response::json(false, 'Este e-mail já está em uso.', null, 409);
            }
            Response::json(false, 'Erro ao atualizar perfil.', null, 500);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao atualizar perfil.', null, 500);
        }
    }

    public function enviarFoto(int $idMercado): void
    {
        try {
            $mercado = $this->mercado->consultarPorId($idMercado);

            if ($mercado === null) {
                Response::json(false, 'Mercado não encontrado.', null, 404);
            }

            $novoCaminho = Imagem::salvarUpload(
                $_FILES['foto'] ?? [],
                'mercados',
                $idMercado,
                (string) $mercado['nm_mercado']
            );

            $this->mercado->alterarFoto($idMercado, $novoCaminho);
            Imagem::remover($mercado['ds_foto_mercado'], $novoCaminho);

            Response::json(true, 'Foto do mercado atualizada.', ['ds_foto_mercado' => $novoCaminho], 200);
        } catch (InvalidArgumentException $e) {
            Response::json(false, $e->getMessage(), null, 400);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao salvar a foto do mercado.', null, 500);
        }
    }

    public function consultarAvaliacao(int $idMercado): void
    {
        $idUsuario = (int) ($_GET['id_usuario'] ?? 0);

        if ($idUsuario <= 0) {
            Response::json(false, 'Informe o id_usuario.', null, 400);
        }

        try {
            $nota = (new AvaliacaoMercado())->consultarNota($idUsuario, $idMercado);
            Response::json(true, 'Avaliação consultada.', ['nu_nota' => $nota], 200);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao consultar avaliação.', null, 500);
        }
    }

    public function avaliar(int $idMercado): void
    {
        $dados = $this->lerJson();
        $idUsuario = (int) ($dados['id_usuario'] ?? 0);
        $nota = filter_var($dados['nu_nota'] ?? null, FILTER_VALIDATE_INT);

        if ($idUsuario <= 0) {
            Response::json(false, 'Informe o id_usuario.', null, 400);
        }

        if ($nota === false || $nota < 1 || $nota > 5) {
            Response::json(false, 'A nota deve ser de 1 a 5 estrelas.', null, 400);
        }

        try {
            $resultado = (new AvaliacaoMercado())->avaliar($idUsuario, $idMercado, $nota);
            Response::json(true, 'Avaliação registrada. Obrigado!', $resultado, 200);
        } catch (PDOException $e) {
            // 23503 = FK: usuário ou mercado inexistente.
            if ($e->getCode() === '23503') {
                Response::json(false, 'Usuário ou mercado não encontrado.', null, 404);
            }
            Response::json(false, 'Erro ao registrar avaliação.', null, 500);
        } catch (Throwable $e) {
            Response::json(false, 'Erro ao registrar avaliação.', null, 500);
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

    /**
     * Valida a lista de horários enviada no perfil.
     * Retorna null se o campo não foi enviado (horários atuais são mantidos).
     */
    private function lerHorarios(array $dados): ?array
    {
        if (!array_key_exists('horarios', $dados)) {
            return null;
        }

        if (!is_array($dados['horarios'])) {
            throw new InvalidArgumentException('Horários inválidos.');
        }

        $nomesDias = ['domingo', 'segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado'];
        $formatoHora = '/^([01]\d|2[0-3]):[0-5]\d$/';
        $porDia = [];

        foreach ($dados['horarios'] as $faixa) {
            if (!is_array($faixa)) {
                throw new InvalidArgumentException('Horários inválidos.');
            }

            $dia = filter_var($faixa['nu_dia_semana'] ?? null, FILTER_VALIDATE_INT);
            $abertura = (string) ($faixa['hr_abertura'] ?? '');
            $fechamento = (string) ($faixa['hr_fechamento'] ?? '');

            if ($dia === false || $dia < 0 || $dia > 6) {
                throw new InvalidArgumentException('Dia da semana inválido.');
            }

            if (!preg_match($formatoHora, $abertura) || !preg_match($formatoHora, $fechamento)) {
                throw new InvalidArgumentException('Informe os horários no formato HH:MM.');
            }

            if ($fechamento <= $abertura) {
                throw new InvalidArgumentException(
                    "No(a) {$nomesDias[$dia]}, o fechamento deve ser depois da abertura."
                );
            }

            $porDia[$dia][] = [
                'nu_dia_semana' => $dia,
                'hr_abertura' => $abertura,
                'hr_fechamento' => $fechamento,
            ];
        }

        $horarios = [];

        foreach ($porDia as $dia => $faixas) {
            usort($faixas, fn(array $a, array $b) => strcmp($a['hr_abertura'], $b['hr_abertura']));

            for ($i = 1; $i < count($faixas); $i++) {
                if ($faixas[$i]['hr_abertura'] < $faixas[$i - 1]['hr_fechamento']) {
                    throw new InvalidArgumentException("Os horários de {$nomesDias[$dia]} se sobrepõem.");
                }
            }

            array_push($horarios, ...$faixas);
        }

        return $horarios;
    }

    private function lerJson(): array
    {
        $dados = json_decode(file_get_contents('php://input'), true);
        return is_array($dados) ? $dados : [];
    }

    private function lerComplementoEndereco(array $dados): array
    {
        $complemento = [
            'nm_bairro' => trim((string) ($dados['nm_bairro'] ?? '')),
            'nm_cidade' => trim((string) ($dados['nm_cidade'] ?? '')),
            'sg_uf' => strtoupper(trim((string) ($dados['sg_uf'] ?? ''))),
            'nu_latitude' => (float) ($dados['nu_latitude'] ?? 0),
            'nu_longitude' => (float) ($dados['nu_longitude'] ?? 0),
        ];

        if (!preg_match('/^.{0,40}$/u', $complemento['nm_bairro'])) {
            throw new InvalidArgumentException('Informe um bairro com até 40 caracteres.');
        }

        if (!preg_match('/^.{1,40}$/u', $complemento['nm_cidade'])) {
            throw new InvalidArgumentException('Informe uma cidade com até 40 caracteres.');
        }

        if (!preg_match('/^[A-Z]{2}$/', $complemento['sg_uf'])) {
            throw new InvalidArgumentException('Informe a UF com 2 letras.');
        }

        if (abs($complemento['nu_latitude']) > 90 || abs($complemento['nu_longitude']) > 180) {
            throw new InvalidArgumentException('Coordenadas do mercado inválidas.');
        }

        return $complemento;
    }

    private function normalizarEValidar(array $dados, bool $senhaObrigatoria): array
    {
        $obrigatorios = ['nu_cnpj', 'nm_mercado', 'ds_email', 'nu_cep', 'nm_endereco', 'nu_numero'];

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

        $dados['nu_numero'] = trim((string) $dados['nu_numero']);

        if (!preg_match('/^.{1,10}$/u', $dados['nu_numero'])) {
            throw new InvalidArgumentException('Informe o número com até 10 caracteres (use S/N se não houver).');
        }

        $dados = array_merge($dados, $this->lerComplementoEndereco($dados));

        $dados['fl_motoboy'] = (bool) ($dados['fl_motoboy'] ?? false);
        $dados['ds_foto_mercado'] = (string) ($dados['ds_foto_mercado'] ?? '');
        $dados['nu_avg_nota'] = (float) ($dados['nu_avg_nota'] ?? 0);
        $dados['nul_avaliacoes'] = (int) ($dados['nul_avaliacoes'] ?? 0);

        return $dados;
    }
}
