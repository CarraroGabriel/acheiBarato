import 'package:flutter/material.dart';
import 'package:achei_barato/services/cep_service.dart';
import 'package:achei_barato/services/localizacao_service.dart';

class EnderecoMercado {
  final cep = TextEditingController();
  final endereco = TextEditingController();
  final numero = TextEditingController();
  final bairro = TextEditingController();
  final cidade = TextEditingController();
  final uf = TextEditingController();

  double latitude = 0;
  double longitude = 0;

  bool localizacaoPeloGps = false;

  // Último CEP consultado, para não repetir a consulta na ViaCEP.
  String _cepConsultado = '';

  void carregar(Map<String, dynamic> mercado) {
    cep.text = (mercado['nu_cep'] ?? '').toString().padLeft(8, '0');
    endereco.text = (mercado['nm_endereco'] ?? '').toString();
    numero.text = (mercado['nu_numero'] ?? '').toString();
    bairro.text = (mercado['nm_bairro'] ?? '').toString();
    cidade.text = (mercado['nm_cidade'] ?? '').toString();
    // CHAR(2) no banco: a UF vazia vem como dois espaços.
    uf.text = (mercado['sg_uf'] ?? '').toString().trim();
    latitude = double.tryParse('${mercado['nu_latitude']}') ?? 0;
    longitude = double.tryParse('${mercado['nu_longitude']}') ?? 0;
    _cepConsultado = cidade.text.isEmpty ? '' : cep.text;
  }

  bool get temCoordenadas => latitude != 0 || longitude != 0;

  String? validar() {
    if (cep.text.replaceAll(RegExp(r'\D'), '').length != 8) {
      return 'Informe um CEP com 8 dígitos.';
    }
    if (endereco.text.trim().isEmpty ||
        numero.text.trim().isEmpty ||
        cidade.text.trim().isEmpty) {
      return 'Preencha o endereço, o número e a cidade.';
    }
    if (!RegExp(r'^[A-Za-z]{2}$').hasMatch(uf.text.trim())) {
      return 'Informe a UF com 2 letras.';
    }
    return null;
  }

  Future<bool> resolverCoordenadas() async {
    if (localizacaoPeloGps) return true;

    final posicao = await LocalizacaoService.coordenadasDoEndereco(
      rua: endereco.text.trim(),
      numero: numero.text.trim(),
      cidade: cidade.text.trim(),
      uf: uf.text.trim().toUpperCase(),
    );
    if (posicao == null) return false;

    latitude = posicao.latitude;
    longitude = posicao.longitude;
    return true;
  }

  Map<String, dynamic> paraApi() => {
    'nu_cep': cep.text.replaceAll(RegExp(r'\D'), ''),
    'nm_endereco': endereco.text.trim(),
    'nu_numero': numero.text.trim(),
    'nm_bairro': bairro.text.trim(),
    'nm_cidade': cidade.text.trim(),
    'sg_uf': uf.text.trim().toUpperCase(),
    'nu_latitude': latitude,
    'nu_longitude': longitude,
  };

  void dispose() {
    for (final c in [cep, endereco, numero, bairro, cidade, uf]) {
      c.dispose();
    }
  }
}

class CamposEndereco extends StatefulWidget {
  final EnderecoMercado endereco;

  const CamposEndereco({super.key, required this.endereco});

  @override
  State<CamposEndereco> createState() => _CamposEnderecoState();
}

class _CamposEnderecoState extends State<CamposEndereco> {
  bool _buscandoCep = false;
  bool _buscandoGps = false;

  EnderecoMercado get _e => widget.endereco;

  @override
  void initState() {
    super.initState();
    _e.cep.addListener(_aoAlterarCep);
    WidgetsBinding.instance.addPostFrameCallback((_) => _aoAlterarCep());
  }

  @override
  void dispose() {
    _e.cep.removeListener(_aoAlterarCep);
    super.dispose();
  }

  void _aoAlterarCep() {
    final numeros = _e.cep.text.replaceAll(RegExp(r'\D'), '');
    if (numeros.length == 8 && numeros != _e._cepConsultado && !_buscandoCep) {
      _consultarCep(numeros);
    }
  }

