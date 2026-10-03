import 'package:flutter/material.dart';
import 'package:achei_barato/services/api_service.dart';
import 'package:achei_barato/telas/edita_produto.dart';
import 'package:achei_barato/telas/registro_produto.dart';
import 'package:achei_barato/widgets/app_bar.dart';
import 'package:achei_barato/widgets/bottomnav_mercado.dart';
import 'package:achei_barato/widgets/menu_lateral.dart';
import 'package:achei_barato/widgets/tempo_promocao.dart';

// Situações usadas para filtrar a lista (e pelos atalhos da home do mercado).
enum FiltroProdutos {
  todos('Todos', 'Este mercado ainda não possui produtos cadastrados.'),
  promocao('Em promoção', 'Nenhum produto em promoção.'),
  disponiveis('Disponíveis', 'Nenhum produto disponível.'),
  indisponiveis('Indisponíveis', 'Nenhum produto indisponível.'),
  estoqueBaixo('Estoque baixo', 'Nenhum produto com estoque baixo.');

  final String rotulo;
  final String mensagemVazia;

  const FiltroProdutos(this.rotulo, this.mensagemVazia);
}

class ProdutosMercado extends StatefulWidget {
  final int idMercado;
  final String nomeMercado;
  final FiltroProdutos filtroInicial;

  const ProdutosMercado({
    super.key,
    required this.idMercado,
    required this.nomeMercado,
    this.filtroInicial = FiltroProdutos.todos,
  });

  @override
  State<ProdutosMercado> createState() => _ProdutosMercadoState();
}

class _ProdutosMercadoState extends State<ProdutosMercado> {
  late String _nomeMercado = widget.nomeMercado;
  late FiltroProdutos _filtro = widget.filtroInicial;
  int? _idCategoria; // null = todas as categorias

  List<Map<String, dynamic>> _produtos = [];
  List<Map<String, dynamic>> _categorias = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resultados = await Future.wait([
        ApiService.get('produto_mercado?mercado=${widget.idMercado}'),
        ApiService.get('categorias'),
      ]);

      if (!mounted) return;

