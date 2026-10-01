<?php

header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../helpers/Response.php';
require_once __DIR__ . '/../routes/usuario_routes.php';
require_once __DIR__ . '/../routes/mercado_routes.php';
require_once __DIR__ . '/../routes/produto_routes.php';
require_once __DIR__ . '/../routes/produto_mercado_routes.php';
require_once __DIR__ . '/../routes/login_routes.php';
require_once __DIR__ . '/../routes/promocao_routes.php';
require_once __DIR__ . '/../routes/mercado_favorito_routes.php';
require_once __DIR__ . '/../routes/favorito_routes.php';
require_once __DIR__ . '/../routes/catalogo_routes.php';

$metodo = $_SERVER['REQUEST_METHOD'];

if (isset($_GET['rota'])) {
    $uri = $_GET['rota'];
} else {
    $uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
}

$uri = trim((string) $uri, '/');
$partesUri = $uri === '' ? [] : explode('/', $uri);

$rotasPrincipais = [
    'usuarios',
    'mercados',
    'produtos',
    'produto_mercado',
    'login',
    'promocoes',
    'mercado_favorito',
    'favoritos',
    'categorias',
    'marcas',
    'unidades',
];

$rotaPrincipal = null;
$posicaoRota = null;

// Usa o primeiro segmento da URI que for uma rota principal, para que
// subrotas como "favoritos/mercados" não sejam confundidas com "mercados".
foreach ($partesUri as $posicao => $parte) {
    if (in_array($parte, $rotasPrincipais, true)) {
        $rotaPrincipal = $parte;
        $posicaoRota = $posicao;
        break;
    }
}

if ($rotaPrincipal === null || $posicaoRota === null) {
    Response::json(false, 'Rota não encontrada.', null, 404);
}

$rotaTratada = array_slice($partesUri, $posicaoRota);

switch ($rotaPrincipal) {
    case 'usuarios':
        tratarRotasUsuario($metodo, $rotaTratada);
        break;
    case 'mercados':
        tratarRotasMercado($metodo, $rotaTratada);
        break;
    case 'produtos':
        tratarRotasProduto($metodo, $rotaTratada);
        break;
    case 'produto_mercado':
        tratarRotasProdutoMercado($metodo, $rotaTratada);
        break;
    case 'login':
        tratarRotaLogin($metodo);
        break;
    case 'promocoes':
        tratarRotaPromocao($metodo);
        break;
    case 'mercado_favorito':
        tratarRotaMercadoFavorito($metodo);
        break;
    case 'favoritos':
        tratarRotaFavorito($metodo, $rotaTratada);
        break;
    case 'categorias':
    case 'marcas':
    case 'unidades':
        tratarRotaCatalogo($metodo, $rotaPrincipal);
        break;
    default:
        Response::json(false, 'Rota não encontrada.', null, 404);
}
