import 'package:flutter/material.dart';
import 'package:achei_barato/services/api_service.dart';
import 'package:achei_barato/widgets/app_bar.dart';
import 'package:achei_barato/widgets/botao_primario.dart';
import 'package:achei_barato/widgets/imagem_app.dart';
import 'package:achei_barato/widgets/selecionar_imagem.dart';

class EdicaoProduto extends StatefulWidget {
  final int idProdutoMercado;

  const EdicaoProduto({super.key, required this.idProdutoMercado});

  @override
  State<EdicaoProduto> createState() => _EdicaoProdutoState();
}

class _EdicaoProdutoState extends State<EdicaoProduto> {
  bool _emPromocao = false;
  bool _disponivel = true;
  int? _descontoSelecionado;

  DateTime? _fimPromocao;
  String _prazoSelecionado = 'sem_prazo';
  DateTime? _promocaoExpiradaEm;

  bool _carregando = true;
  bool _salvando = false;
  bool _enviandoFoto = false;
  String? _erro;

  final _valorController = TextEditingController();
  final _qtdeController = TextEditingController();
  Map<String, dynamic>? _produto;

  final List<int> _descontos = [5, 10, 15, 20, 25, 30, 40, 50];

  @override
  void initState() {
    super.initState();
    _carregarProduto();
  }

  @override
  void dispose() {
    _valorController.dispose();
    _qtdeController.dispose();
    super.dispose();
  }

  Future<void> _carregarProduto() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resposta = await ApiService.get(
        'produto_mercado/${widget.idProdutoMercado}',
      );
      final produto = Map<String, dynamic>.from(resposta['dados'] as Map);

      if (!mounted) return;

