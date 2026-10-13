import 'package:flutter/material.dart';
import 'package:achei_barato/services/api_service.dart';
import 'package:achei_barato/services/notificacao_service.dart';
import 'package:achei_barato/telas/edita_produto.dart';
import 'package:achei_barato/telas/produto.dart';
import 'package:achei_barato/widgets/app_bar.dart';

class NotificacoesTela extends StatefulWidget {
  final int? idUsuario;
  final int? idMercado;

  const NotificacoesTela({super.key, this.idUsuario, this.idMercado});

  @override
  State<NotificacoesTela> createState() => _NotificacoesTelaState();
}

class _NotificacoesTelaState extends State<NotificacoesTela> {
  List<Map<String, dynamic>> _notificacoes = [];
  bool _carregando = true;
  String? _erro;

  String get _filtro => widget.idUsuario != null
      ? 'id_usuario=${widget.idUsuario}'
      : 'id_mercado=${widget.idMercado}';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = _notificacoes.isEmpty;
      _erro = null;
    });

    try {
      final resposta = await ApiService.get('notificacoes?$_filtro');
      final dados = resposta['dados'] as Map;
      final lista = (dados['notificacoes'] as List? ?? [])
          .whereType<Map>()
          .map((n) => Map<String, dynamic>.from(n))
          .toList();

      if (!mounted) return;
      setState(() => _notificacoes = lista);

      if ((dados['nao_lidas'] as num? ?? 0) > 0) {
        await ApiService.put('notificacoes/lidas?$_filtro', {});
      }
      NotificacaoService.naoLidas.value = 0;
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

  Future<void> _excluir(Map<String, dynamic> n) async {
    final posicao = _notificacoes.indexOf(n);
    setState(() => _notificacoes.remove(n));

    try {
      await ApiService.delete('notificacoes/${n['id_notificacao']}?$_filtro');
    } catch (_) {
      if (!mounted) return;
      setState(() => _notificacoes.insert(posicao, n));
      _mostrarMensagem('Não foi possível excluir a notificação.');
    }
  }

  Future<void> _limparTudo() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar notificações'),
        content: const Text('Todas as notificações serão excluídas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;

    try {
      await ApiService.delete('notificacoes?$_filtro');
      if (mounted) setState(() => _notificacoes = []);
    } catch (_) {
      _mostrarMensagem('Não foi possível limpar as notificações.');
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  void _abrir(Map<String, dynamic> n) {
    final Widget? destino;
    if (widget.idUsuario != null && n['id_item_produto'] != null) {
      destino = ProdutoTela(
        idItemProduto: n['id_item_produto'] as int,
        idUsuario: widget.idUsuario,
      );
    } else if (widget.idMercado != null && n['id_produto_mercado'] != null) {
      destino = EdicaoProduto(idProdutoMercado: n['id_produto_mercado'] as int);
    } else {
      destino = null;
    }

    if (destino != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => destino!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AcheiBaratoAppBar(),
      body: RefreshIndicator(onRefresh: _carregar, child: _buildCorpo()),
    );
  }

  Widget _buildCorpo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erro != null || _notificacoes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          Icon(
            _erro == null ? Icons.notifications_none : Icons.cloud_off_outlined,
            size: 56,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            _erro ??
                (widget.idUsuario != null
                    ? 'Nenhuma notificação ainda.\nFavorite mercados e produtos para ser avisado das promoções.'
                    : 'Nenhuma notificação ainda.\nAvisamos aqui quando um produto ficar com estoque baixo ou indisponível.'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _notificacoes.length + 1,
      separatorBuilder: (_, i) =>
          i == 0 ? const SizedBox.shrink() : const Divider(height: 1),
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Notificações',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: _limparTudo,
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Limpar tudo'),
                ),
              ],
            ),
          );
        }
        final n = _notificacoes[i - 1];
        return Dismissible(
          key: ValueKey(n['id_notificacao']),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          onDismissed: (_) => _excluir(n),
          child: _buildItem(n),
        );
      },
    );
  }

  Widget _buildItem(Map<String, dynamic> n) {
    final lida = n['fl_lida'] == true;
    final (icone, cor) = switch (n['tp_notificacao']) {
      'PROMOCAO_PRODUTO_FAVORITO' => (Icons.favorite, Colors.red),
      'PROMOCAO_MERCADO_FAVORITO' => (Icons.local_offer, Colors.red),
      'ESTOQUE_BAIXO' => (Icons.inventory_2_outlined, Colors.orange.shade800),
      'PRODUTO_INDISPONIVEL' => (
        Icons.remove_shopping_cart,
        Colors.grey.shade700,
      ),
      _ => (Icons.notifications, Colors.red),
    };

    return ListTile(
      tileColor: lida ? null : Colors.red.shade50,
      leading: CircleAvatar(
        backgroundColor: cor.withValues(alpha: 0.12),
        child: Icon(icone, color: cor, size: 22),
      ),
      title: Text(
        (n['ds_titulo'] ?? '').toString(),
        style: TextStyle(fontWeight: lida ? FontWeight.w500 : FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text((n['ds_mensagem'] ?? '').toString()),
          const SizedBox(height: 2),
          Text(
            _tempoDecorrido(n['dt_criacao']),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
      trailing: lida
          ? null
          : const Icon(Icons.circle, size: 10, color: Colors.red),
      onTap: () => _abrir(n),
    );
  }

  String _tempoDecorrido(dynamic data) {
    final criada = DateTime.tryParse('$data')?.toLocal();
    if (criada == null) return '';

    final diferenca = DateTime.now().difference(criada);
    if (diferenca.inMinutes < 1) return 'agora';
    if (diferenca.inMinutes < 60) return 'há ${diferenca.inMinutes} min';
    if (diferenca.inHours < 24) return 'há ${diferenca.inHours} h';
    if (diferenca.inDays == 1) return 'ontem';
    if (diferenca.inDays < 7) return 'há ${diferenca.inDays} dias';

    String doisDigitos(int v) => v.toString().padLeft(2, '0');
    return '${doisDigitos(criada.day)}/${doisDigitos(criada.month)}/${criada.year}';
  }
}
