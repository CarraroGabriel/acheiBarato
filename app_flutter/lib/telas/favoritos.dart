import 'package:flutter/material.dart';
import 'package:achei_barato/services/api_service.dart';
import 'package:achei_barato/services/localizacao_service.dart';
import 'package:achei_barato/telas/perfil_mercado.dart';
import 'package:achei_barato/widgets/app_bar.dart';
import 'package:achei_barato/widgets/bottomnav.dart';
import 'package:achei_barato/widgets/menu_lateral.dart';

class Favoritos extends StatefulWidget {
  final int idUsuario;
  final String nomeUsuario;

  const Favoritos({
    super.key,
    required this.idUsuario,
    required this.nomeUsuario,
  });

  @override
  State<Favoritos> createState() => _FavoritosState();
}

class _FavoritosState extends State<Favoritos> {
  late String _nomeUsuario = widget.nomeUsuario;
  bool _carregando = true;
  String? _erro;
  List<Map<String, dynamic>> _mercados = [];
  List<Map<String, dynamic>> _produtos = [];
  PosicaoUsuario? _posicao;

  @override
  void initState() {
    super.initState();
    _carregarFavoritos();
    _carregarLocalizacao();
  }

  Future<void> _carregarFavoritos() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resposta = await ApiService.get(
        'favoritos?id_usuario=${widget.idUsuario}',
      );
      final dados = Map<String, dynamic>.from(resposta['dados'] as Map);

      if (!mounted) return;

