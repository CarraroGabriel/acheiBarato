import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:achei_barato/services/localizacao_service.dart';

class MapaMercados extends StatefulWidget {
  final PosicaoUsuario? posicao;
  final List<Map<String, dynamic>> mercados;
  final void Function(Map<String, dynamic> mercado) aoAbrirMercado;

  const MapaMercados({
    super.key,
    required this.posicao,
    required this.mercados,
    required this.aoAbrirMercado,
  });

  @override
  State<MapaMercados> createState() => _MapaMercadosState();
}

class _MapaMercadosState extends State<MapaMercados> {
  // Ponto padrão (Gravataí), usado enquanto não há posição.
  static const _centroPadrao = LatLng(-29.940034864228743, -50.99516196626957);

  final _controller = MapController();
  bool _mapaPronto = false;
  Map<String, dynamic>? _selecionado;

  @override
  void didUpdateWidget(MapaMercados antigo) {
    super.didUpdateWidget(antigo);
    final nova = widget.posicao;
    final posicaoMudou =
        antigo.posicao?.latitude != nova?.latitude ||
        antigo.posicao?.longitude != nova?.longitude;
    final mercadosMudaram =
        antigo.mercados.where((m) => _coordenadas(m) != null).length !=
        _mercadosNoMapa.length;

    if ((posicaoMudou || mercadosMudaram) && _mapaPronto) _enquadrar();
  }

  List<Map<String, dynamic>> get _mercadosNoMapa =>
      widget.mercados.where((m) => _coordenadas(m) != null).toList();

  void _enquadrar() {
    final p = widget.posicao;
    final pontos = <LatLng>[];

    if (p != null) {
      pontos.add(LatLng(p.latitude, p.longitude));

      final proximos =
          _mercadosNoMapa
              .map((m) => (m, _distancia(m) ?? double.infinity))
              .where((par) => par.$2 <= 20000)
              .toList()
            ..sort((a, b) => a.$2.compareTo(b.$2));
      pontos.addAll(proximos.take(3).map((par) => _coordenadas(par.$1)!));
    } else {
      pontos.addAll(_mercadosNoMapa.map((m) => _coordenadas(m)!));
    }

    if (pontos.isEmpty) return;
    if (pontos.length == 1) {
      _controller.move(pontos.first, 15);
      return;
    }
    _controller.fitCamera(
      CameraFit.coordinates(
        coordinates: pontos,
        padding: const EdgeInsets.fromLTRB(40, 60, 60, 40),
        maxZoom: 16,
      ),
    );
  }

  double? _distancia(Map<String, dynamic> mercado) {
    return LocalizacaoService.distanciaMetros(
      widget.posicao,
      double.tryParse('${mercado['nu_latitude']}') ?? 0,
      double.tryParse('${mercado['nu_longitude']}') ?? 0,
    );
  }

  bool _estaSelecionado(Map<String, dynamic> mercado) =>
      _selecionado != null &&
      '${_selecionado!['id_mercado']}' == '${mercado['id_mercado']}';

  LatLng? _coordenadas(Map<String, dynamic> mercado) {
    final lat = double.tryParse('${mercado['nu_latitude']}') ?? 0;
    final lon = double.tryParse('${mercado['nu_longitude']}') ?? 0;
    if (lat == 0 && lon == 0) return null;
    return LatLng(lat, lon);
  }

  LatLng get _centroInicial {
    final p = widget.posicao;
    if (p != null) return LatLng(p.latitude, p.longitude);
    final mercados = _mercadosNoMapa;
    if (mercados.isNotEmpty) return _coordenadas(mercados.first)!;
    return _centroPadrao;
  }

  @override
  Widget build(BuildContext context) {
    final posicao = widget.posicao;

    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: _centroInicial,
            initialZoom: posicao == null ? 12 : 14,
            minZoom: 4,
            maxZoom: 18,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            onMapReady: () {
              _mapaPronto = true;
              _enquadrar();
            },
            onTap: (_, _) => setState(() => _selecionado = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.achei_barato',
            ),
            MarkerLayer(
              markers: [
                ..._mercadosNoMapa.map(
                  (m) => Marker(
                    point: _coordenadas(m)!,
                    width: _estaSelecionado(m) ? 38 : 30,
                    height: _estaSelecionado(m) ? 38 : 30,
                    child: GestureDetector(
                      onTap: () => setState(() => _selecionado = m),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _estaSelecionado(m)
                              ? Colors.red.shade900
                              : Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                        child: Icon(
                          Icons.store,
                          color: Colors.white,
                          size: _estaSelecionado(m) ? 20 : 16,
                        ),
                      ),
                    ),
                  ),
                ),
                if (posicao != null)
                  Marker(
                    point: LatLng(posicao.latitude, posicao.longitude),
                    width: 22,
                    height: 22,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SimpleAttributionWidget(
              source: Text('OpenStreetMap contributors'),
            ),
          ],
        ),
        if (posicao != null)
          Positioned(
            top: 8,
            right: 8,
            child: FloatingActionButton.small(
              heroTag: 'centralizar_mapa',
              backgroundColor: Colors.white,
              foregroundColor: Colors.red,
              tooltip: 'Ver minha localização e os mercados próximos',
              onPressed: _enquadrar,
              child: const Icon(Icons.my_location),
            ),
          ),
        if (_selecionado != null)
          Positioned(
            left: 8,
            right: 8,
            bottom: 24,
            child: _buildCardSelecionado(_selecionado!),
          ),
      ],
    );
  }

  Widget _buildCardSelecionado(Map<String, dynamic> mercado) {
    final distancia = _distancia(mercado);

    return Card(
      elevation: 4,
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.store, color: Colors.red),
        title: Text(
          (mercado['nm_mercado'] ?? '').toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: distancia == null
            ? null
            : Text('${LocalizacaoService.formatar(distancia)} de você'),
        trailing: TextButton(
          onPressed: () => widget.aoAbrirMercado(mercado),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Ver mercado'),
        ),
      ),
    );
  }
}