      setState(() {
        _produto = produto;
        _emPromocao = _toBool(produto['fl_promocao']);
        _disponivel = _toBool(produto['fl_disponivel']);
        _valorController.text = _numero(produto['nu_valor']).toStringAsFixed(2);
        _qtdeController.text = _toInt(produto['nu_qtde']).toString();
        final desconto = _toInt(produto['nu_desconto']);
        _descontoSelecionado = desconto > 0 ? desconto : null;

        final fim = DateTime.tryParse(
          (produto['dt_fim_promocao'] ?? '').toString(),
        )?.toLocal();

        if (_emPromocao) {
          _fimPromocao = fim;
          _prazoSelecionado = fim == null ? 'sem_prazo' : 'personalizado';
        } else if (_toBool(produto['fl_promocao_expirada'])) {
          _promocaoExpiradaEm = fim;
        }
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

  Future<void> _alterarFoto() async {
    final arquivo = await SelecionarImagem.escolher(context);
    if (arquivo == null || !mounted) return;

    setState(() => _enviandoFoto = true);

    try {
      final resposta = await ApiService.enviarImagem(
        'produto_mercado/${widget.idProdutoMercado}/foto',
        await arquivo.readAsBytes(),
        nomeArquivo: arquivo.name,
      );

      PaintingBinding.instance.imageCache.clear();

      if (!mounted) return;
      setState(
        () =>
            _produto?['ds_foto_produto'] = resposta['dados']['ds_foto_produto'],
      );
      _mostrarMensagem('Foto do produto atualizada.');
    } on ApiException catch (e) {
      _mostrarMensagem(e.mensagem);
    } catch (_) {
      _mostrarMensagem('Não foi possível enviar a foto.');
    } finally {
      if (mounted) setState(() => _enviandoFoto = false);
    }
  }

  Widget _buildFotoProduto(Map<String, dynamic> produto) {
    final temFotoPropria = (produto['ds_foto_produto'] ?? '')
        .toString()
        .startsWith('uploads/');

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 160,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ImagemApp.produto(
                  produto,
                  tamanhoIcone: 48,
                  fit: BoxFit.contain,
                ),
                if (_enviandoFoto)
                  const ColoredBox(
                    color: Colors.black38,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
        TextButton.icon(
          onPressed: _enviandoFoto ? null : _alterarFoto,
          icon: const Icon(Icons.photo_camera, color: Colors.red),
          label: Text(
            temFotoPropria
                ? 'Trocar foto do produto'
                : 'Enviar foto do produto',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        Text(
          temFotoPropria
              ? 'A foto aparece para este produto em todos os mercados.'
              : 'Sem foto enviada, o app mostra a imagem padrão do produto.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Future<void> _salvar() async {
    final valorDigitado = double.tryParse(
      _valorController.text.replaceAll(',', '.'),
    );
    final quantidade = int.tryParse(_qtdeController.text);

    if (valorDigitado == null || quantidade == null) {
      _mostrarMensagem('Informe um valor e uma quantidade válidos.');
      return;
    }

    if (_emPromocao && _descontoSelecionado == null) {
      _mostrarMensagem('Selecione o percentual de desconto.');
      return;
    }

    if (_emPromocao &&
        _fimPromocao != null &&
        !_fimPromocao!.isAfter(DateTime.now())) {
      _mostrarMensagem('O término da promoção deve ser depois de agora.');
      return;
    }

    setState(() => _salvando = true);

    try {
      await ApiService.put('produto_mercado/${widget.idProdutoMercado}', {
        'nu_valor': double.parse(valorDigitado.toStringAsFixed(2)),
        'nu_qtde': quantidade,
        'fl_promocao': _emPromocao,
        'nu_desconto': _emPromocao ? _descontoSelecionado : 0,
        'dt_fim_promocao': _emPromocao && _fimPromocao != null
            ? _fimPromocao!.toUtc().toIso8601String()
            : null,
        'fl_disponivel': _disponivel,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto alterado com sucesso.')),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      _mostrarMensagem(e.mensagem);
    } catch (_) {
      _mostrarMensagem('Não foi possível conectar ao servidor.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _excluir() async {
    Navigator.pop(context);
    setState(() => _salvando = true);

    try {
      await ApiService.delete('produto_mercado/${widget.idProdutoMercado}');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto removido do mercado.')),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      _mostrarMensagem(e.mensagem);
    } catch (_) {
      _mostrarMensagem('Não foi possível conectar ao servidor.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
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
                onPressed: _carregarProduto,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final produto = _produto ?? {};

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Editar Produto',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              '${produto['ds_item_produto'] ?? produto['nm_produto'] ?? ''} • ${produto['nm_marca'] ?? ''}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            _buildFotoProduto(produto),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _disponivel = !_disponivel),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _disponivel
                            ? Colors.green.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _disponivel
                              ? Colors.green.shade400
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _disponivel
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: _disponivel ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _disponivel ? 'Disponível' : 'Indisponível',
                            style: TextStyle(
                              fontSize: 12,
                              color: _disponivel
                                  ? Colors.green.shade700
                                  : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _emPromocao = !_emPromocao;
                      if (!_emPromocao) {
                        _descontoSelecionado = null;
                        _fimPromocao = null;
                        _prazoSelecionado = 'sem_prazo';
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _emPromocao
                            ? Colors.red.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _emPromocao
                              ? Colors.red.shade300
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.local_offer,
                            color: _emPromocao ? Colors.red : Colors.grey,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _emPromocao ? 'Em Promoção' : 'Sem Promoção',
                            style: TextStyle(
                              fontSize: 12,
                              color: _emPromocao ? Colors.red : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _confirmarExclusao(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(height: 4),
                          Text(
                            'Excluir',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_promocaoExpiradaEm != null && !_emPromocao) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  'A promoção deste produto terminou em '
                  '${_formatarDataHora(_promocaoExpiradaEm!)}. '
                  'Toque em "Sem Promoção" para criar uma nova.',
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                ),
              ),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _valorController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Valor / Valor base (R\$)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _qtdeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantidade em Estoque',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
            ),
            if (_emPromocao) ...[
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.red.shade50,
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.percent, color: Colors.red, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Percentual de Desconto',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _descontos
                          .map(
                            (d) => _buildOpcao(
                              '$d%',
                              _descontoSelecionado == d,
                              () => setState(() => _descontoSelecionado = d),
                            ),
                          )
                          .toList(),
                    ),
                    if (_descontoSelecionado != null) ...[
                      const SizedBox(height: 10),
                      Builder(
                        builder: (_) {
                          final base =
                              double.tryParse(
                                _valorController.text.replaceAll(',', '.'),
                              ) ??
                              0;
                          final valorFinal =
                              base * (1 - _descontoSelecionado! / 100);
                          return Text(
                            'Preço final: R\$ ${valorFinal.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Row(
                      children: [
                        Icon(Icons.timer_outlined, color: Colors.red, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Duração da Promoção',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildOpcao(
                          'Até o fim do dia',
                          _prazoSelecionado == 'fim_dia',
                          () => _definirPrazo('fim_dia', _fimDoDia()),
                        ),
                        _buildOpcao(
                          '3 horas',
                          _prazoSelecionado == '3h',
                          () => _definirPrazo(
                            '3h',
                            DateTime.now().add(const Duration(hours: 3)),
                          ),
                        ),
                        _buildOpcao(
                          '24 horas',
                          _prazoSelecionado == '24h',
                          () => _definirPrazo(
                            '24h',
                            DateTime.now().add(const Duration(hours: 24)),
                          ),
                        ),
                        _buildOpcao(
                          '7 dias',
                          _prazoSelecionado == '7d',
                          () => _definirPrazo(
                            '7d',
                            DateTime.now().add(const Duration(days: 7)),
                          ),
                        ),
                        _buildOpcao(
                          'Escolher data e hora',
                          _prazoSelecionado == 'personalizado',
                          _escolherDataHora,
                        ),
                        _buildOpcao(
                          'Sem prazo',
                          _prazoSelecionado == 'sem_prazo',
                          () => _definirPrazo('sem_prazo', null),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _fimPromocao == null
                          ? 'A promoção fica ativa até você desligá-la.'
                          : 'Termina em ${_formatarDataHora(_fimPromocao!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (_salvando)
              const Center(child: CircularProgressIndicator())
            else
              BotaoPrimario(texto: 'Salvar Alterações', onPressed: _salvar),
          ],
        ),
      ),
    );
  }

  void _confirmarExclusao(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir produto?'),
        content: const Text(
          'Esta ação remove o produto do catálogo deste mercado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: _excluir,
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _definirPrazo(String opcao, DateTime? fim) {
    setState(() {
      _prazoSelecionado = opcao;
      _fimPromocao = fim;
    });
  }

  DateTime _fimDoDia() {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day, 23, 59);
    return hoje.isAfter(agora) ? hoje : hoje.add(const Duration(days: 1));
  }

  Future<void> _escolherDataHora() async {
    final agora = DateTime.now();
    final inicial = _fimPromocao ?? agora.add(const Duration(hours: 1));

    final data = await showDatePicker(
      context: context,
      initialDate: inicial.isBefore(agora) ? agora : inicial,
      firstDate: DateTime(agora.year, agora.month, agora.day),
      lastDate: agora.add(const Duration(days: 365)),
      helpText: 'Último dia da promoção',
    );
    if (data == null || !mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(inicial),
      helpText: 'Horário de término',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (hora == null) return;

    final fim = DateTime(
      data.year,
      data.month,
      data.day,
      hora.hour,
      hora.minute,
    );

    if (!fim.isAfter(DateTime.now())) {
      _mostrarMensagem('Escolha um horário depois de agora.');
      return;
    }

    _definirPrazo('personalizado', fim);
  }

  String _formatarDataHora(DateTime data) {
    String doisDigitos(int n) => n.toString().padLeft(2, '0');
    return '${doisDigitos(data.day)}/${doisDigitos(data.month)} '
        'às ${doisDigitos(data.hour)}:${doisDigitos(data.minute)}';
  }

  Widget _buildOpcao(String texto, bool selecionado, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selecionado ? Colors.red : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selecionado ? Colors.red : Colors.red.shade200,
          ),
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: selecionado ? Colors.white : Colors.red,
          ),
        ),
      ),
    );
  }

  int _toInt(dynamic valor) => int.tryParse(valor.toString()) ?? 0;

  double _numero(dynamic valor) {
    return double.tryParse(valor.toString().replaceAll(',', '.')) ?? 0;
  }

  bool _toBool(dynamic valor) {
    if (valor is bool) return valor;
    return valor.toString().toLowerCase() == 'true' || valor.toString() == '1';
  }
}
