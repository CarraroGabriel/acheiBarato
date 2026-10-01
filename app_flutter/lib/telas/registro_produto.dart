import 'package:flutter/material.dart';
import 'package:achei_barato/services/api_service.dart';
import 'package:achei_barato/widgets/app_bar.dart';
import 'package:achei_barato/widgets/botao_primario.dart';

class RegistroProduto extends StatefulWidget {
  final int idMercado;

  const RegistroProduto({
    super.key,
    required this.idMercado,
  });

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
  List<Map<String, dynamic>> _produtos = [];
  List<Map<String, dynamic>> _marcas = [];
  List<Map<String, dynamic>> _unidades = [];

  // Produto existente selecionado, com seus tipos e marcas sugeridas.
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
        ApiService.get('produtos'),
        ApiService.get('marcas'),
        ApiService.get('unidades'),
      ]);

      if (!mounted) return;

      setState(() {
        _produtos = _listaDeMapas(resultados[0]['dados']);
        _marcas = _listaDeMapas(resultados[1]['dados']);
        _unidades = _listaDeMapas(resultados[2]['dados']);
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

  // Ao digitar ou escolher um produto, carrega tipos, marcas e categoria
  // se ele já existir; caso contrário, o produto será criado como novo.
  void _onProdutoAlterado(String texto) {
    final existente = _buscarPorNome(_produtos, 'nm_produto', texto);

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

      // Ignora a resposta se o usuário já trocou de produto.
      final atual = _buscarPorNome(_produtos, 'nm_produto', _produtoController.text);
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

    final produto = _buscarPorNome(_produtos, 'nm_produto', nomeProduto);
    final tipo = _buscarPorNome(_tiposDoProduto, 'nm_tipo', nomeTipo);
    final marca = _buscarPorNome(_marcas, 'nm_marca', nomeMarca);

    setState(() => _carregando = true);

    try {
      await ApiService.post('produto_mercado', {
        'id_mercado': widget.idMercado,
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

  // Registro existente vai por id; texto novo vai por nome para o backend criar.
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  List<Map<String, dynamic>> get _tiposDoProduto =>
      _listaDeMapas(_produtoSelecionado?['tipos']);

  // Marcas já usadas com o produto aparecem primeiro, depois as demais.
  List<String> get _opcoesMarca {
    final doProduto = _listaDeMapas(_produtoSelecionado?['marcas'])
        .map((m) => m['nm_marca'].toString())
        .toList();
    final demais = _marcas
        .map((m) => m['nm_marca'].toString())
        .where((nome) => !doProduto.contains(nome));
    return [...doProduto, ...demais];
  }

  bool get _produtoNovo =>
      _produtoController.text.trim().isNotEmpty &&
      _buscarPorNome(_produtos, 'nm_produto', _produtoController.text) == null;

  String get _categoria {
    if (_produtoSelecionado != null) {
      return _produtoSelecionado!['nm_categoria'].toString();
    }
    if (_carregandoProduto) return 'Carregando...';
    return _produtoNovo ? 'OUTRO' : 'Selecione o produto';
  }

  String get _siglaUnidade {
    final unidade = _unidades.where(
      (u) => _toInt(u['id_unidade']) == _idUnidade,
    );
    return unidade.isEmpty ? '' : unidade.first['sg_unidade'].toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AcheiBaratoAppBar(),
      body: _buildBody(),
    );
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
            _campoAutocomplete(
              controller: _produtoController,
              focusNode: _produtoFocus,
              label: 'Produto',
              icone: Icons.label,
              opcoes: _produtos.map((p) => p['nm_produto'].toString()).toList(),
              onChanged: _onProdutoAlterado,
              textoAjuda: _produtoNovo
                  ? 'Produto novo: será cadastrado na categoria OUTRO.'
                  : null,
            ),
            const SizedBox(height: 16),
            _campoAutocomplete(
              controller: _tipoController,
              focusNode: _tipoFocus,
              label: 'Tipo',
              icone: Icons.style,
              opcoes: _tiposDoProduto.map((t) => t['nm_tipo'].toString()).toList(),
              onChanged: (_) => setState(() {}),
              textoAjuda: textoTipo.isNotEmpty &&
                      _buscarPorNome(_tiposDoProduto, 'nm_tipo', textoTipo) == null
                  ? 'Tipo novo: será cadastrado para este produto.'
                  : null,
            ),
            const SizedBox(height: 16),
            _campoAutocomplete(
              controller: _marcaController,
              focusNode: _marcaFocus,
              label: 'Marca',
              icone: Icons.business_center,
              opcoes: _opcoesMarca,
              onChanged: (_) => setState(() {}),
              textoAjuda: textoMarca.isNotEmpty &&
                      _buscarPorNome(_marcas, 'nm_marca', textoMarca) == null
                  ? 'Marca nova: será cadastrada.'
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
                            child: Text('${u['sg_unidade']} — ${u['nm_unidade']}'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _idUnidade = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Categoria',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
                suffixIcon: Icon(Icons.lock_outline),
                enabled: false,
              ),
              child: Text(
                _categoria,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _valorController,
              onChanged: (_) => setState(() {}),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
            OutlinedButton.icon(
              onPressed: () {
                _mostrarMensagem(
                  'Upload de foto será integrado em uma etapa específica.',
                );
              },
              icon: const Icon(Icons.add_photo_alternate, color: Colors.red),
              label: const Text(
                'Adicionar Foto',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
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
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.image, color: Colors.grey, size: 30),
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

  // Campo de texto com sugestões: o mercadista escolhe da lista ou digita um valor novo.
  Widget _campoAutocomplete({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icone,
    required List<String> opcoes,
    required ValueChanged<String> onChanged,
    String? textoAjuda,
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
        fieldViewBuilder: (context, campoController, campoFocus, _) => TextField(
          controller: campoController,
          focusNode: campoFocus,
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

  // Compara nomes sem diferenciar maiúsculas, acentos e espaços extras,
  // para "feijao" encontrar "FEIJÃO" em vez de criar um duplicado.
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
    'Á': 'A', 'À': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A',
    'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E',
    'Í': 'I', 'Ì': 'I', 'Î': 'I', 'Ï': 'I',
    'Ó': 'O', 'Ò': 'O', 'Ô': 'O', 'Õ': 'O', 'Ö': 'O',
    'Ú': 'U', 'Ù': 'U', 'Û': 'U', 'Ü': 'U',
    'Ç': 'C',
  };

  String _normalizar(String texto) {
    final maiusculo = texto.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
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
