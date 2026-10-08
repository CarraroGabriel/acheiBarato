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

class ResultadoEndereco {
  final PosicaoUsuario posicao;
  final EnderecoPosicao endereco;

  const ResultadoEndereco(this.posicao, this.endereco);
}

class LocalizacaoService {
  static PosicaoUsuario? _posicao;
  static DateTime? _obtidaEm;
  static String? _descricao;

  static bool posicaoManual = false;

  static const _validadeGps = Duration(minutes: 5);

  static PosicaoUsuario? get posicaoAtual => _posicao;

  static Future<PosicaoUsuario?> obterPosicao({bool atualizar = false}) async {
    final recente =
        _obtidaEm != null &&
        DateTime.now().difference(_obtidaEm!) < _validadeGps;
    if (!atualizar && _posicao != null && (posicaoManual || recente)) {
      return _posicao;
    }

    final gps = await _lerGps();
    if (gps != null) {
      _posicao = gps;
      _obtidaEm = DateTime.now();
      _descricao = null;
      posicaoManual = false;
    }
    return gps ?? (atualizar ? null : _posicao);
  }

  static void definirPosicaoManual(PosicaoUsuario posicao, String descricao) {
    _posicao = posicao;
    _obtidaEm = DateTime.now();
    _descricao = descricao;
    posicaoManual = true;
  }

  static Future<String?> descreverPosicao() async {
    if (_descricao != null || _posicao == null) return _descricao;

    final endereco = await enderecoDaPosicao(_posicao!);
    if (endereco == null || endereco.cidade.isEmpty) return null;

    final cidade = endereco.uf.isEmpty
        ? endereco.cidade
        : '${endereco.cidade}/${endereco.uf}';
    _descricao = endereco.bairro.isEmpty
        ? cidade
        : '${endereco.bairro}, $cidade';
    return _descricao;
  }

  static Future<PosicaoUsuario?> _lerGps() async {
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
        // usa a última posição conhecida do aparelho.
        final ultima = await Geolocator.getLastKnownPosition();
        if (ultima == null) return null;
        return PosicaoUsuario(ultima.latitude, ultima.longitude);
      }
    } catch (_) {
      return null;
    }
  }

  static Future<PosicaoUsuario?> coordenadasDoEndereco({
    required String rua,
    required String numero,
    required String cidade,
    required String uf,
  }) async {
    final temNumero = RegExp(r'\d').hasMatch(numero);
    final tentativas = [if (temNumero) '$numero $rua', rua, ''];

    for (final street in tentativas.toSet()) {
      final posicao = await _buscarNominatim({
        if (street.trim().isNotEmpty) 'street': street,
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

      return _lerEndereco(Map<String, dynamic>.from(json['address'] as Map));
    } catch (_) {
      return null;
    }
  }

  static Future<List<ResultadoEndereco>> buscarEnderecos(
    String texto, {
    PosicaoUsuario? perto,
  }) async {
    if (texto.trim().length < 3) return [];

    try {
      final resposta = await http
          .get(
            Uri.https('nominatim.openstreetmap.org', '/search', {
              'q': texto.trim(),
              'countrycodes': 'br',
              'format': 'jsonv2',
              'addressdetails': '1',
              'limit': '6',
              'accept-language': 'pt-BR',
              if (perto != null)
                'viewbox':
                    '${perto.longitude - 0.5},${perto.latitude + 0.5},'
                    '${perto.longitude + 0.5},${perto.latitude - 0.5}',
            }),
            headers: const {'User-Agent': 'AcheiBarato/1.0 (TCC)'},
          )
          .timeout(const Duration(seconds: 10));

      if (resposta.statusCode != 200) return [];

      final lista = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (lista is! List) return [];

      final resultados = <ResultadoEndereco>[];
      for (final item in lista.whereType<Map>()) {
        final lat = double.tryParse('${item['lat']}');
        final lon = double.tryParse('${item['lon']}');
        if (lat == null || lon == null || item['address'] is! Map) continue;

        final endereco = _lerEndereco(
          Map<String, dynamic>.from(item['address'] as Map),
        );
        resultados.add(ResultadoEndereco(PosicaoUsuario(lat, lon), endereco));
      }
      return resultados;
    } catch (_) {
      return [];
    }
  }

  static String descrever(EnderecoPosicao e) {
    final cidade = e.uf.isEmpty ? e.cidade : '${e.cidade}/${e.uf}';
    if (e.logradouro.isNotEmpty) {
      return e.numero.isEmpty ? e.logradouro : '${e.logradouro}, ${e.numero}';
    }
    if (e.bairro.isNotEmpty) return '${e.bairro}, $cidade';
    return cidade;
  }

  static EnderecoPosicao _lerEndereco(Map<String, dynamic> a) {
    String campo(List<String> chaves) {
      for (final c in chaves) {
        final valor = (a[c] ?? '').toString().trim();
        if (valor.isNotEmpty) return valor;
      }
      return '';
    }

    final iso = campo(['ISO3166-2-lvl4']);

    return EnderecoPosicao(
      cep: campo(['postcode']).replaceAll(RegExp(r'\D'), ''),
      logradouro: campo(['road', 'pedestrian', 'street']),
      numero: campo(['house_number']),
      bairro: campo(['suburb', 'neighbourhood', 'quarter']),
      cidade: campo(['city', 'town', 'village', 'municipality']),
      uf: iso.startsWith('BR-') ? iso.substring(3) : '',
    );
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
