<?php
class Imagem
{
    private const TAMANHO_MAXIMO = 2 * 1024 * 1024; // 2 MB (o app já reduz a foto antes de enviar)
    private const EXTENSOES = [
        'image/jpeg' => 'jpg',
        'image/png'  => 'png',
    ];

    /**
     * @param array  $arquivo item de $_FILES (ex.: $_FILES['foto'])
     * @param string $pasta   subpasta dentro de public/uploads (mercados, produtos)
     * @param int    $id      id do registro dono da foto
     * @param string $nome    texto usado no nome do arquivo (nome do mercado/produto)
     * @return string caminho relativo a ser salvo no banco
     */
    public static function salvarUpload(array $arquivo, string $pasta, int $id, string $nome): string
    {
        $erro = $arquivo['error'] ?? UPLOAD_ERR_NO_FILE;

        if ($erro === UPLOAD_ERR_NO_FILE) {
            throw new InvalidArgumentException('Envie uma imagem no campo "foto".');
        }

        if (in_array($erro, [UPLOAD_ERR_INI_SIZE, UPLOAD_ERR_FORM_SIZE], true)
            || ($arquivo['size'] ?? 0) > self::TAMANHO_MAXIMO) {
            throw new InvalidArgumentException('A imagem deve ter no máximo 2 MB.');
        }

        if ($erro !== UPLOAD_ERR_OK || !is_uploaded_file($arquivo['tmp_name'] ?? '')) {
            throw new RuntimeException('Não foi possível receber a imagem.');
        }

        $info = @getimagesize($arquivo['tmp_name']);
        $extensao = $info ? (self::EXTENSOES[$info['mime']] ?? null) : null;

        if ($extensao === null) {
            throw new InvalidArgumentException('Envie uma imagem JPG ou PNG.');
        }

        $diretorio = __DIR__ . '/../public/uploads/' . $pasta;

        if (!is_dir($diretorio) && !mkdir($diretorio, 0755, true)) {
            throw new RuntimeException('Não foi possível salvar a imagem.');
        }

        $nomeArquivo = $id . '-' . self::slug($nome) . '.' . $extensao;

        if (!move_uploaded_file($arquivo['tmp_name'], $diretorio . '/' . $nomeArquivo)) {
            throw new RuntimeException('Não foi possível salvar a imagem.');
        }

        return 'uploads/' . $pasta . '/' . $nomeArquivo;
    }

    public static function remover(?string $caminho, ?string $exceto = null): void
    {
        if ($caminho === null || $caminho === $exceto || !str_starts_with($caminho, 'uploads/')) {
            return;
        }

        $arquivo = __DIR__ . '/../public/' . $caminho;

        if (is_file($arquivo)) {
            unlink($arquivo);
        }
    }

    public static function slug(string $texto): string
    {
        $semAcento = strtr($texto, [
            'á' => 'a', 'à' => 'a', 'â' => 'a', 'ã' => 'a', 'ä' => 'a',
            'é' => 'e', 'è' => 'e', 'ê' => 'e', 'ë' => 'e',
            'í' => 'i', 'ì' => 'i', 'î' => 'i', 'ï' => 'i',
            'ó' => 'o', 'ò' => 'o', 'ô' => 'o', 'õ' => 'o', 'ö' => 'o',
            'ú' => 'u', 'ù' => 'u', 'û' => 'u', 'ü' => 'u', 'ç' => 'c',
            'Á' => 'A', 'À' => 'A', 'Â' => 'A', 'Ã' => 'A', 'Ä' => 'A',
            'É' => 'E', 'È' => 'E', 'Ê' => 'E', 'Ë' => 'E',
            'Í' => 'I', 'Ì' => 'I', 'Î' => 'I', 'Ï' => 'I',
            'Ó' => 'O', 'Ò' => 'O', 'Ô' => 'O', 'Õ' => 'O', 'Ö' => 'O',
            'Ú' => 'U', 'Ù' => 'U', 'Û' => 'U', 'Ü' => 'U', 'Ç' => 'C',
        ]);

        $slug = trim(preg_replace('/[^a-z0-9]+/', '-', strtolower($semAcento)), '-');
        $slug = rtrim(substr($slug, 0, 60), '-');

        return $slug !== '' ? $slug : 'imagem';
    }
}