  Future<void> _consultarCep(String cep) async {
    _e._cepConsultado = cep;
    setState(() => _buscandoCep = true);

    try {
      final resultado = await CepService.consultar(cep);
      if (!mounted) return;

      if (resultado == null) {
        _mostrarMensagem(
          'CEP não encontrado. Preencha o endereço manualmente.',
        );
        return;
      }

      setState(() {
        if (resultado.logradouro.isNotEmpty) {
          _e.endereco.text = _limitar(resultado.logradouro, 50);
        }
        _e.bairro.text = _limitar(resultado.bairro, 40);
        _e.cidade.text = _limitar(resultado.cidade, 40);
        _e.uf.text = resultado.uf;
        // O endereço mudou: a localização volta a ser calculada por ele.
        _e.localizacaoPeloGps = false;
      });
    } catch (_) {
      _e._cepConsultado = '';
      _mostrarMensagem(
        'Não foi possível consultar o CEP. Preencha o endereço manualmente.',
      );
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  Future<void> _usarLocalizacaoAtual() async {
    setState(() => _buscandoGps = true);

    final posicao = await LocalizacaoService.obterPosicao(atualizar: true);
    if (!mounted) return;

    if (posicao == null) {
      setState(() => _buscandoGps = false);
      _mostrarMensagem(
        'Não foi possível obter a localização. Verifique se o GPS e a permissão estão ativos.',
      );
      return;
    }

    final achado = await LocalizacaoService.enderecoDaPosicao(posicao);
    if (!mounted) return;

    setState(() {
      _buscandoGps = false;
      _e.latitude = posicao.latitude;
      _e.longitude = posicao.longitude;
      _e.localizacaoPeloGps = true;

      if (achado != null) {
        // Marca o CEP como consultado para a ViaCEP não sobrescrever o endereço.
        if (achado.cep.length == 8) {
          _e._cepConsultado = achado.cep;
          _e.cep.text = achado.cep;
        }
        if (achado.logradouro.isNotEmpty) {
          _e.endereco.text = _limitar(achado.logradouro, 50);
        }
        if (achado.numero.isNotEmpty) {
          _e.numero.text = _limitar(achado.numero, 10);
        }
        if (achado.bairro.isNotEmpty) {
          _e.bairro.text = _limitar(achado.bairro, 40);
        }
        if (achado.cidade.isNotEmpty) {
          _e.cidade.text = _limitar(achado.cidade, 40);
        }
        if (achado.uf.isNotEmpty) _e.uf.text = achado.uf;
      }
    });

    _mostrarMensagem(
      achado == null
          ? 'Localização definida, mas o endereço não foi encontrado. Confira os campos e salve.'
          : 'Endereço preenchido pela sua localização. Confira os campos e salve.',
    );
  }

  String _limitar(String texto, int tamanho) =>
      texto.length > tamanho ? texto.substring(0, tamanho) : texto;

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    final String situacaoLocalizacao;
    if (_e.localizacaoPeloGps) {
      situacaoLocalizacao = 'Localização no mapa: GPS do aparelho.';
    } else if (_e.temCoordenadas) {
      situacaoLocalizacao = 'Localização no mapa definida pelo endereço.';
    } else {
      situacaoLocalizacao =
          'A localização no mapa será obtida pelo endereço ao salvar.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _e.cep,
          keyboardType: TextInputType.number,
          maxLength: 9,
          decoration: InputDecoration(
            labelText: 'CEP',
            helperText: 'O endereço é preenchido pelo CEP.',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.location_on),
            counterText: '',
            suffixIcon: _buscandoCep
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _e.endereco,
          maxLength: 50,
          decoration: const InputDecoration(
            labelText: 'Endereço',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.map),
            counterText: '',
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _e.numero,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Número',
                  hintText: '123 ou S/N',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pin),
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: TextField(
                controller: _e.bairro,
                maxLength: 40,
                decoration: const InputDecoration(
                  labelText: 'Bairro',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _e.cidade,
                maxLength: 40,
                decoration: const InputDecoration(
                  labelText: 'Cidade',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _e.uf,
                maxLength: 2,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'UF',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _buscandoGps ? null : _usarLocalizacaoAtual,
          icon: _buscandoGps
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
          label: const Text('Usar minha localização atual'),
        ),
        Text(
          situacaoLocalizacao,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
