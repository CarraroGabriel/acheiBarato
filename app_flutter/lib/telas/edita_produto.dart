import 'package:flutter/material.dart';
import 'package:achei_barato/widgets/app_bar.dart';
import 'package:achei_barato/widgets/botao_primario.dart';

class EdicaoProduto extends StatefulWidget {
  const EdicaoProduto({super.key});

  @override
  State<EdicaoProduto> createState() => _EdicaoProdutoState();
}

class _EdicaoProdutoState extends State<EdicaoProduto> {
  bool _emPromocao = false;    // fl_promocao
  bool _disponivel = true;     // fl_disponivel
  int? _descontoSelecionado;

  final List<int> _descontos = [5, 10, 15, 20, 25, 30, 40, 50];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AcheiBaratoAppBar(),
      body: SingleChildScrollView(
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

              const SizedBox(height: 20),

              // ── AÇÕES RÁPIDAS no topo ──────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _disponivel = !_disponivel),
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
                              color: _disponivel
                                  ? Colors.green
                                  : Colors.grey,
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
                              color: _emPromocao
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _emPromocao ? 'Em Promoção' : 'Sem Promoção',
                              style: TextStyle(
                                fontSize: 12,
                                color: _emPromocao
                                    ? Colors.red
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

              // nu_valor
              const TextField(
                keyboardType:
                TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Novo Valor (R\$)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monetization_on),
                ),
              ),

              const SizedBox(height: 12),

              const TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantidade em Estoque',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
              ),

              // Percentual de desconto — só visível com fl_promocao = true
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
                          final sel = _descontoSelecionado == d;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _descontoSelecionado = d),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color:
                                sel ? Colors.red : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: sel
                                      ? Colors.red
                                      : Colors.red.shade200,
                                ),
                              ),
                              child: Text(
                                '$d%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: sel
                                      ? Colors.white
                                      : Colors.red,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (_descontoSelecionado != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Desconto de $_descontoSelecionado% será aplicado sobre o valor cadastrado',
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

              BotaoPrimario(
                texto: 'Salvar Alterações',
                onPressed: () {},
              ),
            ],
          ),
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
            'Esta ação não pode ser desfeita. O produto será removido do seu catálogo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // futura chamada ao backend PHP
            },
            child: const Text('Excluir',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}