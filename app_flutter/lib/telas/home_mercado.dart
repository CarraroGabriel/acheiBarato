import 'package:flutter/material.dart';
import 'package:achei_barato/services/api_service.dart';
import 'package:achei_barato/telas/edita_produto.dart';
import 'package:achei_barato/telas/editar_mercado.dart';
import 'package:achei_barato/telas/produtos_mercado.dart';
import 'package:achei_barato/telas/registro_produto.dart';
import 'package:achei_barato/widgets/app_bar.dart';
import 'package:achei_barato/widgets/imagem_app.dart';
import 'package:achei_barato/widgets/bottomnav_mercado.dart';
import 'package:achei_barato/widgets/menu_lateral.dart';
import 'package:achei_barato/widgets/tempo_promocao.dart';

class HomeMercado extends StatefulWidget {
  final int idMercado;
  final String nomeMercado;

  const HomeMercado({
    super.key,
    required this.idMercado,
    required this.nomeMercado,
  });

  @override
  State<HomeMercado> createState() => _HomeMercadoState();
}

class _HomeMercadoState extends State<HomeMercado> {
  static const int _maxPromocoesHome = 10;

  late String _nomeMercado = widget.nomeMercado;
  Map<String, dynamic> _resumo = {};
  List<Map<String, dynamic>> _promocoes = [];
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
        ApiService.get('mercados/${widget.idMercado}/resumo'),
        ApiService.get('mercados/${widget.idMercado}/promocoes'),
      ]);

      if (!mounted) return;

      final resumo = Map<String, dynamic>.from(resultados[0]['dados'] as Map);

      setState(() {
        _resumo = resumo;
        _nomeMercado = (resumo['nm_mercado'] ?? _nomeMercado).toString();
        _promocoes = _listaDeMapas(resultados[1]['dados'])
            .take(_maxPromocoesHome)
            .toList();
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

  Future<void> _abrirERecarregar(Widget tela) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => tela),
    );
    if (resultado != null) _carregar();
  }

  void _abrirProdutos(FiltroProdutos filtro) {
    BottomNavMercado.abrirProdutos(
      context,
      idMercado: widget.idMercado,
      nomeMercado: _nomeMercado,
      filtro: filtro,
    );
  }

  void _abrirEditarMercado() =>
      _abrirERecarregar(EditarMercado(idMercado: widget.idMercado));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AcheiBaratoAppBar(
        exibirBotaoVoltar: false,
        exibirMenu: true,
        acoes: [
          IconButton(
            tooltip: 'Notificações',
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      drawer: MenuLateral(
        nome: _nomeMercado,
        id: widget.idMercado,
        isUsuario: false,
        aoAlterarPerfil: (_) => _carregar(),
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavMercado(
        indiceAtual: 0,
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

    final cadastrados = _toInt(_resumo['produtos_cadastrados']);

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Olá, $_nomeMercado!',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            'Gerencie seus produtos.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () =>
                _abrirERecarregar(RegistroProduto(idMercado: widget.idMercado)),
            icon: const Icon(Icons.add),
            label: const Text('Registrar produto'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildTitulo('Visão geral'),
          _buildInformacoesFaltantes(),
          if (cadastrados == 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Este mercado ainda não possui produtos cadastrados.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              _buildCardNumero(
                icone: Icons.inventory_2,
                cor: Colors.blueGrey,
                titulo: 'Produtos cadastrados',
                valor: cadastrados,
                onTap: () => _abrirProdutos(FiltroProdutos.todos),
              ),
              _buildCardNumero(
                icone: Icons.local_offer,
                cor: Colors.red,
                titulo: 'Em promoção',
                valor: _toInt(_resumo['produtos_promocao']),
                onTap: () => _abrirProdutos(FiltroProdutos.promocao),
              ),
              _buildCardNumero(
                icone: Icons.check_circle,
                cor: Colors.green.shade700,
                titulo: 'Disponíveis',
                valor: _toInt(_resumo['produtos_disponiveis']),
                onTap: () => _abrirProdutos(FiltroProdutos.disponiveis),
              ),
              _buildCardNumero(
                icone: Icons.warning_amber,
                cor: Colors.orange.shade800,
                titulo: 'Estoque baixo',
                valor: _toInt(_resumo['produtos_estoque_baixo']),
                onTap: () => _abrirProdutos(FiltroProdutos.estoqueBaixo),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildCardReputacao(),
          const SizedBox(height: 24),
          _buildTitulo('Atenção'),
          _buildAtencao(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildTitulo('Promoções atuais')),
              TextButton(
                onPressed: () => _abrirProdutos(FiltroProdutos.promocao),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Ver todas', style: TextStyle(color: Colors.red)),
                    Icon(Icons.chevron_right, color: Colors.red, size: 18),
                  ],
                ),
              ),
            ],
          ),
          _buildPromocoes(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTitulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInformacoesFaltantes() {
    final faltantes = Map<String, dynamic>.from(
      (_resumo['informacoes_faltantes'] as Map?) ?? {},
    );
    final semHorario = _toBool(faltantes['horario']);
    final semFoto = _toBool(faltantes['foto']);

    if (!semHorario && !semFoto) return const SizedBox.shrink();

    final detalhe = semHorario && semFoto
        ? 'Adicione o horário de funcionamento e a foto do estabelecimento.'
        : semHorario
        ? 'Horário de funcionamento não informado.'
        : 'Foto do estabelecimento não cadastrada.';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _abrirEditarMercado,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade800),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informações do mercado incompletas',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detalhe,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.orange.shade800),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardNumero({
    required IconData icone,
    required Color cor,
    required String titulo,
    required int valor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icone, color: cor, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
            Text(
              '$valor',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardReputacao() {
    final avaliacoes = _toInt(_resumo['quantidade_avaliacoes']);
    final favoritos = _toInt(_resumo['quantidade_favoritos']);
    final nota = double.tryParse('${_resumo['nota_media']}') ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    SizedBox(width: 6),
                    Text('Avaliação', style: TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                if (avaliacoes == 0)
                  Text(
                    'Este mercado ainda não possui avaliações.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  )
                else ...[
                  Text(
                    nota.toStringAsFixed(1).replaceAll('.', ','),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _plural(avaliacoes, 'avaliação', 'avaliações'),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
          Container(width: 1, height: 60, color: Colors.grey.shade300),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.red, size: 20),
                    SizedBox(width: 6),
                    Text('Favoritos', style: TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                if (favoritos == 0)
                  Text(
                    'Nenhum usuário favoritou o mercado ainda.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  )
                else ...[
                  Text(
                    '$favoritos',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    favoritos == 1 ? 'usuário' : 'usuários',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtencao() {
    final estoqueBaixo = _toInt(_resumo['produtos_estoque_baixo']);
    final indisponiveis = _toInt(_resumo['produtos_indisponiveis']);

    if (estoqueBaixo == 0 && indisponiveis == 0) {
      return Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Text(
            'Nenhuma pendência no momento.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (estoqueBaixo > 0)
          _buildItemAtencao(
            Icons.warning_amber,
            Colors.orange.shade800,
            '${_plural(estoqueBaixo, 'produto', 'produtos')} com estoque baixo',
            () => _abrirProdutos(FiltroProdutos.estoqueBaixo),
          ),
        if (indisponiveis > 0)
          _buildItemAtencao(
            Icons.block,
            Colors.grey.shade700,
            _plural(
              indisponiveis,
              'produto indisponível',
              'produtos indisponíveis',
            ),
            () => _abrirProdutos(FiltroProdutos.indisponiveis),
          ),
      ],
    );
  }

  Widget _buildItemAtencao(
    IconData icone,
    Color cor,
    String texto,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icone, color: cor),
        title: Text(texto, style: const TextStyle(fontSize: 14)),
        trailing: const Icon(Icons.chevron_right),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildPromocoes() {
    if (_promocoes.isEmpty) {
      return Text(
        'Nenhum produto em promoção.',
        style: TextStyle(color: Colors.grey.shade700),
      );
    }

    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _promocoes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _buildCardPromocao(_promocoes[i]),
      ),
    );
  }

  Widget _buildCardPromocao(Map<String, dynamic> produto) {
    return InkWell(
      onTap: () => _abrirERecarregar(
        EdicaoProduto(idProdutoMercado: _toInt(produto['id_produto_mercado'])),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ImagemApp.produto(produto, tamanhoIcone: 32),
                  ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _toInt(produto['nu_desconto']) > 0
                            ? '-${_toInt(produto['nu_desconto'])}%'
                            : 'PROMO',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              (produto['ds_item_produto'] ?? produto['nm_produto'] ?? '')
                  .toString(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Text(
              (produto['nm_marca'] ?? '').toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            Text(
              _formatarValor(produto['nu_valor_final'] ?? produto['nu_valor']),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            TempoPromocao(
              segundosRestantes: produto['nu_segundos_restantes'],
              tamanhoFonte: 10,
            ),
          ],
        ),
      ),
    );
  }

  String _plural(int quantidade, String singular, String plural) =>
      '$quantidade ${quantidade == 1 ? singular : plural}';

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
