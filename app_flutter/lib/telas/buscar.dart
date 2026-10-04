import 'dart:async';

import 'package:flutter/material.dart';
import 'package:achei_barato/services/api_service.dart';
import 'package:achei_barato/services/localizacao_service.dart';
import 'package:achei_barato/telas/perfil_mercado.dart';
import 'package:achei_barato/telas/produto.dart';
import 'package:achei_barato/widgets/app_bar.dart';
import 'package:achei_barato/widgets/bottomnav_usuarios.dart';
import 'package:achei_barato/widgets/menu_lateral.dart';

enum OrdemProdutos {
  relevancia('Relevância', 'relevancia'),
  menorPreco('Menor preço', 'menor_preco'),
  maiorPreco('Maior preço', 'maior_preco'),
  nome('Nome', 'nome');

  final String rotulo;
  final String valorApi;

  const OrdemProdutos(this.rotulo, this.valorApi);
}

enum OrdemMercados {
  proximos('Mais próximos'),
  avaliacao('Melhor avaliação'),
  promocoes('Mais promoções'),
  nome('Nome');

  final String rotulo;

  const OrdemMercados(this.rotulo);
}

class Buscar extends StatefulWidget {
  final int idUsuario;
  final String nomeUsuario;

  const Buscar({super.key, required this.idUsuario, required this.nomeUsuario});

  @override
  State<Buscar> createState() => _BuscarState();
}

class _BuscarState extends State<Buscar> with SingleTickerProviderStateMixin {
  static const Duration _atrasoBusca = Duration(milliseconds: 500);
  static const List<int> _raiosKm = [1, 3, 5, 10, 15];
  static const double _precoMaximoSlider = 200;

  late final TabController _abas = TabController(length: 2, vsync: this)
    ..addListener(_aoTrocarAba);
  final _buscaProdutosController = TextEditingController();
  final _buscaMercadosController = TextEditingController();
  Timer? _debounce;
  late String _nomeUsuario = widget.nomeUsuario;

  int _requisicaoProdutos = 0;
  int _requisicaoMercados = 0;

  List<Map<String, dynamic>> _produtos = [];
  bool _carregandoProdutos = false;
  String? _erroProdutos;
  List<Map<String, dynamic>> _categorias = [];
  List<Map<String, dynamic>> _marcas = [];
  int? _idCategoria;
  int? _idMarca;
  RangeValues? _faixaPreco;
  String? _promocao;
  OrdemProdutos _ordemProdutos = OrdemProdutos.relevancia;

  List<Map<String, dynamic>> _mercados = [];
  bool _carregandoMercados = false;
  String? _erroMercados;
  bool _mercadosCarregados = false;
  PosicaoUsuario? _posicao;
  bool _buscandoLocalizacao = false;
  bool _localizacaoVerificada = false;
  int? _raioKm;
  bool? _motoboy;
  double? _notaMinima;
  bool _somenteComPromocao = false;
  OrdemMercados _ordemMercados = OrdemMercados.nome;

  @override
  void initState() {
    super.initState();
    _carregarListasFiltros();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _abas.dispose();
    _buscaProdutosController.dispose();
    _buscaMercadosController.dispose();
    super.dispose();
  }

  bool get _abaProdutos => _abas.index == 0;

  void _aoTrocarAba() {
    if (_abas.indexIsChanging) return;
    setState(() {});

    if (!_abaProdutos && !_mercadosCarregados) {
      _buscarMercados();
      _obterLocalizacao();
    }
  }

  void _aoDigitar(String _) {
    _debounce?.cancel();
    _debounce = Timer(
      _atrasoBusca,
      _abaProdutos ? _buscarProdutos : _buscarMercados,
    );
    setState(() {});
  }

  void _aoConfirmar(String _) {
    _debounce?.cancel();
    _abaProdutos ? _buscarProdutos() : _buscarMercados();
  }

  void _limparTexto() {
    (_abaProdutos ? _buscaProdutosController : _buscaMercadosController)
        .clear();
    _aoConfirmar('');
  }