      setState(() {
        _produtos = _listaDeMapas(resultados[0]['dados']);
        _categorias = _listaDeMapas(resultados[1]['dados']);
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } catch (_) {
      if (mounted) {
        setState(() => _erro = 'Não foi possível conectar ao servidor.');
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  List<Map<String, dynamic>> get _produtosFiltrados {
    return _produtos.where((p) {
      final atendeSituacao = switch (_filtro) {
        FiltroProdutos.todos => true,
        FiltroProdutos.promocao => _toBool(p['fl_promocao']),
        FiltroProdutos.disponiveis => _toBool(p['fl_disponivel']),
        FiltroProdutos.indisponiveis => !_toBool(p['fl_disponivel']),
        FiltroProdutos.estoqueBaixo => _toBool(p['fl_estoque_baixo']),
      };

      final atendeCategoria =
          _idCategoria == null || _toInt(p['id_categoria']) == _idCategoria;

      return atendeSituacao && atendeCategoria;
    }).toList();
  }

  Future<void> _registrarProduto() async {
    final alterou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RegistroProduto(idMercado: widget.idMercado),
      ),
    );
    if (alterou == true) _carregar();
  }

  Future<void> _editarProduto(Map<String, dynamic> produto) async {
    final alterou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EdicaoProduto(
          idProdutoMercado: _toInt(produto['id_produto_mercado']),
        ),
      ),
    );
    if (alterou == true) _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AcheiBaratoAppBar(
        exibirBotaoVoltar: false,
        exibirMenu: true,
      ),
      drawer: MenuLateral(
        nome: _nomeMercado,
        id: widget.idMercado,
        isUsuario: false,
        aoAlterarPerfil: (nome) => setState(() => _nomeMercado = nome),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        onPressed: _registrarProduto,
        icon: const Icon(Icons.add),
        label: const Text('Produto'),
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavMercado(
        indiceAtual: 1,
        idMercado: widget.idMercado,
        nomeMercado: _nomeMercado,
      ),
    );
  }

  Widget _buildBody() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 12),
              Text(_erro!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _carregar,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final produtos = _produtosFiltrados;

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: FiltroProdutos.values
                  .map(
                    (filtro) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filtro.rotulo),
                        selected: _filtro == filtro,
                        selectedColor: Colors.red.shade100,
                        onSelected: (_) => setState(() => _filtro = filtro),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            initialValue: _idCategoria,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Categoria',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Todas as categorias'),
              ),
              ..._categorias.map(
                (c) => DropdownMenuItem<int?>(
                  value: _toInt(c['id_categoria']),
                  child: Text(c['nm_categoria'].toString()),
                ),
              ),
            ],
            onChanged: (valor) => setState(() => _idCategoria = valor),
          ),
          const SizedBox(height: 12),
          Text(
            produtos.length == 1 ? '1 produto' : '${produtos.length} produtos',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          if (produtos.isEmpty)
            _buildVazio()
          else
            ...produtos.map(_buildCardProduto),
        ],
      ),
    );
  }

  Widget _buildVazio() {
    final semProdutos = _produtos.isEmpty;
    final mensagem = semProdutos
        ? FiltroProdutos.todos.mensagemVazia
        : _idCategoria != null && _filtro == FiltroProdutos.todos
        ? 'Nenhum produto nesta categoria.'
        : _filtro.mensagemVazia;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          if (semProdutos) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _registrarProduto,
              icon: const Icon(Icons.add, color: Colors.red),
              label: const Text(
                'Registrar produto',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardProduto(Map<String, dynamic> produto) {
    final foto = (produto['ds_foto_produto'] ?? '').toString();
    final disponivel = _toBool(produto['fl_disponivel']);
    final promocao = _toBool(produto['fl_promocao']);
    final estoqueBaixo = _toBool(produto['fl_estoque_baixo']);
    final desconto = _toInt(produto['nu_desconto']);

    return InkWell(
      onTap: () => _editarProduto(produto),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 64,
                height: 64,
                color: Colors.grey.shade200,
                child: foto.isNotEmpty
                    ? Image.network(
                        foto,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.image, color: Colors.grey),
                      )
                    : const Icon(Icons.image, color: Colors.grey, size: 30),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (produto['ds_item_produto'] ?? produto['nm_produto'] ?? '')
                        .toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Marca: ${produto['nm_marca'] ?? ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  Text(
                    'Categoria: ${produto['ds_categoria'] ?? ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      Text(
                        _formatarValor(
                          produto['nu_valor_final'] ?? produto['nu_valor'],
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      if (promocao && desconto > 0)
                        Text(
                          '${_formatarValor(produto['nu_valor'])}  -$desconto%',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildSelo(
                        estoqueBaixo ? Icons.warning_amber : Icons.numbers,
                        'Estoque: ${_toInt(produto['nu_qtde'])}',
                        estoqueBaixo
                            ? Colors.orange.shade800
                            : Colors.grey.shade700,
                      ),
                      disponivel
                          ? _buildSelo(
                              Icons.check_circle_outline,
                              'Disponível',
                              Colors.green.shade700,
                            )
                          : _buildSelo(
                              Icons.block,
                              'Indisponível',
                              Colors.grey.shade700,
                            ),
                      if (promocao)
                        _buildSelo(Icons.local_offer, 'Promoção', Colors.red),
                      if (_toBool(produto['fl_promocao_expirada']))
                        _buildSelo(
                          Icons.timer_off_outlined,
                          'Promoção expirada',
                          Colors.orange.shade800,
                        ),
                    ],
                  ),
                  if (promocao)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: TempoPromocao(
                        segundosRestantes: produto['nu_segundos_restantes'],
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildSelo(IconData icone, String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 13, color: cor),
          const SizedBox(width: 3),
          Text(texto, style: TextStyle(fontSize: 11, color: cor)),
        ],
      ),
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

  bool _toBool(dynamic valor) {
    if (valor is bool) return valor;
    return valor.toString().toLowerCase() == 'true' || valor.toString() == '1';
  }
}
