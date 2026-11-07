import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:achei_barato/config/api_config.dart';

class ApiException implements Exception {
  final String mensagem;
  final int? statusCode;

  ApiException(this.mensagem, {this.statusCode});

  @override
  String toString() => mensagem;
}

class ApiService {
  static const Duration _timeout = Duration(seconds: 15);

  // Token devolvido pela API no login. Vai em todas as requisições para que
  // a API saiba qual conta está pedindo e libere só os dados dela.
  static String? _token;

  static void iniciarSessao(String? token) => _token = token;

  static void encerrarSessao() => _token = null;

  static Future<Map<String, dynamic>> get(String rota) async {
    final response = await http
        .get(_uri(rota), headers: _headers())
        .timeout(_timeout);
    return _tratarResposta(response);
  }

  static Future<Map<String, dynamic>> post(
    String rota,
    Map<String, dynamic> dados,
  ) async {
    final response = await http
        .post(_uri(rota), headers: _headers(), body: jsonEncode(dados))
        .timeout(_timeout);
    return _tratarResposta(response);
  }

  static Future<Map<String, dynamic>> put(
    String rota,
    Map<String, dynamic> dados,
  ) async {
    final response = await http
        .put(_uri(rota), headers: _headers(), body: jsonEncode(dados))
        .timeout(_timeout);
    return _tratarResposta(response);
  }

  static Future<Map<String, dynamic>> delete(String rota) async {
    final response = await http
        .delete(_uri(rota), headers: _headers())
        .timeout(_timeout);
    return _tratarResposta(response);
  }

  static Future<Map<String, dynamic>> enviarImagem(
    String rota,
    List<int> bytes, {
    String nomeArquivo = 'foto.jpg',
  }) async {
    final requisicao = http.MultipartRequest('POST', _uri(rota))
      ..headers['Accept'] = 'application/json'
      ..headers.addAll(_autorizacao())
      ..files.add(
        http.MultipartFile.fromBytes('foto', bytes, filename: nomeArquivo),
      );

    final resposta = await http.Response.fromStream(
      await requisicao.send().timeout(const Duration(seconds: 60)),
    );
    return _tratarResposta(resposta);
  }

  static Uri _uri(String rota) {
    final rotaLimpa = rota.startsWith('/') ? rota.substring(1) : rota;
    return Uri.parse('${ApiConfig.baseUrl}/$rotaLimpa');
  }

  static Map<String, String> _headers() => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
    ..._autorizacao(),
  };

  static Map<String, String> _autorizacao() =>
      _token == null ? const {} : {'Authorization': 'Bearer $_token'};

  static Map<String, dynamic> _tratarResposta(http.Response response) {
    Map<String, dynamic> json;

    try {
      final conteudo = utf8.decode(response.bodyBytes);
      final decoded = jsonDecode(conteudo);

      if (decoded is! Map<String, dynamic>) {
        throw ApiException('A API retornou um JSON em formato inesperado.');
      }

      json = decoded;
    } on FormatException {
      throw ApiException(
        'A API não retornou um JSON válido.',
        statusCode: response.statusCode,
      );
    }

    final sucessoHttp = response.statusCode >= 200 && response.statusCode < 300;
    final sucessoApi = json['sucesso'] == true;

    if (!sucessoHttp || !sucessoApi) {
      throw ApiException(
        (json['mensagem'] ?? 'Erro na comunicação com a API').toString(),
        statusCode: response.statusCode,
      );
    }

    return json;
  }
}
