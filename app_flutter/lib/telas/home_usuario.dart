import 'package:flutter/material.dart';
import 'package:achei_barato/services/api_service.dart';
import 'package:achei_barato/telas/perfil_mercado.dart';
import 'package:achei_barato/widgets/app_bar.dart';
import 'package:achei_barato/widgets/bottomnav_usuarios.dart';
import 'package:achei_barato/widgets/editor_horarios.dart';
import 'package:achei_barato/widgets/imagem_app.dart';
import 'package:achei_barato/widgets/menu_lateral.dart';
import 'package:achei_barato/widgets/tempo_promocao.dart';

class HomeUsuario extends StatefulWidget {
  final int idUsuario;
  final String nomeUsuario;

  const HomeUsuario({
    super.key,
    required this.idUsuario,
    required this.nomeUsuario,
  });

  @override
  State<HomeUsuario> createState() => _HomeUsuarioState();
}

class _HomeUsuarioState extends State<HomeUsuario> {
  late String _nomeUsuario = widget.nomeUsuario;
  bool _carregando = true;
  String? _erro;
  List<Map<String, dynamic>> _mercados = [];
  List<Map<String, dynamic>> _produtosDestaque = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resultados = await Future.wait([
        ApiService.get('mercados'),
        ApiService.get('promocoes?id_usuario=${widget.idUsuario}'),
      ]);

      if (!mounted) return;

      setState(() {
        _mercados = _listaDeMapas(resultados[0]['dados']);
        _produtosDestaque = _listaDeMapas(resultados[1]['dados']);
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

  List<Map<String, dynamic>> _listaDeMapas(dynamic dados) {
    if (dados is! List) return [];
    return dados
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
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
      body: RefreshIndicator(
        onRefresh: _carregarDados,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: Colors.red.shade50,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 20),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Localização do usuário — integração GPS pendente',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'Alterar',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 260,
                color: Colors.grey.shade300,
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.map,
                            size: 48,
                            color: Colors.grey.shade500,
                          ),
                          Text(
                            'Mapa será integrado na etapa de geolocalização',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    const Center(
                      child: Icon(
                        Icons.my_location,
                        color: Colors.red,
                        size: 34,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_carregando)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_erro != null)
                _buildErro()
              else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mercados',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_mercados.isEmpty)
                        const Text('Nenhum mercado cadastrado.')
                      else
                        SizedBox(
                          height: 160,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _mercados.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (_, i) =>
                                _buildCardMercado(_mercados[i]),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.local_offer, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Promoções em Destaque',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_produtosDestaque.isEmpty)
                        const Text('Nenhuma promoção disponível no momento.')
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 0.82,
                              ),
                          itemCount: _produtosDestaque.length,
                          itemBuilder: (_, i) =>
                              _buildCardProduto(_produtosDestaque[i]),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavUsuarios(
        indiceAtual: 0,
        idUsuario: widget.idUsuario,
        nomeUsuario: _nomeUsuario,
      ),
    );
  }

  Widget _buildErro() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(_erro ?? 'Erro ao carregar dados.'),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _carregarDados,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildSituacaoMercado(Map<String, dynamic> mercado) {
    final aberto = EditorHorarios.estaAberto(
      EditorHorarios.lerDaApi(mercado['horarios']),
    );

    final (texto, cor) = switch (aberto) {
      true => ('Aberto', Colors.green.shade700),
      false => ('Fechado', Colors.red.shade700),
      null => ('Horário não informado', Colors.grey.shade500),
    };

    return Row(
      children: [
        Icon(Icons.circle, size: 8, color: cor),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: cor,
              fontWeight: aberto == null ? FontWeight.normal : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardMercado(Map<String, dynamic> mercado) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PerfilMercado(
              idMercado: _toInt(mercado['id_mercado']),
              idUsuario: widget.idUsuario,
            ),
          ),
        );
        _carregarDados();
      },
      child: Container(
        width: 160,
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
                _buildLogoMercado(mercado),
                const Spacer(),
                if (_toBool(mercado['fl_motoboy']))
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delivery_dining,
                      color: Colors.green.shade600,
                      size: 16,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              (mercado['nm_mercado'] ?? '').toString(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            _buildSituacaoMercado(mercado),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 13),
                const SizedBox(width: 3),
                Text(
                  _formatarNota(mercado['nu_avg_nota']),
                  style: const TextStyle(fontSize: 11),
                ),
                const SizedBox(width: 8),
                Icon(Icons.location_on, color: Colors.grey.shade400, size: 13),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    'distância pendente',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoMercado(Map<String, dynamic> mercado) {
    return SizedBox(
      width: 44,
      height: 44,
      child: ClipOval(
        child: ImagemApp(
          caminhos: [mercado['ds_foto_mercado']],
          iconePadrao: Icons.store,
          tamanhoIcone: 22,
        ),
      ),
    );
  }

  Widget _buildCardProduto(Map<String, dynamic> produto) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ImagemApp.produto(produto, tamanhoIcone: 36),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'PROMO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
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
            (produto['nm_mercado'] ?? '').toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 4),
          Text(
            _formatarValor(produto['nu_valor_final'] ?? produto['nu_valor']),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          TempoPromocao(segundosRestantes: produto['nu_segundos_restantes']),
        ],
      ),
    );
  }

  String _formatarValor(dynamic valor) {
    final numero = double.tryParse(valor.toString().replaceAll(',', '.')) ?? 0;
    return 'R\$ ${numero.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatarNota(dynamic valor) {
    final numero = double.tryParse(valor.toString().replaceAll(',', '.')) ?? 0;
    return numero.toStringAsFixed(1);
  }

  int _toInt(dynamic valor) => int.tryParse(valor.toString()) ?? 0;

  bool _toBool(dynamic valor) {
    if (valor is bool) return valor;
    return valor.toString().toLowerCase() == 'true' || valor.toString() == '1';
  }
}
