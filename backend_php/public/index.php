<?php

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER["REQUEST_METHOD"] === "OPTIONS") {
    http_response_code(200);
    exit;
}

require_once __DIR__ . "/../helpers/Response.php";

require_once __DIR__ . "/../routes/usuario_routes.php";

$metodo = $_SERVER["REQUEST_METHOD"];

if (isset($_GET["rota"])) {
    $uri = $_GET["rota"];
} else {
    $uri = parse_url($_SERVER["REQUEST_URI"], PHP_URL_PATH);
}

$uri = trim($uri, "/");

$partesUri = explode("/", $uri);

// Lista das rotas principais aceitas pela API
$rotasPrincipais = ["usuarios"];

// Procura qual rota principal aparece na URL
$rotaPrincipal = null;
$posicaoRota = null;

foreach ($rotasPrincipais as $rota) {
    $posicao = array_search($rota, $partesUri);

    if ($posicao !== false) {
        $rotaPrincipal = $rota;
        $posicaoRota = $posicao;
        break;
    }
}

if ($rotaPrincipal === null) {
    Response::json(false, "Rota não encontrada.", null, 404);
}

// Pega somente a parte da URI a partir da rota principal
$rotaTratada = array_slice($partesUri, $posicaoRota);

// Decide qual arquivo de rotas deve tratar a requisição
switch ($rotaPrincipal) {
    case "usuarios":
        tratarRotasUsuario($metodo, $rotaTratada);
        break;

    default:
        Response::json(false, "Rota não encontrada.", null, 404);
        break;
}