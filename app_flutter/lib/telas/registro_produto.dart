import 'package:flutter/material.dart';
import 'package:achei_barato/services/api_service.dart';
import 'package:achei_barato/widgets/app_bar.dart';
import 'package:achei_barato/widgets/botao_primario.dart';
import 'package:achei_barato/widgets/imagem_app.dart';

class RegistroProduto extends StatefulWidget {
  final int idMercado;

  const RegistroProduto({super.key, required this.idMercado});

  @override
  State<RegistroProduto> createState() => _RegistroProdutoState();
}

class _RegistroProdutoState extends State<RegistroProduto> {
  final _produtoController = TextEditingController();
  final _tipoController = TextEditingController();
  final _marcaController = TextEditingController();
  final _medidaController = TextEditingController();
  final _valorController = TextEditingController();
  final _qtdeController = TextEditingController();

  final _produtoFocus = FocusNode();
  final _tipoFocus = FocusNode();
  final _marcaFocus = FocusNode();

  // Listas vindas da API.
  List<Map<String, dynamic>> _categorias = [];
  List<Map<String, dynamic>> _produtos = [];
  List<Map<String, dynamic>> _marcas = [];
  List<Map<String, dynamic>> _unidades = [];

  int? _idCategoria;

  Map<String, dynamic>? _produtoSelecionado;
  int? _idUnidade;

