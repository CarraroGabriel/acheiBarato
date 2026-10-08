import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:achei_barato/services/localizacao_service.dart';
import 'package:achei_barato/widgets/app_bar.dart';
import 'package:achei_barato/widgets/botao_primario.dart';

class EscolherLocalizacao extends StatefulWidget {
  const EscolherLocalizacao({super.key});

  @override
  State<EscolherLocalizacao> createState() => _EscolherLocalizacaoState();
}

class _EscolherLocalizacaoState extends State<EscolherLocalizacao> {
  static const _centroPadrao = LatLng(-29.940034864228743, -50.99516196626957);

  final _mapController = MapController();
  final _buscaController = TextEditingController();
  final _buscaFoco = FocusNode();

  late LatLng _centro;
  EnderecoPosicao? _endereco;
  bool _buscandoEndereco = false;
  bool _buscandoGps = false;

  List<ResultadoEndereco> _resultados = [];
  bool _pesquisando = false;

  Timer? _esperaMapa;
  Timer? _esperaBusca;

  @override
  void initState() {
    super.initState();
    final atual = LocalizacaoService.posicaoAtual;
    _centro = atual == null
        ? _centroPadrao
        : LatLng(atual.latitude, atual.longitude);
    _atualizarEndereco();
  }

  @override
  void dispose() {
    _esperaMapa?.cancel();
    _esperaBusca?.cancel();
    _buscaController.dispose();
    _buscaFoco.dispose();
    super.dispose();
  }

  PosicaoUsuario get _posicaoCentro =>
      PosicaoUsuario(_centro.latitude, _centro.longitude);

  void _aoMoverMapa(MapCamera camera, bool porGesto) {
    _centro = camera.center;
    if (!porGesto) return;

    _esperaMapa?.cancel();
    setState(() => _buscandoEndereco = true);
    _esperaMapa = Timer(const Duration(milliseconds: 700), _atualizarEndereco);
  }

  Future<void> _atualizarEndereco() async {
    setState(() => _buscandoEndereco = true);
    final posicao = _posicaoCentro;
    final endereco = await LocalizacaoService.enderecoDaPosicao(posicao);

    if (!mounted ||
        posicao.latitude != _centro.latitude ||
        posicao.longitude != _centro.longitude) {
      return;
    }
    setState(() {
      _endereco = endereco;
      _buscandoEndereco = false;
    });
  }

  void _aoDigitar(String texto) {
    _esperaBusca?.cancel();
    if (texto.trim().length < 3) {
      setState(() {
        _resultados = [];
        _pesquisando = false;
      });
      return;
    }
    _esperaBusca = Timer(
      const Duration(milliseconds: 900),
      () => _pesquisar(texto),
    );
  }

  Future<void> _pesquisar(String texto) async {
    setState(() => _pesquisando = true);
    final resultados = await LocalizacaoService.buscarEnderecos(
      texto,
      perto: _posicaoCentro,
    );
    if (!mounted || texto != _buscaController.text) return;
    setState(() {
      _resultados = resultados;
      _pesquisando = false;
    });
  }

  void _escolherResultado(ResultadoEndereco resultado) {
    _buscaFoco.unfocus();
    _buscaController.clear();

    final ponto = LatLng(
      resultado.posicao.latitude,
      resultado.posicao.longitude,
    );
    _mapController.move(ponto, 17);

    setState(() {
      _centro = ponto;
      _endereco = resultado.endereco;
      _resultados = [];
      _buscandoEndereco = false;
    });
  }

  Future<void> _usarGps() async {
    setState(() => _buscandoGps = true);
    final posicao = await LocalizacaoService.obterPosicao(atualizar: true);
    if (!mounted) return;
    setState(() => _buscandoGps = false);

    if (posicao == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível obter a localização. Verifique se o GPS e a permissão estão ativos.',
          ),
        ),
      );
      return;
    }

    Navigator.pop(context, true);
  }

  void _confirmar() {
    if (_buscandoEndereco) return;

    final endereco = _endereco;
    final descricao = endereco == null
        ? 'Local escolhido no mapa'
        : LocalizacaoService.descrever(endereco);

    LocalizacaoService.definirPosicaoManual(_posicaoCentro, descricao);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AcheiBaratoAppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _buscaController,
              focusNode: _buscaFoco,
              onChanged: _aoDigitar,
              textInputAction: TextInputAction.search,
              onSubmitted: _pesquisar,
              decoration: InputDecoration(
                hintText: 'Buscar rua, número ou bairro',
                prefixIcon: const Icon(Icons.search, color: Colors.red),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _pesquisando
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
            ),
          ),
          ListTile(
            dense: true,
            leading: _buscandoGps
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location, color: Colors.red),
            title: const Text(
              'Usar minha localização atual',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onTap: _buscandoGps ? null : _usarGps,
          ),
          const Divider(height: 1),
          Expanded(
            child: Stack(
              children: [
                _buildMapa(),
                if (_resultados.isNotEmpty) _buildResultados(),
              ],
            ),
          ),
          _buildRodape(),
        ],
      ),
    );
  }

  Widget _buildMapa() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _centro,
            initialZoom: 16,
            minZoom: 4,
            maxZoom: 19,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            onPositionChanged: _aoMoverMapa,
            onTap: (_, _) => _buscaFoco.unfocus(),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.achei_barato',
            ),
            const SimpleAttributionWidget(
              source: Text('OpenStreetMap contributors'),
            ),
          ],
        ),
        const IgnorePointer(
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 44),
              child: Icon(Icons.location_on, color: Colors.red, size: 48),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultados() {
    return Material(
      color: Colors.white,
      elevation: 4,
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _resultados.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final e = _resultados[i].endereco;
          final cidade = e.uf.isEmpty ? e.cidade : '${e.cidade}/${e.uf}';
          final complemento = [
            e.bairro,
            cidade,
          ].where((t) => t.isNotEmpty).join(', ');

          return ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(LocalizacaoService.descrever(e)),
            subtitle: complemento.isEmpty ? null : Text(complemento),
            onTap: () => _escolherResultado(_resultados[i]),
          );
        },
      ),
    );
  }

  Widget _buildRodape() {
    final e = _endereco;
    final String titulo;
    final String? subtitulo;

    if (_buscandoEndereco) {
      titulo = 'Buscando endereço...';
      subtitulo = null;
    } else if (e == null) {
      titulo = 'Local escolhido no mapa';
      subtitulo = 'Endereço não encontrado para este ponto';
    } else {
      titulo = LocalizacaoService.descrever(e);
      final cidade = e.uf.isEmpty ? e.cidade : '${e.cidade}/${e.uf}';
      subtitulo = [e.bairro, cidade].where((t) => t.isNotEmpty).join(', ');
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Arraste o mapa para ajustar o pino',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (subtitulo != null && subtitulo.isNotEmpty)
                        Text(
                          subtitulo,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BotaoPrimario(
              texto: 'Confirmar localização',
              onPressed: _confirmar,
            ),
          ],
        ),
      ),
    );
  }
}