      setState(() {
        _mercados = _listaDeMapas(dados['mercados']);
        _produtos = _listaDeMapas(dados['produtos']);
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

  Future<void> _carregarLocalizacao() async {
    final posicao = await LocalizacaoService.obterPosicao();
    if (!mounted) return;
    setState(() => _posicao = posicao);
  }

  Future<void> _atualizar() async {
    _carregarLocalizacao();
    await _carregarFavoritos();
  }

  List<Map<String, dynamic>> _listaDeMapas(dynamic dados) {
    if (dados is! List) return [];
    return dados
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  void _abrirMercado(int idMercado) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PerfilMercado(idMercado: idMercado, idUsuario: widget.idUsuario),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      body: _buildBody(),
      bottomNavigationBar: BottomNav(
        indiceAtual: 2,
        idUsuario: widget.idUsuario,
        nomeUsuario: _nomeUsuario,
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
              const SizedBox(height: 8),
              Text(_erro!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _carregarFavoritos,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final vazio = _mercados.isEmpty && _produtos.isEmpty;

    return RefreshIndicator(
      onRefresh: _atualizar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: vazio ? _buildVazio() : _buildConteudo(),
      ),
    );
  }

  Widget _buildVazio() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
      child: Column(
        children: [
          Icon(Icons.favorite_border, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Você ainda não possui mercados ou produtos favoritos.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildConteudo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTituloSecao(Icons.store, 'Mercados favoritos'),
        const SizedBox(height: 12),
        if (_mercados.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Você ainda não possui mercados favoritos.'),
          )
        else
          SizedBox(
            height: 210,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _mercados.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _buildCardMercado(_mercados[i]),
            ),
          ),
        const SizedBox(height: 24),
        _buildTituloSecao(Icons.favorite, 'Produtos favoritos'),
        const SizedBox(height: 12),
        if (_produtos.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Você ainda não possui produtos favoritos.'),
          )
        else
          ..._produtos.map(_buildGrupoProduto),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTituloSecao(IconData icone, String titulo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icone, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Text(
            titulo,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCardMercado(Map<String, dynamic> mercado) {
    final idMercado = _toInt(mercado['id_mercado']);
    final qtPromocoes = _toInt(mercado['qt_promocoes']);
    final temMotoboy = _toBool(mercado['fl_motoboy']);
    final horarioHoje = mercado['horario_hoje']?.toString();
    final abertoAgora = mercado['aberto_agora'];

    final distancia = LocalizacaoService.distanciaMetros(
      _posicao,
      _numero(mercado['nu_latitude']),
      _numero(mercado['nu_longitude']),
    );

    String textoHorario;
    if (horarioHoje != null && horarioHoje.isNotEmpty) {
      textoHorario = horarioHoje;
    } else if (abertoAgora == false) {
      textoHorario = 'Fechado hoje';
    } else {
      textoHorario = 'Horário não informado';
    }

    return GestureDetector(
      onTap: () => _abrirMercado(idMercado),
      child: Container(
        width: 210,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.store, color: Colors.red, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    (mercado['nm_mercado'] ?? '').toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildLinhaInfo(
              Icons.star,
              Colors.amber,
              '${_formatarNota(mercado['nu_avg_nota'])}  •  ${_toInt(mercado['nul_avaliacoes'])} avaliações',
            ),
            const SizedBox(height: 4),
            _buildLinhaInfo(
              Icons.access_time,
              Colors.grey.shade600,
              textoHorario,
            ),
            if (abertoAgora != null) ...[
              const SizedBox(height: 4),
              _buildLinhaInfo(
                Icons.circle,
                abertoAgora == true ? Colors.green : Colors.red,
                abertoAgora == true ? 'Aberto agora' : 'Fechado agora',
              ),
            ],
            const SizedBox(height: 4),
            _buildLinhaInfo(
              Icons.delivery_dining,
              temMotoboy ? Colors.green.shade600 : Colors.grey,
              temMotoboy ? 'Motoboy' : 'Sem motoboy',
            ),
            const SizedBox(height: 4),
            _buildLinhaInfo(
              Icons.local_offer,
              qtPromocoes > 0 ? Colors.red : Colors.grey,
              qtPromocoes == 0
                  ? 'Sem ofertas'
                  : qtPromocoes == 1
                  ? '1 oferta'
                  : '$qtPromocoes ofertas',
            ),
            if (distancia != null) ...[
              const SizedBox(height: 4),
              _buildLinhaInfo(
                Icons.location_on,
                Colors.grey.shade600,
                LocalizacaoService.formatar(distancia),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLinhaInfo(IconData icone, Color cor, String texto) {
    return Row(
      children: [
        Icon(icone, color: cor, size: icone == Icons.circle ? 10 : 15),
        SizedBox(width: icone == Icons.circle ? 7 : 5),
        Expanded(
          child: Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildGrupoProduto(Map<String, dynamic> produto) {
    final mercados = _listaDeMapas(produto['mercados']);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (produto['ds_item_produto'] ?? produto['nm_produto'] ?? '')
                .toString(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            '${produto['nm_marca'] ?? ''} • ${produto['ds_categoria'] ?? ''}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          if (mercados.isEmpty)
            Text(
              'Nenhum mercado possui este produto cadastrado.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            )
          else
            ...mercados.map(_buildLinhaMercadoProduto),
        ],
      ),
    );
  }

  Widget _buildLinhaMercadoProduto(Map<String, dynamic> item) {
    final disponivel = _toBool(item['fl_disponivel']);
    final promocao = _toBool(item['fl_promocao']);
    final melhorPreco = _toBool(item['melhor_preco']);

    final distancia = LocalizacaoService.distanciaMetros(
      _posicao,
      _numero(item['nu_latitude']),
      _numero(item['nu_longitude']),
    );

    final corTexto = disponivel ? Colors.black87 : Colors.grey;

    return GestureDetector(
      onTap: () => _abrirMercado(_toInt(item['id_mercado'])),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: melhorPreco ? Colors.green.shade50 : Colors.white,
          border: Border.all(
            color: melhorPreco ? Colors.green.shade400 : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (item['nm_mercado'] ?? '').toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: corTexto,
                    ),
                  ),
                  if (melhorPreco || promocao || !disponivel) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        if (melhorPreco)
                          _buildSelo(
                            Icons.trending_down,
                            'Melhor preço',
                            Colors.green.shade700,
                          ),
                        if (promocao && disponivel)
                          _buildSelo(Icons.local_offer, 'Promoção', Colors.red),
                        if (!disponivel)
                          _buildSelo(Icons.block, 'Indisponível', Colors.grey),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatarValor(item['nu_valor_final'] ?? item['nu_valor']),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: disponivel ? Colors.red : Colors.grey,
                  ),
                ),
                if (distancia != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    LocalizacaoService.formatar(distancia),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelo(IconData icone, String texto, Color cor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 14, color: cor),
        const SizedBox(width: 3),
        Text(
          texto,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cor,
          ),
        ),
      ],
    );
  }

  String _formatarValor(dynamic valor) {
    final numero = _numero(valor);
    return 'R\$ ${numero.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatarNota(dynamic valor) {
    return _numero(valor).toStringAsFixed(1).replaceAll('.', ',');
  }

  double _numero(dynamic valor) {
    return double.tryParse(valor.toString().replaceAll(',', '.')) ?? 0;
  }

  int _toInt(dynamic valor) => int.tryParse(valor.toString()) ?? 0;

  bool _toBool(dynamic valor) {
    if (valor is bool) return valor;
    return valor.toString().toLowerCase() == 'true' || valor.toString() == '1';
  }
}
