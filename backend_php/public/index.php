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
];

$rotaPrincipal = null;
$posicaoRota = null;

foreach ($rotasPrincipais as $rota) {
    $posicao = array_search($rota, $partesUri, true);

    if ($posicao !== false) {
        $rotaPrincipal = $rota;
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
    default:
        Response::json(false, 'Rota não encontrada.', null, 404);
}