  Future<void> _carregarListasFiltros() async {
    try {
      final resultados = await Future.wait([
        ApiService.get('categorias'),
        ApiService.get('marcas'),
      ]);
      if (!mounted) return;
      setState(() {
        _categorias = _listaDeMapas(resultados[0]['dados']);
        _marcas = _listaDeMapas(resultados[1]['dados']);
      });
    } catch (_) {
      // Sem as listas, os filtros mostram só "Todas"; a busca por texto continua funcionando.
    }
  }

  bool get _temFiltroProduto =>
      _idCategoria != null ||
      _idMarca != null ||
      _faixaPreco != null ||
      _promocao != null;

  bool get _podeBuscarProdutos =>
      _buscaProdutosController.text.trim().isNotEmpty || _temFiltroProduto;

  Future<void> _buscarProdutos() async {
    final requisicao = ++_requisicaoProdutos;

    if (!_podeBuscarProdutos) {
      setState(() {
        _produtos = [];
        _erroProdutos = null;
        _carregandoProdutos = false;
      });
      return;
    }

    setState(() {
      _carregandoProdutos = true;
      _erroProdutos = null;
    });

    final faixa = _faixaPreco;
    final parametros = {
      'busca': _buscaProdutosController.text.trim(),
      'ordem': _ordemProdutos.valorApi,
      if (_idCategoria != null) 'categoria': '$_idCategoria',
      if (_idMarca != null) 'marca': '$_idMarca',
      'promocao': ?_promocao,
      if (faixa != null && faixa.start > 0)
        'preco_min': faixa.start.toStringAsFixed(0),
      if (faixa != null && faixa.end < _precoMaximoSlider)
        'preco_max': faixa.end.toStringAsFixed(0),
    };

    try {
      final resposta = await ApiService.get(
        'produtos/busca?${Uri(queryParameters: parametros).query}',
      );
      if (!mounted || requisicao != _requisicaoProdutos) return;
      setState(() => _produtos = _listaDeMapas(resposta['dados']));
    } on ApiException catch (e) {
      if (mounted && requisicao == _requisicaoProdutos) {
        setState(() => _erroProdutos = e.mensagem);
      }
    } catch (_) {
      if (mounted && requisicao == _requisicaoProdutos) {
        setState(
          () => _erroProdutos = 'Não foi possível conectar ao servidor.',
        );
      }
    } finally {
      if (mounted && requisicao == _requisicaoProdutos) {
        setState(() => _carregandoProdutos = false);
      }
    }
  }

  void _alterarFiltroProduto(VoidCallback alteracao) {
    setState(alteracao);
    _buscarProdutos();
  }

  void _limparFiltrosProduto() {
    _alterarFiltroProduto(() {
      _idCategoria = null;
      _idMarca = null;
      _faixaPreco = null;
      _promocao = null;
    });
  }