  bool _carregandoListas = true;
  String? _erroListas;
  bool _carregandoProduto = false;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _carregarListas();
  }

  @override
  void dispose() {
    _produtoController.dispose();
    _tipoController.dispose();
    _marcaController.dispose();
    _medidaController.dispose();
    _valorController.dispose();
    _qtdeController.dispose();
    _produtoFocus.dispose();
    _tipoFocus.dispose();
    _marcaFocus.dispose();
    super.dispose();
  }

  Future<void> _carregarListas() async {
    setState(() {
      _carregandoListas = true;
      _erroListas = null;
    });

    try {
      final resultados = await Future.wait([
        ApiService.get('categorias'),
        ApiService.get('produtos'),
        ApiService.get('marcas'),
        ApiService.get('unidades'),
      ]);

      if (!mounted) return;

      setState(() {
        _categorias = _listaDeMapas(resultados[0]['dados']);
        _produtos = _listaDeMapas(resultados[1]['dados']);
        _marcas = _listaDeMapas(resultados[2]['dados']);
        _unidades = _listaDeMapas(resultados[3]['dados']);
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _erroListas = e.mensagem);
    } catch (_) {
      if (mounted) {
        setState(() => _erroListas = 'Não foi possível conectar ao servidor.');
      }
    } finally {
      if (mounted) setState(() => _carregandoListas = false);
    }
  }

  void _onCategoriaAlterada(int? idCategoria) {
    setState(() {
      _idCategoria = idCategoria;
      _produtoSelecionado = null;
      _produtoController.clear();
      _tipoController.clear();
      _marcaController.clear();
    });
  }

  void _onProdutoAlterado(String texto) {
    final existente = _buscarPorNome(_produtosDaCategoria, 'nm_produto', texto);

    if (existente == null) {
      setState(() => _produtoSelecionado = null);
      return;
    }

    final idProduto = _toInt(existente['id_produto']);
    if (_toInt(_produtoSelecionado?['id_produto']) == idProduto) {
      setState(() {});
      return;
    }

    _carregarProduto(idProduto);
  }

  Future<void> _carregarProduto(int idProduto) async {
    setState(() {
      _produtoSelecionado = null;
      _carregandoProduto = true;
    });

    try {
      final resposta = await ApiService.get('produtos/$idProduto');
      final produto = Map<String, dynamic>.from(resposta['dados'] as Map);

      if (!mounted) return;

      final atual = _buscarPorNome(
        _produtosDaCategoria,
        'nm_produto',
        _produtoController.text,
      );
      if (_toInt(atual?['id_produto']) != idProduto) return;

      setState(() => _produtoSelecionado = produto);
    } on ApiException catch (e) {
      _mostrarMensagem(e.mensagem);
    } catch (_) {
      _mostrarMensagem('Não foi possível carregar o produto.');
    } finally {
      if (mounted) setState(() => _carregandoProduto = false);
    }
  }

  Future<void> _registrarProduto() async {
    final nomeProduto = _produtoController.text.trim();
    final nomeTipo = _tipoController.text.trim();
    final nomeMarca = _marcaController.text.trim();

    if (_idCategoria == null) {
      _mostrarMensagem('Selecione a categoria.');
      return;
    }

    final emOutraCategoria = _produtoEmOutraCategoria;
    if (emOutraCategoria != null) {
      _mostrarMensagem(
        'Este produto pertence à categoria ${emOutraCategoria['nm_categoria']}.',
      );
      return;
    }

    if (nomeProduto.isEmpty ||
        nomeTipo.isEmpty ||
        nomeMarca.isEmpty ||
        _medidaController.text.trim().isEmpty ||
        _idUnidade == null ||
        _valorController.text.trim().isEmpty ||
        _qtdeController.text.trim().isEmpty) {
      _mostrarMensagem('Preencha todos os campos do produto.');
      return;
    }

    final medida = double.tryParse(_medidaController.text.replaceAll(',', '.'));
    final valor = double.tryParse(_valorController.text.replaceAll(',', '.'));
    final quantidade = int.tryParse(_qtdeController.text);

    if (medida == null || medida <= 0) {
      _mostrarMensagem('Conteúdo da embalagem inválido.');
      return;
    }

    if (valor == null || quantidade == null) {
      _mostrarMensagem('Valor ou quantidade inválidos.');
      return;
    }

    final produto = _buscarPorNome(
      _produtosDaCategoria,
      'nm_produto',
      nomeProduto,
    );
    final tipo = _buscarPorNome(_tiposDoProduto, 'nm_tipo', nomeTipo);
    final marca = _buscarPorNome(_marcas, 'nm_marca', nomeMarca);

    setState(() => _carregando = true);

    try {
      await ApiService.post('produto_mercado', {
        'id_mercado': widget.idMercado,
        'id_categoria': _idCategoria,
        ..._referencia('produto', produto, nomeProduto),
        ..._referencia('tipo', tipo, nomeTipo),
        ..._referencia('marca', marca, nomeMarca),
        'nu_medida': medida,
        'id_unidade': _idUnidade,
        'nu_valor': valor,
        'nu_qtde': quantidade,
        'fl_promocao': false,
        'fl_disponivel': true,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto registrado com sucesso.')),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      _mostrarMensagem(e.mensagem);
    } catch (_) {
      _mostrarMensagem('Não foi possível conectar ao servidor.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Map<String, dynamic> _referencia(
    String campo,
    Map<String, dynamic>? registro,
    String texto,
  ) {
    return registro != null
        ? {'id_$campo': _toInt(registro['id_$campo'])}
        : {'nm_$campo': texto};
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  List<Map<String, dynamic>> get _produtosDaCategoria => _produtos
      .where((p) => _toInt(p['id_categoria']) == _idCategoria)
      .toList();

  List<Map<String, dynamic>> get _tiposDoProduto =>
      _listaDeMapas(_produtoSelecionado?['tipos']);

  List<Map<String, dynamic>> get _marcasDoProduto =>
      _listaDeMapas(_produtoSelecionado?['marcas']);

  Map<String, dynamic>? get _produtoEmOutraCategoria {
    if (_buscarPorNome(
          _produtosDaCategoria,
          'nm_produto',
          _produtoController.text,
        ) !=
        null) {
      return null;
    }
    return _buscarPorNome(_produtos, 'nm_produto', _produtoController.text);
  }

  bool get _produtoNovo =>
      _produtoController.text.trim().isNotEmpty &&
      _buscarPorNome(_produtos, 'nm_produto', _produtoController.text) == null;

  String get _categoria {
    final categoria = _categorias.where(
      (c) => _toInt(c['id_categoria']) == _idCategoria,
    );
    return categoria.isEmpty
        ? 'Categoria'
        : categoria.first['nm_categoria'].toString();
  }

  String? get _ajudaProduto {
    final outra = _produtoEmOutraCategoria;
    if (outra != null) {
      return 'Este produto pertence à categoria ${outra['nm_categoria']}.';
    }
    if (_produtoNovo) return 'Produto novo: será cadastrado em $_categoria.';
    if (_carregandoProduto) return 'Carregando tipos e marcas...';
    return null;
  }

  String get _siglaUnidade {
    final unidade = _unidades.where(
      (u) => _toInt(u['id_unidade']) == _idUnidade,
    );
    return unidade.isEmpty ? '' : unidade.first['sg_unidade'].toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: const AcheiBaratoAppBar(), body: _buildBody());
  }

  Widget _buildBody() {
    if (_carregandoListas) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erroListas != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_erroListas!),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _carregarListas,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final textoTipo = _tipoController.text.trim();
    final textoMarca = _marcaController.text.trim();
    final temCategoria = _idCategoria != null;
    final temProduto =
        temCategoria &&
        _produtoController.text.trim().isNotEmpty &&
        _produtoEmOutraCategoria == null;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Registrar Produto',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildPreVisualizacao(),
            const SizedBox(height: 8),
            Text(
              'Pré-visualização de como o produto aparecerá',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<int>(
              initialValue: _idCategoria,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _categorias
                  .map(
                    (c) => DropdownMenuItem(
                      value: _toInt(c['id_categoria']),
                      child: Text(c['nm_categoria'].toString()),
                    ),
                  )
                  .toList(),
              onChanged: _onCategoriaAlterada,
            ),
            const SizedBox(height: 16),
            _campoAutocomplete(
              controller: _produtoController,
              focusNode: _produtoFocus,
              label: 'Produto',
              icone: Icons.label,
              habilitado: temCategoria,
              opcoes: _produtosDaCategoria
                  .map((p) => p['nm_produto'].toString())
                  .toList(),
              onChanged: _onProdutoAlterado,
              textoAjuda: temCategoria
                  ? _ajudaProduto
                  : 'Selecione a categoria primeiro.',
            ),
            const SizedBox(height: 16),
            _campoAutocomplete(
              controller: _tipoController,
              focusNode: _tipoFocus,
              label: 'Tipo',
              icone: Icons.style,
              habilitado: temProduto,
              opcoes: _tiposDoProduto
                  .map((t) => t['nm_tipo'].toString())
                  .toList(),
              onChanged: (_) => setState(() {}),
              textoAjuda:
                  textoTipo.isNotEmpty &&
                      _buscarPorNome(_tiposDoProduto, 'nm_tipo', textoTipo) ==
                          null
                  ? 'Tipo novo: será cadastrado para este produto.'
                  : null,
            ),
            const SizedBox(height: 16),
            _campoAutocomplete(
              controller: _marcaController,
              focusNode: _marcaFocus,
              label: 'Marca',
              icone: Icons.business_center,
              habilitado: temProduto,
              opcoes: _marcasDoProduto
                  .map((m) => m['nm_marca'].toString())
                  .toList(),
              onChanged: (_) => setState(() {}),
              textoAjuda:
                  textoMarca.isNotEmpty &&
                      _buscarPorNome(
                            _marcasDoProduto,
                            'nm_marca',
                            textoMarca,
                          ) ==
                          null
                  ? 'Marca nova para este produto.'
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _medidaController,
                    onChanged: (_) => setState(() {}),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Conteúdo da embalagem',
                      hintText: 'Ex.: 5',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.scale),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    initialValue: _idUnidade,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Unidade',
                      border: OutlineInputBorder(),
                    ),
                    selectedItemBuilder: (_) => _unidades
                        .map((u) => Text(u['sg_unidade'].toString()))
                        .toList(),
                    items: _unidades
                        .map(
                          (u) => DropdownMenuItem(
                            value: _toInt(u['id_unidade']),
                            child: Text(
                              '${u['sg_unidade']} — ${u['nm_unidade']}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _idUnidade = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _valorController,
              onChanged: (_) => setState(() {}),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Valor (R\$)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _qtdeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Estoque disponível (unidades)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.photo_camera, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Produtos do catálogo já têm imagem padrão. Para enviar uma '
                    'foto, registre o produto e toque nele na lista de produtos.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_carregando)
              const Center(child: CircularProgressIndicator())
            else
              BotaoPrimario(
                texto: 'Registrar Produto',
                onPressed: _registrarProduto,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreVisualizacao() {
    final nome = [
      _produtoController.text.trim(),
      _tipoController.text.trim(),
    ].where((t) => t.isNotEmpty).join(' ').toUpperCase();

    final medida = _medidaController.text.trim();
    final embalagem = medida.isEmpty ? '' : '$medida $_siglaUnidade'.trim();
    final detalhe = [
      _marcaController.text.trim().toUpperCase(),
      embalagem,
    ].where((t) => t.isNotEmpty).join(' • ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 60,
              height: 60,
              child: ImagemApp(
                caminhos: [_produtoSelecionado?['ds_imagem_padrao']],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome.isEmpty ? 'Nome do produto' : nome,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: nome.isEmpty ? Colors.grey : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detalhe.isEmpty ? 'Marca • Embalagem' : detalhe,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  _categoria,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Text(
            _valorController.text.isEmpty
                ? 'R\$ 0,00'
                : 'R\$ ${_valorController.text}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _campoAutocomplete({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icone,
    required List<String> opcoes,
    required ValueChanged<String> onChanged,
    String? textoAjuda,
    bool habilitado = true,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => RawAutocomplete<String>(
        textEditingController: controller,
        focusNode: focusNode,
        optionsBuilder: (valor) {
          final busca = _normalizar(valor.text);
          if (busca.isEmpty) return opcoes;
          return opcoes.where((o) => _normalizar(o).contains(busca));
        },
        onSelected: onChanged,
        fieldViewBuilder: (context, campoController, campoFocus, _) =>
            TextField(
              controller: campoController,
              focusNode: campoFocus,
              enabled: habilitado,
              textCapitalization: TextCapitalization.characters,
              onChanged: onChanged,
              decoration: InputDecoration(
                labelText: label,
                helperText: textoAjuda,
                helperStyle: TextStyle(color: Colors.orange.shade800),
                border: const OutlineInputBorder(),
                prefixIcon: Icon(icone),
              ),
            ),
        optionsViewBuilder: (context, onSelected, sugestoes) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 220,
                maxWidth: constraints.maxWidth,
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: sugestoes
                    .map(
                      (s) => ListTile(
                        dense: true,
                        title: Text(s),
                        onTap: () => onSelected(s),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic>? _buscarPorNome(
    List<Map<String, dynamic>> lista,
    String campo,
    String texto,
  ) {
    final busca = _normalizar(texto);
    if (busca.isEmpty) return null;

    for (final item in lista) {
      if (_normalizar((item[campo] ?? '').toString()) == busca) return item;
    }
    return null;
  }

  static const Map<String, String> _semAcento = {
    'Á': 'A',
    'À': 'A',
    'Â': 'A',
    'Ã': 'A',
    'Ä': 'A',
    'É': 'E',
    'È': 'E',
    'Ê': 'E',
    'Ë': 'E',
    'Í': 'I',
    'Ì': 'I',
    'Î': 'I',
    'Ï': 'I',
    'Ó': 'O',
    'Ò': 'O',
    'Ô': 'O',
    'Õ': 'O',
    'Ö': 'O',
    'Ú': 'U',
    'Ù': 'U',
    'Û': 'U',
    'Ü': 'U',
    'Ç': 'C',
  };

  String _normalizar(String texto) {
    final maiusculo = texto.trim().toUpperCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    return maiusculo.split('').map((c) => _semAcento[c] ?? c).join();
  }

  List<Map<String, dynamic>> _listaDeMapas(dynamic dados) {
    if (dados is! List) return [];
    return dados
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  int _toInt(dynamic valor) => int.tryParse(valor.toString()) ?? 0;
}
