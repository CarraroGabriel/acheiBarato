import 'package:flutter/material.dart';
import 'package:achei_barato/services/api_service.dart';
import 'package:achei_barato/telas/edita_produto.dart';
import 'package:achei_barato/telas/login.dart';
import 'package:achei_barato/telas/registro_produto.dart';
import 'package:achei_barato/widgets/app_bar.dart';

class PerfilMercado extends StatefulWidget {
  final int idMercado;
  final int? idUsuario;
  final bool modoLojista;

  const PerfilMercado({
    super.key,
    required this.idMercado,
    this.idUsuario,
    this.modoLojista = false,
  });

  @override
  State<PerfilMercado> createState() => _PerfilMercadoState();
}

class _PerfilMercadoState extends State<PerfilMercado> {
  bool _carregando = true;
  String? _erro;
  Map<String, dynamic>? _mercado;
  List<Map<String, dynamic>> _produtos = [];
  bool _favorito = false;
  bool _alternandoFavorito = false;
  bool get _podeFavoritar => !widget.modoLojista && widget.idUsuario != null;

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _carregarFavorito();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final rotaProdutos = widget.modoLojista
          ? 'produto_mercado?mercado=${widget.idMercado}'
          : 'mercados/${widget.idMercado}/promocoes';

      final resultados = await Future.wait([
        ApiService.get('mercados/${widget.idMercado}'),
        ApiService.get(rotaProdutos),
      ]);

      if (!mounted) return;

      setState(() {
        _mercado = Map<String, dynamic>.from(resultados[0]['dados'] as Map);
        _produtos = _listaDeMapas(resultados[1]['dados']);
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

  Future<void> _carregarFavorito() async {
    if (!_podeFavoritar) return;
    try {
      final r = await ApiService.get(
        'mercado_favorito?id_usuario=${widget.idUsuario}&id_mercado=${widget.idMercado}',
      );
      if (mounted) setState(() => _favorito = r['dados']['favorito'] == true);
    } catch (_) {}
  }

  Future<void> _alternarFavorito() async {
    if (_alternandoFavorito) return;
    setState(() => _alternandoFavorito = true);
    try {
      if (_favorito) {
        await ApiService.delete(
          'mercado_favorito?id_usuario=${widget.idUsuario}&id_mercado=${widget.idMercado}',
        );
      } else {
        await ApiService.post('mercado_favorito', {
          'id_usuario': widget.idUsuario,
          'id_mercado': widget.idMercado,
        });
      }
      if (mounted) setState(() => _favorito = !_favorito);
    } on ApiException catch (e) {
      _mostrarMensagem(e.mensagem);
    } catch (_) {
      _mostrarMensagem('Não foi possível conectar ao servidor.');
    } finally {
      if (mounted) setState(() => _alternandoFavorito = false);
    }
  }

  void _mostrarMensagem(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
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
        exibirBotaoVoltar: !widget.modoLojista,
        acoes: widget.modoLojista
            ? [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const Login(isUsuario: false),
                      ),
                      (_) => false,
                    );
                  },
                ),
              ]
            : const [],
      ),
      floatingActionButton: widget.modoLojista
          ? FloatingActionButton.extended(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              onPressed: () async {
                final alterou = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RegistroProduto(idMercado: widget.idMercado),
                  ),
                );

                if (alterou == true) _carregarDados();
              },
              icon: const Icon(Icons.add),
              label: const Text('Produto'),
            )
          : null,
      body: _buildBody(),
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
              Text(_erro!),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _carregarDados,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final mercado = _mercado ?? {};
    final foto = (mercado['ds_foto_mercado'] ?? '').toString();
    final temMotoboy = _toBool(mercado['fl_motoboy']);

    return RefreshIndicator(
      onRefresh: _carregarDados,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Container(height: 130, color: Colors.red),
                Positioned(
                  bottom: -50,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: foto.isNotEmpty
                          ? NetworkImage(foto)
                          : null,
                      child: foto.isEmpty
                          ? const Icon(
                              Icons.store,
                              size: 50,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      (mercado['nm_mercado'] ?? 'Mercado').toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_podeFavoritar)
                    IconButton(
                      onPressed: _alternarFavorito,
                      icon: Icon(
                        _favorito ? Icons.favorite : Icons.favorite_border,
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChip(
                    icon: Icons.star,
                    iconColor: Colors.amber,
                    label:
                        '${_formatarNota(mercado['nu_avg_nota'])}  •  ${_toInt(mercado['nul_avaliacoes'])} avaliações',
                    bgColor: Colors.amber.shade50,
                  ),
                  _buildChip(
                    icon: Icons.delivery_dining,
                    iconColor: temMotoboy
                        ? Colors.green.shade600
                        : Colors.grey.shade600,
                    label: temMotoboy
                        ? 'Tele-entrega disponível'
                        : 'Sem tele-entrega',
                    bgColor: temMotoboy
                        ? Colors.green.shade50
                        : Colors.grey.shade100,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${mercado['nm_endereco'] ?? ''}\nCEP ${mercado['nu_cep'] ?? ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.modoLojista
                            ? Icons.inventory_2
                            : Icons.local_offer,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.modoLojista
                            ? 'Produtos do Mercado'
                            : 'Produtos em Promoção',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_produtos.isEmpty)
                    Text(
                      widget.modoLojista
                          ? 'Nenhum produto cadastrado ainda.'
                          : 'Nenhuma promoção disponível no momento.',
                    )
                  else
                    ..._produtos.map(_buildCardProduto),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCardProduto(Map<String, dynamic> produto) {
    final conteudo = Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
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
                  (produto['ds_item_produto'] ?? produto['nm_produto'] ?? '')
                      .toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${produto['nm_marca'] ?? ''} • ${produto['ds_categoria'] ?? ''}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (widget.modoLojista) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Estoque: ${produto['nu_qtde'] ?? 0} • ${_toBool(produto['fl_disponivel']) ? 'Disponível' : 'Indisponível'}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_toBool(produto['fl_promocao']))
                const Text(
                  'PROMO',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Text(
                _formatarValor(
                  produto['nu_valor_final'] ?? produto['nu_valor'],
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              if (widget.modoLojista &&
                  _toBool(produto['fl_promocao']) &&
                  _toInt(produto['nu_desconto']) > 0)
                Text(
                  'Base: ${_formatarValor(produto['nu_valor'])} • -${_toInt(produto['nu_desconto'])}%',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
            ],
          ),
        ],
      ),
    );

    if (!widget.modoLojista) return conteudo;

    return GestureDetector(
      onTap: () async {
        final alterou = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => EdicaoProduto(
              idProdutoMercado: _toInt(produto['id_produto_mercado']),
            ),
          ),
        );

        if (alterou == true) _carregarDados();
      },
      child: conteudo,
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
