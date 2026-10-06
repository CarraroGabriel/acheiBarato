import 'package:flutter/material.dart';
import 'package:achei_barato/services/api_service.dart';
import 'package:achei_barato/services/localizacao_service.dart';
import 'package:achei_barato/telas/perfil_mercado.dart';
import 'package:achei_barato/widgets/app_bar.dart';
import 'package:achei_barato/widgets/imagem_app.dart';
import 'package:achei_barato/widgets/tempo_promocao.dart';

class ProdutoTela extends StatefulWidget {
  final int idItemProduto;
  final int? idUsuario; // necessário para favoritar

  const ProdutoTela({super.key, required this.idItemProduto, this.idUsuario});

  @override
  State<ProdutoTela> createState() => _ProdutoTelaState();
}

class _ProdutoTelaState extends State<ProdutoTela> {
  Map<String, dynamic>? _item;
  List<Map<String, dynamic>> _mercados = [];
  bool _carregando = true;
  String? _erro;
  bool _naoEncontrado = false;

  bool _favorito = false;
  bool _alternandoFavorito = false;

  PosicaoUsuario? _posicao;
  bool _localizacaoVerificada = false;

  bool get _podeFavoritar => widget.idUsuario != null;

  @override
  void initState() {
    super.initState();
    _carregar();
    _carregarFavorito();
    _obterLocalizacao();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
      _naoEncontrado = false;
    });

    try {
      final resposta = await ApiService.get(
        'produtos/item/${widget.idItemProduto}',
      );
      final dados = Map<String, dynamic>.from(resposta['dados'] as Map);

      if (!mounted) return;

      setState(() {
        _item = Map<String, dynamic>.from(dados['item'] as Map);
        _mercados = _listaDeMapas(dados['mercados']);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.statusCode == 404) {
          _naoEncontrado = true;
        } else {
          _erro = e.mensagem;
        }
      });
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
        'produto_favorito?id_usuario=${widget.idUsuario}'
        '&id_item_produto=${widget.idItemProduto}',
      );
      if (mounted) setState(() => _favorito = r['dados']['favorito'] == true);
    } catch (_) {}
  }

  Future<void> _alternarFavorito() async {
    if (!_podeFavoritar) {
      _mostrarMensagem('Entre com sua conta para favoritar produtos.');
      return;
    }
    if (_alternandoFavorito) return;

    setState(() => _alternandoFavorito = true);

    try {
      if (_favorito) {
        await ApiService.delete(
          'produto_favorito?id_usuario=${widget.idUsuario}'
          '&id_item_produto=${widget.idItemProduto}',
        );
      } else {
        await ApiService.post('produto_favorito', {
          'id_usuario': widget.idUsuario,
          'id_item_produto': widget.idItemProduto,
        });
      }

      if (!mounted) return;
      setState(() => _favorito = !_favorito);
      _mostrarMensagem(
        _favorito
            ? 'Produto adicionado aos favoritos.'
            : 'Produto removido dos favoritos.',
      );
    } on ApiException catch (e) {
      _mostrarMensagem(e.mensagem);
    } catch (_) {
      _mostrarMensagem('Não foi possível conectar ao servidor.');
    } finally {
      if (mounted) setState(() => _alternandoFavorito = false);
    }
  }

  Future<void> _obterLocalizacao() async {
    final posicao = await LocalizacaoService.obterPosicao();
    if (!mounted) return;
    setState(() {
      _posicao = posicao;
      _localizacaoVerificada = true;
    });
  }

  void _abrirMercado(Map<String, dynamic> mercado) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PerfilMercado(
          idMercado: _toInt(mercado['id_mercado']),
          idUsuario: widget.idUsuario,
        ),
      ),
    );
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: const AcheiBaratoAppBar(), body: _buildBody());
  }

  Widget _buildBody() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_naoEncontrado) {
      return _buildMensagem(
        Icons.search_off,
        'Produto não encontrado.',
        acao: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Voltar'),
        ),
      );
    }

    if (_erro != null) {
      return _buildMensagem(
        Icons.error_outline,
        _erro!,
        acao: TextButton(
          onPressed: _carregar,
          child: const Text('Tentar novamente'),
        ),
      );
    }

    final item = _item ?? {};

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildFoto(item),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (item['ds_item_produto'] ?? '').toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        item['nm_marca'],
                        item['nm_categoria'],
                        _formatarMedida(item['nu_medida'], item['sg_unidade']),
                      ].where((t) => t != null && '$t'.isNotEmpty).join(' · '),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildBotaoFavorito(),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Mercados que vendem este produto',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (_localizacaoVerificada && _posicao == null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.location_off,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Ative a localização para ver a distância dos mercados.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _obterLocalizacao,
                    child: const Text('Ativar'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (_mercados.isEmpty)
            _buildMensagem(
              Icons.storefront,
              'Nenhum mercado possui este produto disponível no momento.',
            )
          else
            ..._mercados.map(_buildCardMercado),
        ],
      ),
    );
  }

  Widget _buildBotaoFavorito() {
    return OutlinedButton.icon(
      onPressed: _alternandoFavorito ? null : _alternarFavorito,
      icon: _alternandoFavorito
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              _favorito ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
              size: 20,
            ),
      label: Text(
        _favorito ? 'Favoritado' : 'Favoritar',
        style: const TextStyle(color: Colors.red),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.red),
        backgroundColor: _favorito ? Colors.red.shade50 : null,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  Widget _buildFoto(Map<String, dynamic> item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: Colors.grey.shade200,
          child: ImagemApp.produto(item, tamanhoIcone: 64, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildCardMercado(Map<String, dynamic> mercado) {
    final melhorPreco = _toBool(mercado['melhor_preco']);
    final promocao = _toBool(mercado['fl_promocao']);
    final temMotoboy = _toBool(mercado['fl_motoboy']);
    final desconto = _toInt(mercado['nu_desconto']);
    final distancia = LocalizacaoService.distanciaMetros(
      _posicao,
      _toDouble(mercado['nu_latitude']),
      _toDouble(mercado['nu_longitude']),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: melhorPreco ? Colors.green.shade400 : Colors.grey.shade300,
          width: melhorPreco ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _abrirMercado(mercado),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      (mercado['nm_mercado'] ?? '').toString(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (melhorPreco)
                    _buildSelo('MELHOR PREÇO', Colors.green.shade700),
                ],
              ),
              if (distancia != null) ...[
                const SizedBox(height: 6),
                _buildLinhaInfo(
                  Icons.location_on,
                  LocalizacaoService.formatar(distancia),
                  Colors.grey.shade700,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatarValor(mercado['nu_valor_final']),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (promocao && desconto > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        _formatarValor(mercado['nu_valor']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (promocao)
                    _buildSelo(
                      desconto > 0 ? 'PROMOÇÃO -$desconto%' : 'PROMOÇÃO',
                      Colors.red,
                    ),
                ],
              ),
              if (promocao)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: TempoPromocao(
                    segundosRestantes: mercado['nu_segundos_restantes'],
                  ),
                ),
              const SizedBox(height: 8),
              _buildLinhaInfo(
                Icons.delivery_dining,
                temMotoboy
                    ? _textoTaxaEntrega(mercado['nu_taxa_entrega'])
                    : 'Sem tele-entrega',
                temMotoboy ? Colors.green.shade700 : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelo(String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cor.withValues(alpha: 0.4)),
      ),
      child: Text(
        texto,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cor),
      ),
    );
  }

  Widget _buildLinhaInfo(IconData icone, String texto, Color cor) {
    return Row(
      children: [
        Icon(icone, size: 16, color: cor),
        const SizedBox(width: 4),
        Text(texto, style: TextStyle(fontSize: 13, color: cor)),
      ],
    );
  }

  Widget _buildMensagem(IconData icone, String texto, {Widget? acao}) {
    return Padding(
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
    );
  }

  String _textoTaxaEntrega(dynamic taxa) {
    final valor = _toDouble(taxa);
    return valor <= 0
        ? 'Tele-entrega grátis'
        : 'Tele-entrega: ${_formatarValor(valor)}';
  }

  String? _formatarMedida(dynamic medida, dynamic unidade) {
    final numero = double.tryParse('$medida');
    if (numero == null || unidade == null) return null;
    final texto = numero == numero.roundToDouble()
        ? numero.toStringAsFixed(0)
        : numero.toString().replaceAll('.', ',');
    return '$texto $unidade';
  }

  List<Map<String, dynamic>> _listaDeMapas(dynamic dados) {
    if (dados is! List) return [];
    return dados
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _formatarValor(dynamic valor) {
    final numero = _toDouble(valor);
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