  void _abrirProduto(int idItemProduto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProdutoTela(
          idItemProduto: idItemProduto,
          idUsuario: widget.idUsuario,
        ),
      ),
    );
  }

  Future<void> _buscarMercados() async {
    final requisicao = ++_requisicaoMercados;

    setState(() {
      _carregandoMercados = true;
      _erroMercados = null;
    });

    final parametros = {
      'busca': _buscaMercadosController.text.trim(),
      if (_motoboy != null) 'motoboy': _motoboy! ? 'sim' : 'nao',
    };

    try {
      final resposta = await ApiService.get(
        'mercados?${Uri(queryParameters: parametros).query}',
      );
      if (!mounted || requisicao != _requisicaoMercados) return;
      setState(() {
        _mercados = _listaDeMapas(resposta['dados']);
        _mercadosCarregados = true;
      });
    } on ApiException catch (e) {
      if (mounted && requisicao == _requisicaoMercados) {
        setState(() => _erroMercados = e.mensagem);
      }
    } catch (_) {
      if (mounted && requisicao == _requisicaoMercados) {
        setState(
          () => _erroMercados = 'Não foi possível conectar ao servidor.',
        );
      }
    } finally {
      if (mounted && requisicao == _requisicaoMercados) {
        setState(() => _carregandoMercados = false);
      }
    }
  }

  Future<void> _obterLocalizacao() async {
    setState(() => _buscandoLocalizacao = true);
    final posicao = await LocalizacaoService.obterPosicao();
    if (!mounted) return;

    setState(() {
      _posicao = posicao;
      _localizacaoVerificada = true;
      _buscandoLocalizacao = false;

      if (posicao != null && _ordemMercados == OrdemMercados.nome) {
        _ordemMercados = OrdemMercados.proximos;
      }
      if (posicao == null) {
        _raioKm = null;
        if (_ordemMercados == OrdemMercados.proximos) {
          _ordemMercados = OrdemMercados.nome;
        }
      }
    });
  }

  double? _distancia(Map<String, dynamic> mercado) {
    return LocalizacaoService.distanciaMetros(
      _posicao,
      _toDouble(mercado['nu_latitude']),
      _toDouble(mercado['nu_longitude']),
    );
  }

  bool get _temFiltroMercadoLocal =>
      _raioKm != null || _notaMinima != null || _somenteComPromocao;

  List<Map<String, dynamic>> get _mercadosExibidos {
    final lista = _mercados.where((m) {
      if (_raioKm != null) {
        final distancia = _distancia(m);
        if (distancia == null || distancia > _raioKm! * 1000) return false;
      }
      if (_notaMinima != null &&
          (_toInt(m['nul_avaliacoes']) == 0 ||
              _toDouble(m['nu_avg_nota']) < _notaMinima!)) {
        return false;
      }
      if (_somenteComPromocao && _toInt(m['qt_promocoes']) == 0) return false;
      return true;
    }).toList();

    int porNome(Map<String, dynamic> a, Map<String, dynamic> b) =>
        a['nm_mercado'].toString().toLowerCase().compareTo(
          b['nm_mercado'].toString().toLowerCase(),
        );

    lista.sort((a, b) {
      final comparacao = switch (_ordemMercados) {
        OrdemMercados.proximos => (_distancia(a) ?? double.infinity).compareTo(
          _distancia(b) ?? double.infinity,
        ),
        OrdemMercados.avaliacao =>
          (_toInt(b['nul_avaliacoes']) > 0 ? _toDouble(b['nu_avg_nota']) : -1)
              .compareTo(
                _toInt(a['nul_avaliacoes']) > 0
                    ? _toDouble(a['nu_avg_nota'])
                    : -1,
              ),
        OrdemMercados.promocoes => _toInt(
          b['qt_promocoes'],
        ).compareTo(_toInt(a['qt_promocoes'])),
        OrdemMercados.nome => 0,
      };
      return comparacao != 0 ? comparacao : porNome(a, b);
    });

    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final controller = _abaProdutos
        ? _buscaProdutosController
        : _buscaMercadosController;

    return Scaffold(
      appBar: AcheiBaratoAppBar(
        exibirBotaoVoltar: false,
        exibirMenu: true,
        acoes: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      drawer: MenuLateral(
        nome: _nomeUsuario,
        id: widget.idUsuario,
        aoAlterarPerfil: (nome) => setState(() => _nomeUsuario = nome),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              key: ValueKey(_abas.index),
              controller: controller,
              textInputAction: TextInputAction.search,
              onChanged: _aoDigitar,
              onSubmitted: _aoConfirmar,
              decoration: InputDecoration(
                hintText: _abaProdutos
                    ? 'Buscar produto...'
                    : 'Buscar mercado...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpar',
                        icon: const Icon(Icons.close),
                        onPressed: _limparTexto,
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          TabBar(
            controller: _abas,
            labelColor: Colors.red,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.red,
            tabs: const [
              Tab(icon: Icon(Icons.shopping_basket), text: 'Produtos'),
              Tab(icon: Icon(Icons.store), text: 'Mercados'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _abas,
              children: [_buildAbaProdutos(), _buildAbaMercados()],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavUsuarios(
        indiceAtual: 1,
        idUsuario: widget.idUsuario,
        nomeUsuario: _nomeUsuario,
      ),
    );
  }

  Widget _buildAbaProdutos() {
    final categoria = _categorias.where(
      (c) => _toInt(c['id_categoria']) == _idCategoria,
    );
    final marca = _marcas.where((m) => _toInt(m['id_marca']) == _idMarca);
    final faixa = _faixaPreco;

    return Column(
      children: [
        _buildLinhaFiltros([
          _buildChipFiltro(
            rotulo: categoria.isEmpty
                ? 'Categoria'
                : categoria.first['nm_categoria'].toString(),
            ativo: _idCategoria != null,
            onTap: _escolherCategoria,
          ),
          _buildChipFiltro(
            rotulo: marca.isEmpty
                ? 'Marca'
                : marca.first['nm_marca'].toString(),
            ativo: _idMarca != null,
            onTap: _escolherMarca,
          ),
          _buildChipFiltro(
            rotulo: faixa == null ? 'Preço' : _textoFaixaPreco(faixa),
            ativo: faixa != null,
            onTap: _escolherFaixaPreco,
          ),
          _buildChipFiltro(
            rotulo: switch (_promocao) {
              'sim' => 'Em promoção',
              'nao' => 'Sem promoção',
              _ => 'Promoção',
            },
            ativo: _promocao != null,
            onTap: _escolherPromocao,
          ),
          if (_temFiltroProduto)
            ActionChip(
              avatar: const Icon(Icons.filter_alt_off, size: 18),
              label: const Text('Limpar'),
              onPressed: _limparFiltrosProduto,
            ),
        ]),
        _buildLinhaOrdenacao<OrdemProdutos>(
          quantidade: _podeBuscarProdutos && !_carregandoProdutos
              ? _produtos.length
              : null,
          singular: 'produto',
          plural: 'produtos',
          atual: _ordemProdutos,
          opcoes: OrdemProdutos.values,
          rotulo: (o) => o.rotulo,
          habilitada: (_) => true,
          aoEscolher: (o) => _alterarFiltroProduto(() => _ordemProdutos = o),
        ),
        Expanded(child: _buildResultadosProdutos()),
      ],
    );
  }

  Widget _buildResultadosProdutos() {
    if (!_podeBuscarProdutos) {
      return _buildMensagem(
        Icons.search,
        'Digite o nome de um produto ou use os filtros para começar.',
      );
    }

    if (_carregandoProdutos) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erroProdutos != null) {
      return _buildMensagem(
        Icons.error_outline,
        _erroProdutos!,
        acao: TextButton(
          onPressed: _buscarProdutos,
          child: const Text('Tentar novamente'),
        ),
      );
    }

    if (_produtos.isEmpty) {
      return _buildMensagem(
        Icons.search_off,
        _temFiltroProduto
            ? 'Nenhum produto encontrado com esses filtros.'
            : 'Nenhum produto encontrado.',
        acao: _temFiltroProduto
            ? TextButton(
                onPressed: _limparFiltrosProduto,
                child: const Text('Limpar filtros'),
              )
            : null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: _produtos.length,
      itemBuilder: (_, i) => _buildCardProduto(_produtos[i]),
    );
  }

  Widget _buildCardProduto(Map<String, dynamic> produto) {
    final foto = (produto['ds_foto_produto'] ?? '').toString();
    final qtMercados = _toInt(produto['qt_mercados']);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _abrirProduto(_toInt(produto['id_item_produto'])),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildImagem(foto, Icons.image, 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (produto['ds_item_produto'] ?? '').toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${produto['nm_marca'] ?? ''} • ${produto['ds_categoria'] ?? ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'A partir de ${_formatarValor(produto['nu_menor_preco'])}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildInfo(
                          Icons.store,
                          qtMercados == 1
                              ? '1 mercado encontrado'
                              : '$qtMercados mercados encontrados',
                          Colors.grey.shade700,
                        ),
                        if (_toBool(produto['fl_promocao']))
                          _buildInfo(Icons.local_offer, 'Promoção', Colors.red),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _escolherCategoria() async {
    if (_categorias.isEmpty) await _carregarListasFiltros();
    if (!mounted) return;

    _escolherOpcao<int?>(
      titulo: 'Categoria',
      atual: _idCategoria,
      opcoes: [
        (null, 'Todas as categorias'),
        ..._categorias.map(
          (c) =>
              (_toInt(c['id_categoria']) as int?, c['nm_categoria'].toString()),
        ),
      ],
      aoEscolher: (v) => _alterarFiltroProduto(() => _idCategoria = v),
    );
  }

  Future<void> _escolherMarca() async {
    if (_marcas.isEmpty) await _carregarListasFiltros();
    if (!mounted) return;

    _escolherOpcao<int?>(
      titulo: 'Marca',
      atual: _idMarca,
      opcoes: [
        (null, 'Todas as marcas'),
        ..._marcas.map(
          (m) => (_toInt(m['id_marca']) as int?, m['nm_marca'].toString()),
        ),
      ],
      aoEscolher: (v) => _alterarFiltroProduto(() => _idMarca = v),
    );
  }

  void _escolherPromocao() {
    _escolherOpcao<String?>(
      titulo: 'Promoção',
      atual: _promocao,
      opcoes: const [
        (null, 'Todos'),
        ('sim', 'Somente em promoção'),
        ('nao', 'Sem promoção'),
      ],
      aoEscolher: (v) => _alterarFiltroProduto(() => _promocao = v),
    );
  }

  Future<void> _escolherFaixaPreco() async {
    var faixa = _faixaPreco ?? const RangeValues(0, _precoMaximoSlider);

    final escolhida = await showModalBottomSheet<RangeValues?>(
      context: context,
      showDragHandle: true,
      builder: (contextoSheet) => StatefulBuilder(
        builder: (contextoSheet, setStateSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Faixa de preço',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Considera o menor preço encontrado entre os mercados.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                Text(
                  _textoFaixaPreco(faixa),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                RangeSlider(
                  values: faixa,
                  min: 0,
                  max: _precoMaximoSlider,
                  divisions: 40,
                  activeColor: Colors.red,
                  onChanged: (v) => setStateSheet(() => faixa = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(
                          contextoSheet,
                          const RangeValues(0, _precoMaximoSlider),
                        ),
                        child: const Text('Qualquer preço'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(contextoSheet, faixa),
                        child: const Text('Aplicar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (escolhida == null) return;

    final semFiltro =
        escolhida.start <= 0 && escolhida.end >= _precoMaximoSlider;
    _alterarFiltroProduto(() => _faixaPreco = semFiltro ? null : escolhida);
  }

  String _textoFaixaPreco(RangeValues faixa) {
    final minimo = 'R\$ ${faixa.start.toStringAsFixed(0)}';
    final maximo = faixa.end >= _precoMaximoSlider
        ? 'R\$ ${_precoMaximoSlider.toStringAsFixed(0)}+'
        : 'R\$ ${faixa.end.toStringAsFixed(0)}';
    return '$minimo – $maximo';
  }

  Widget _buildAbaMercados() {
    final semLocalizacao = _posicao == null;
    final notaMinima = _notaMinima;

    return Column(
      children: [
        _buildLinhaFiltros([
          _buildChipFiltro(
            rotulo: _raioKm == null ? 'Raio' : 'Até $_raioKm km',
            ativo: _raioKm != null,
            icone: Icons.near_me,
            onTap: semLocalizacao ? null : _escolherRaio,
          ),
          _buildChipFiltro(
            rotulo: switch (_motoboy) {
              true => 'Com tele-entrega',
              false => 'Sem tele-entrega',
              null => 'Tele-entrega',
            },
            ativo: _motoboy != null,
            icone: Icons.delivery_dining,
            onTap: _escolherTeleEntrega,
          ),
          _buildChipFiltro(
            rotulo: 'Mais',
            ativo: notaMinima != null || _somenteComPromocao,
            icone: Icons.tune,
            onTap: _escolherMaisFiltrosMercado,
          ),
        ]),
        if (_buscandoLocalizacao)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(color: Colors.red),
          )
        else if (_localizacaoVerificada && semLocalizacao)
          _buildAvisoLocalizacao(),
        _buildLinhaOrdenacao<OrdemMercados>(
          quantidade: _mercadosCarregados && !_carregandoMercados
              ? _mercadosExibidos.length
              : null,
          singular: 'mercado',
          plural: 'mercados',
          atual: _ordemMercados,
          opcoes: OrdemMercados.values,
          rotulo: (o) => o.rotulo,
          habilitada: (o) => o != OrdemMercados.proximos || !semLocalizacao,
          aoEscolher: (o) => setState(() => _ordemMercados = o),
        ),
        Expanded(child: _buildResultadosMercados()),
      ],
    );
  }

  Widget _buildAvisoLocalizacao() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.location_off, color: Colors.orange.shade800, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ative a localização para ver a distância dos mercados e filtrar por raio.',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
            ),
          ),
          TextButton(onPressed: _obterLocalizacao, child: const Text('Ativar')),
        ],
      ),
    );
  }

  Widget _buildResultadosMercados() {
    if (_carregandoMercados && _mercados.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erroMercados != null) {
      return _buildMensagem(
        Icons.error_outline,
        _erroMercados!,
        acao: TextButton(
          onPressed: _buscarMercados,
          child: const Text('Tentar novamente'),
        ),
      );
    }

    final mercados = _mercadosExibidos;

    if (mercados.isEmpty) {
      final comFiltro = _temFiltroMercadoLocal || _motoboy != null;
      return _buildMensagem(
        Icons.search_off,
        comFiltro
            ? 'Nenhum mercado encontrado com esses filtros.'
            : 'Nenhum mercado encontrado.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: mercados.length,
      itemBuilder: (_, i) => _buildCardMercado(mercados[i]),
    );
  }

  Widget _buildCardMercado(Map<String, dynamic> mercado) {
    final distancia = _distancia(mercado);
    final avaliacoes = _toInt(mercado['nul_avaliacoes']);
    final temMotoboy = _toBool(mercado['fl_motoboy']);
    final promocoes = _toInt(mercado['qt_promocoes']);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PerfilMercado(
              idMercado: _toInt(mercado['id_mercado']),
              idUsuario: widget.idUsuario,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildImagem(
                (mercado['ds_foto_mercado'] ?? '').toString(),
                Icons.store,
                52,
                circular: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (mercado['nm_mercado'] ?? '').toString(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (distancia != null)
                          _buildInfo(
                            Icons.location_on,
                            LocalizacaoService.formatar(distancia),
                            Colors.grey.shade700,
                          ),
                        _buildInfo(
                          Icons.star,
                          avaliacoes == 0
                              ? 'Sem avaliações'
                              : _toDouble(mercado['nu_avg_nota'])
                                    .toStringAsFixed(1)
                                    .replaceAll('.', ','),
                          avaliacoes == 0 ? Colors.grey : Colors.amber.shade800,
                        ),
                        _buildInfo(
                          Icons.delivery_dining,
                          temMotoboy ? 'Tele-entrega' : 'Sem tele-entrega',
                          temMotoboy ? Colors.green.shade700 : Colors.grey,
                        ),
                        if (promocoes > 0)
                          _buildInfo(
                            Icons.local_offer,
                            promocoes == 1
                                ? '1 promoção'
                                : '$promocoes promoções',
                            Colors.red,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  void _escolherRaio() {
    _escolherOpcao<int?>(
      titulo: 'Distância máxima',
      atual: _raioKm,
      opcoes: [
        ..._raiosKm.map((km) => (km as int?, 'Até $km km')),
        (null, 'Qualquer distância'),
      ],
      aoEscolher: (v) => setState(() => _raioKm = v),
    );
  }

  void _escolherTeleEntrega() {
    _escolherOpcao<bool?>(
      titulo: 'Tele-entrega',
      atual: _motoboy,
      opcoes: const [
        (null, 'Todos'),
        (true, 'Com tele-entrega'),
        (false, 'Sem tele-entrega'),
      ],
      aoEscolher: (v) {
        setState(() => _motoboy = v);
        _buscarMercados();
      },
    );
  }

  Future<void> _escolherMaisFiltrosMercado() async {
    var nota = _notaMinima;
    var comPromocao = _somenteComPromocao;

    final aplicar = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (contextoSheet) => StatefulBuilder(
        builder: (contextoSheet, setStateSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mais filtros',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('Avaliação mínima'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final opcao in <(double?, String)>[
                      (null, 'Qualquer'),
                      (3, '3+'),
                      (4, '4+'),
                      (4.5, '4,5+'),
                    ])
                      ChoiceChip(
                        avatar: opcao.$1 == null
                            ? null
                            : const Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber,
                              ),
                        label: Text(opcao.$2),
                        selected: nota == opcao.$1,
                        selectedColor: Colors.red.shade50,
                        onSelected: (_) => setStateSheet(() => nota = opcao.$1),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: comPromocao,
                  activeThumbColor: Colors.red,
                  title: const Text('Somente mercados com promoções'),
                  onChanged: (v) => setStateSheet(() => comPromocao = v),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(contextoSheet, true),
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (aplicar != true) return;

    setState(() {
      _notaMinima = nota;
      _somenteComPromocao = comPromocao;
    });
  }

  Widget _buildLinhaFiltros(List<Widget> chips) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          for (final chip in chips)
            Padding(padding: const EdgeInsets.only(right: 8), child: chip),
        ],
      ),
    );
  }

  Widget _buildChipFiltro({
    required String rotulo,
    required bool ativo,
    required VoidCallback? onTap,
    IconData? icone,
  }) {
    return FilterChip(
      avatar: icone == null ? null : Icon(icone, size: 18),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Text(rotulo), const Icon(Icons.arrow_drop_down, size: 18)],
      ),
      selected: ativo,
      showCheckmark: false,
      selectedColor: Colors.red.shade50,
      onSelected: onTap == null ? null : (_) => onTap(),
    );
  }

  Widget _buildLinhaOrdenacao<T>({
    required int? quantidade,
    required String singular,
    required String plural,
    required T atual,
    required List<T> opcoes,
    required String Function(T) rotulo,
    required bool Function(T) habilitada,
    required ValueChanged<T> aoEscolher,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              quantidade == null
                  ? ''
                  : quantidade == 1
                  ? '1 $singular'
                  : '$quantidade $plural',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          PopupMenuButton<T>(
            initialValue: atual,
            onSelected: aoEscolher,
            itemBuilder: (_) => [
              for (final opcao in opcoes)
                PopupMenuItem<T>(
                  value: opcao,
                  enabled: habilitada(opcao),
                  child: Text(rotulo(opcao)),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sort, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'Ordenar: ${rotulo(atual)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _escolherOpcao<T>({
    required String titulo,
    required T atual,
    required List<(T, String)> opcoes,
    required ValueChanged<T> aoEscolher,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (contextoSheet) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(contextoSheet).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final opcao in opcoes)
                      ListTile(
                        title: Text(opcao.$2),
                        trailing: opcao.$1 == atual
                            ? const Icon(Icons.check, color: Colors.red)
                            : null,
                        onTap: () {
                          Navigator.pop(contextoSheet);
                          aoEscolher(opcao.$1);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMensagem(IconData icone, String texto, {Widget? acao}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            if (acao != null) ...[const SizedBox(height: 8), acao],
          ],
        ),
      ),
    );
  }

  Widget _buildImagem(
    String url,
    IconData iconePadrao,
    double tamanho, {
    bool circular = false,
  }) {
    final raio = BorderRadius.circular(circular ? tamanho : 8);

    return ClipRRect(
      borderRadius: raio,
      child: Container(
        width: tamanho,
        height: tamanho,
        color: Colors.grey.shade200,
        child: url.isEmpty
            ? Icon(iconePadrao, color: Colors.grey, size: tamanho / 2)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(iconePadrao, color: Colors.grey, size: tamanho / 2),
              ),
      ),
    );
  }

  Widget _buildInfo(IconData icone, String texto, Color cor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 14, color: cor),
        const SizedBox(width: 3),
        Text(texto, style: TextStyle(fontSize: 12, color: cor)),
      ],
    );
  }

  List<Map<String, dynamic>> _listaDeMapas(dynamic dados) {
    if (dados is! List) return [];
    return dados
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _formatarValor(dynamic valor) {
    final numero = double.tryParse(valor.toString().replaceAll(',', '.')) ?? 0;
    return 'R\$ ${numero.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  int _toInt(dynamic valor) => int.tryParse(valor.toString()) ?? 0;

  double _toDouble(dynamic valor) =>
      double.tryParse(valor.toString().replaceAll(',', '.')) ?? 0;

  bool _toBool(dynamic valor) {
    if (valor is bool) return valor;
    return valor.toString().toLowerCase() == 'true' || valor.toString() == '1';
  }
}
