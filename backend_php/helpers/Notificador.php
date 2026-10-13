<?php

require_once __DIR__ . '/Firebase.php';
require_once __DIR__ . '/../models/Notificacao.php';
require_once __DIR__ . '/../models/ProdutoMercado.php';

class Notificador
{
    public static function aposAlterarOferta(array $antes, array $depois): void
    {
        $promocaoAtivada = !self::bool($antes['fl_promocao']) && self::bool($depois['fl_promocao']);

        $disponivelAntes = self::bool($antes['fl_disponivel']);
        $disponivelDepois = self::bool($depois['fl_disponivel']);
        $limite = ProdutoMercado::LIMITE_ESTOQUE_BAIXO;

        $ficouIndisponivel = $disponivelAntes && !$disponivelDepois;
        $estoqueFicouBaixo = $disponivelDepois
            && (int) $depois['nu_qtde'] <= $limite
            && (!$disponivelAntes || (int) $antes['nu_qtde'] > $limite);

        if ($promocaoAtivada && $disponivelDepois) {
            self::executar(fn() => self::promocao($depois));
        }
        if ($ficouIndisponivel) {
            self::executar(fn() => self::avisoMercado(
                $depois,
                'PRODUTO_INDISPONIVEL',
                'Produto indisponível',
                self::nomeItem($depois) . ' está marcado como indisponível.'
            ));
        }
        if ($estoqueFicouBaixo) {
            $qtde = (int) $depois['nu_qtde'];
            self::executar(fn() => self::avisoMercado(
                $depois,
                'ESTOQUE_BAIXO',
                'Estoque baixo',
                self::nomeItem($depois) . ($qtde === 1 ? ': resta 1 unidade.' : ": restam {$qtde} unidades.")
            ));
        }
    }

    private static function promocao(array $oferta): void
    {
        $titulo = self::limitar('🔥 Promoção no ' . $oferta['nm_mercado'], 60);
        $mensagem = self::limitar(sprintf(
            '%s com %d%% OFF: de %s por %s',
            self::nomeItem($oferta),
            (int) $oferta['nu_desconto'],
            self::moeda($oferta['nu_valor']),
            self::moeda($oferta['nu_valor_final'])
        ), 200);

        $criadas = (new Notificacao())->criarPromocao($oferta, $titulo, $mensagem);
        if ($criadas === 0) {
            return; // ninguém favoritou o mercado nem o item
        }

        Firebase::enviarParaTopicos(
            ['mercado_' . (int) $oferta['id_mercado'], 'item_' . (int) $oferta['id_item_produto']],
            $titulo,
            $mensagem,
            [
                'tipo' => 'PROMOCAO',
                'id_item_produto' => (int) $oferta['id_item_produto'],
                'id_produto_mercado' => (int) $oferta['id_produto_mercado'],
            ]
        );
    }

    private static function avisoMercado(array $oferta, string $tipo, string $titulo, string $mensagem): void
    {
        $mensagem = self::limitar($mensagem, 200);

        (new Notificacao())->criarParaMercado(
            (int) $oferta['id_mercado'],
            $tipo,
            (int) $oferta['id_produto_mercado'],
            $titulo,
            $mensagem
        );

        Firebase::enviarParaTopicos(
            ['lojista_' . (int) $oferta['id_mercado']],
            $titulo,
            $mensagem,
            ['tipo' => $tipo, 'id_produto_mercado' => (int) $oferta['id_produto_mercado']]
        );
    }

    // Falha no envio não pode impedir o lojista de salvar o produto.
    private static function executar(callable $acao): void
    {
        try {
            $acao();
        } catch (Throwable $e) {
            error_log('[Notificador] ' . $e->getMessage());
        }
    }

    private static function nomeItem(array $oferta): string
    {
        return trim($oferta['ds_item_produto'] . ' ' . $oferta['nm_marca']);
    }

    private static function moeda(mixed $valor): string
    {
        return 'R$ ' . number_format((float) $valor, 2, ',', '.');
    }

    private static function limitar(string $texto, int $tamanho): string
    {
        return preg_match('/^.{0,' . $tamanho . '}/u', $texto, $m) ? $m[0] : $texto;
    }

    private static function bool(mixed $valor): bool
    {
        if (is_bool($valor)) {
            return $valor;
        }
        return in_array(strtolower((string) $valor), ['t', 'true', '1'], true);
    }
}
