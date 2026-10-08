import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class PosicaoUsuario {
  final double latitude;
  final double longitude;

  const PosicaoUsuario(this.latitude, this.longitude);
}

class EnderecoPosicao {
  final String cep;
  final String logradouro;
  final String numero;
  final String bairro;
  final String cidade;
  final String uf;

  const EnderecoPosicao({
    required this.cep,
    required this.logradouro,
    required this.numero,
    required this.bairro,
    required this.cidade,
    required this.uf,
  });
}

class LocalizacaoService {
  static Future<PosicaoUsuario?> obterPosicao() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }
      if (permissao == LocationPermission.denied ||
          permissao == LocationPermission.deniedForever) {
        return null;
      }

      try {
        final p = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 20),
          ),
        );
        return PosicaoUsuario(p.latitude, p.longitude);
      } catch (_) {
        // Sem sinal novo a tempo (comum em ambientes fechados e no emulador):
        // usa a última posição conhecida do aparelho.
        final ultima = await Geolocator.getLastKnownPosition();
        if (ultima == null) return null;
        return PosicaoUsuario(ultima.latitude, ultima.longitude);
      }
    } catch (_) {
      return null;
    }
  }

  // Converte o endereço em coordenadas pelo Nominatim (OpenStreetMap, sem chave).
  // Tenta primeiro com o número da rua e, se não achar, só com a rua.
  static Future<PosicaoUsuario?> coordenadasDoEndereco({
    required String rua,
    required String numero,
    required String cidade,
    required String uf,
  }) async {
    final temNumero = RegExp(r'\d').hasMatch(numero);
    final tentativas = [if (temNumero) '$numero $rua', rua];

    for (final street in tentativas) {
      final posicao = await _buscarNominatim({
        'street': street,
        'city': cidade,
        'state': uf,
        'country': 'Brasil',
        'format': 'jsonv2',
        'limit': '1',
      });
      if (posicao != null) return posicao;
    }
    return null;
  }

  // Caminho inverso: coordenadas -> endereço, também pelo Nominatim.
  static Future<EnderecoPosicao?> enderecoDaPosicao(
    PosicaoUsuario posicao,
  ) async {
    try {
      final resposta = await http
          .get(
            Uri.https('nominatim.openstreetmap.org', '/reverse', {
              'lat': '${posicao.latitude}',
              'lon': '${posicao.longitude}',
              'format': 'jsonv2',
              'addressdetails': '1',
              'accept-language': 'pt-BR',
            }),
            headers: const {'User-Agent': 'AcheiBarato/1.0 (TCC)'},
          )
          .timeout(const Duration(seconds: 10));

      if (resposta.statusCode != 200) return null;

      final json = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (json is! Map<String, dynamic> || json['address'] is! Map) return null;

      final a = Map<String, dynamic>.from(json['address'] as Map);
      String campo(List<String> chaves) {
        for (final c in chaves) {
          final valor = (a[c] ?? '').toString().trim();
          if (valor.isNotEmpty) return valor;
        }
        return '';
      }

      // "BR-RS" -> "RS"
      final iso = campo(['ISO3166-2-lvl4']);

      return EnderecoPosicao(
        cep: campo(['postcode']).replaceAll(RegExp(r'\D'), ''),
        logradouro: campo(['road', 'pedestrian', 'street']),
        numero: campo(['house_number']),
        bairro: campo(['suburb', 'neighbourhood', 'quarter']),
        cidade: campo(['city', 'town', 'village', 'municipality']),
        uf: iso.startsWith('BR-') ? iso.substring(3) : '',
      );
    } catch (_) {
      return null;
    }
  }

  static Future<PosicaoUsuario?> _buscarNominatim(
    Map<String, String> parametros,
  ) async {
    try {
      final resposta = await http
          .get(
            Uri.https('nominatim.openstreetmap.org', '/search', parametros),
            // O Nominatim exige identificar o aplicativo.
            headers: const {'User-Agent': 'AcheiBarato/1.0 (TCC)'},
          )
          .timeout(const Duration(seconds: 10));

      if (resposta.statusCode != 200) return null;

      final lista = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (lista is! List || lista.isEmpty) return null;

      final lat = double.tryParse('${lista.first['lat']}');
      final lon = double.tryParse('${lista.first['lon']}');
      if (lat == null || lon == null) return null;

      return PosicaoUsuario(lat, lon);
    } catch (_) {
      return null;
    }
  }

  static double? distanciaMetros(
    PosicaoUsuario? origem,
    double latitude,
    double longitude,
  ) {
    if (origem == null) return null;
    if (latitude == 0 && longitude == 0) return null;
    if (latitude.abs() > 90 || longitude.abs() > 180) return null;

    return Geolocator.distanceBetween(
      origem.latitude,
      origem.longitude,
      latitude,
      longitude,
    );
  }

  static String formatar(double metros) {
    if (metros < 1000) return '${metros.round()} m';
    return '${(metros / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
  }
}
