import 'dart:convert';

import 'package:http/http.dart' as http;

class EnderecoCep {
  final String logradouro;
  final String bairro;
  final String cidade;
  final String uf;

  const EnderecoCep({
    required this.logradouro,
    required this.bairro,
    required this.cidade,
    required this.uf,
  });
}

// Consulta de endereço pelo CEP na ViaCEP (gratuita, sem chave).
class CepService {
  // Retorna null quando o CEP não existe; lança exceção quando não há conexão.
  static Future<EnderecoCep?> consultar(String cep) async {
    final numeros = cep.replaceAll(RegExp(r'\D'), '');
    if (numeros.length != 8) return null;

    final resposta = await http
        .get(Uri.parse('https://viacep.com.br/ws/$numeros/json/'))
        .timeout(const Duration(seconds: 10));

    if (resposta.statusCode != 200) return null;

    final json = jsonDecode(utf8.decode(resposta.bodyBytes));
    if (json is! Map<String, dynamic> || json['erro'] != null) return null;

    return EnderecoCep(
      logradouro: (json['logradouro'] ?? '').toString(),
      bairro: (json['bairro'] ?? '').toString(),
      cidade: (json['localidade'] ?? '').toString(),
      uf: (json['uf'] ?? '').toString(),
    );
  }
}
