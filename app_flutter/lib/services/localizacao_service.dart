import 'package:geolocator/geolocator.dart';

class PosicaoUsuario {
  final double latitude;
  final double longitude;

  const PosicaoUsuario(this.latitude, this.longitude);
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

      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return PosicaoUsuario(p.latitude, p.longitude);
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
