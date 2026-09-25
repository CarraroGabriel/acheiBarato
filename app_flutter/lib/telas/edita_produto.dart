import 'package:flutter/material.dart';
import 'package:achei_barato/services/api_service.dart';
import 'package:achei_barato/widgets/app_bar.dart';
import 'package:achei_barato/widgets/botao_primario.dart';

class EdicaoProduto extends StatefulWidget {
  final int idProdutoMercado;

  const EdicaoProduto({
    super.key,
    required this.idProdutoMercado,
  });

  @override
  State<EdicaoProduto> createState() => _EdicaoProdutoState();
}

class _EdicaoProdutoState extends State<EdicaoProduto> {
  bool _emPromocao = false;
  bool _disponivel = true;
  int? _descontoSelecionado;
  bool _carregando = true;
  bool _salvando = false;
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

  Future<void> _salvar() async {
    final valorDigitado = double.tryParse(
      _valorController.text.replaceAll(',', '.'),
    );
    final quantidade = int.tryParse(_qtdeController.text);

    if (valorDigitado == null || quantidade == null) {
      _mostrarMensagem('Informe um valor e uma quantidade válidos.');
      return;
    }

    var valorFinal = valorDigitado;

    // O ER atual possui fl_promocao e nu_valor, mas não possui uma coluna
    // para guardar o percentual. Por isso o percentual é usado para calcular
    // o preço final, e o backend persiste apenas o preço resultante.
    if (_emPromocao && _descontoSelecionado != null) {
      valorFinal = valorDigitado * (1 - (_descontoSelecionado! / 100));
    }

    setState(() => _salvando = true);

    try {
      await ApiService.put(
        'produto_mercado/${widget.idProdutoMercado}',
        {
          'nu_valor': double.parse(valorFinal.toStringAsFixed(2)),
          'nu_qtde': quantidade,
          'fl_promocao': _emPromocao,
          'fl_disponivel': _disponivel,
        },
      );

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
      await ApiService.delete(
        'produto_mercado/${widget.idProdutoMercado}',
      );

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AcheiBaratoAppBar(),
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
              '${produto['nm_produto'] ?? ''} • ${produto['nm_marca'] ?? ''}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
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
                            _disponivel ? Icons.visibility : Icons.visibility_off,
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
                      if (!_emPromocao) _descontoSelecionado = null;
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
            const SizedBox(height: 20),
            TextField(
              controller: _valorController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                      children: _descontos.map((d) {
                        final selecionado = _descontoSelecionado == d;
                        return GestureDetector(
                          onTap: () => setState(() => _descontoSelecionado = d),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selecionado ? Colors.red : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selecionado
                                    ? Colors.red
                                    : Colors.red.shade200,
                              ),
                            ),
                            child: Text(
                              '$d%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: selecionado ? Colors.white : Colors.red,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (_descontoSelecionado != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'O backend salvará o preço final após aplicar $_descontoSelecionado%. O ER atual não guarda o percentual separadamente.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (_salvando)
              const Center(child: CircularProgressIndicator())
            else
              BotaoPrimario(
                texto: 'Salvar Alterações',
                onPressed: _salvar,
              ),
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

  int _toInt(dynamic valor) => int.tryParse(valor.toString()) ?? 0;

  double _numero(dynamic valor) {
    return double.tryParse(valor.toString().replaceAll(',', '.')) ?? 0;
  }

  bool _toBool(dynamic valor) {
    if (valor is bool) return valor;
    return valor.toString().toLowerCase() == 'true' || valor.toString() == '1';
  }
}
