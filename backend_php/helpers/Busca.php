<?php

/*
 * Pesquisa por texto ignorando maiúsculas e acentos ("feijao" encontra "FEIJÃO").
 * Usa TRANSLATE do PostgreSQL, sem depender da extensão unaccent.
 * Cada palavra digitada precisa aparecer no texto pesquisado (busca "arroz tio" = arroz E tio).
 */
class Busca
{
    private const COM_ACENTO = 'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇáàâãäéèêëíìîïóòôõöúùûüç';
    private const SEM_ACENTO = 'AAAAAEEEEIIIIOOOOOUUUUCaaaaaeeeeiiiiooooouuuuc';
    private const MAXIMO_PALAVRAS = 5;

    public static function semAcento(string $expressao): string
    {
        return "UPPER(TRANSLATE({$expressao}, '" . self::COM_ACENTO . "', '" . self::SEM_ACENTO . "'))";
    }

    public static function palavras(?string $texto): array
    {
        $texto = trim((string) $texto);

        if ($texto === '') {
            return [];
        }

        $palavras = preg_split('/\s+/u', $texto);
        return array_slice($palavras, 0, self::MAXIMO_PALAVRAS);
    }

    /**
     * Monta "texto contém palavra1 AND texto contém palavra2 ...".
     * Retorna [fragmento SQL, parâmetros]. Os valores vão sempre como parâmetros (sem concatenação).
     */
    public static function condicao(string $expressaoTexto, array $palavras, string $prefixo): array
    {
        $partes = [];
        $parametros = [];

        foreach ($palavras as $i => $palavra) {
            $nome = ":{$prefixo}{$i}";
            $partes[] = self::semAcento($expressaoTexto) . " LIKE '%' || " . self::semAcento($nome) . " || '%'";
            $parametros[$nome] = self::escaparLike($palavra);
        }

        return [implode(' AND ', $partes), $parametros];
    }

    public static function escaparLike(string $texto): string
    {
        return str_replace(['\\', '%', '_'], ['\\\\', '\\%', '\\_'], $texto);
    }
}
