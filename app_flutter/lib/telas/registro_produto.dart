import 'package:flutter/material.dart';
import 'package:achei_barato/Widgets/app_bar.dart';
import 'package:achei_barato/Widgets/botao_primario.dart';

class RegistroProduto extends StatefulWidget {
  const RegistroProduto({super.key});

  @override
  State<RegistroProduto> createState() => _RegistroProdutoState();
}

class _RegistroProdutoState extends State<RegistroProduto> {
  String? _categoriaSelecionada;
  String? _marcaSelecionada;

  final _nomeController = TextEditingController();
  final _valorController = TextEditingController();
  final _qtdeController  = TextEditingController();

  final List<String> _categorias = [
    'Grãos', 'Laticínios', 'Óleos', 'Bebidas',
    'Carnes', 'Higiene', 'Limpeza', 'Padaria', 'Hortifruti', 'Outros',
  ];

  final List<String> _marcas = [
    'Tio João', 'Elegê', 'Liza', 'Nestlé',
    'Forno de Minas', 'Sadia', 'Perdigão', 'Omo', 'Dove', 'Outra',
  ];

  @override
  void dispose() {
    _nomeController.dispose();
    _valorController.dispose();
    _qtdeController.dispose();
    super.dispose();
  }

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
                'Registrar Produto',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              // ── CARD DE PREVIEW ────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
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
                      child: const Icon(Icons.image,
                          color: Colors.grey, size: 30),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Reflete o que o usuário digita em tempo real
                          ValueListenableBuilder(
                            valueListenable: _nomeController,
                            builder: (_, __, ___) => Text(
                              _nomeController.text.isEmpty
                                  ? 'Nome do produto'
                                  : _nomeController.text,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _nomeController.text.isEmpty
                                    ? Colors.grey
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _marcaSelecionada ?? 'Marca',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                          Text(
                            _categoriaSelecionada ?? 'Categoria',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    ValueListenableBuilder(
                      valueListenable: _valorController,
                      builder: (_, __, ___) => Text(
                        _valorController.text.isEmpty
                            ? 'R\$ 0,00'
                            : 'R\$ ${_valorController.text}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              Text(
                'Pré-visualização de como o produto aparecerá',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: _nomeController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Nome do Produto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _categoriaSelecionada,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categorias.map((c) =>
                    DropdownMenuItem(value: c, child: Text(c)),
                ).toList(),
                onChanged: (v) => setState(() => _categoriaSelecionada = v),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _marcaSelecionada,
                decoration: const InputDecoration(
                  labelText: 'Marca',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business_center),
                ),
                items: _marcas.map((m) =>
                    DropdownMenuItem(value: m, child: Text(m)),
                ).toList(),
                onChanged: (v) => setState(() => _marcaSelecionada = v),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _valorController,
                onChanged: (_) => setState(() {}),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Valor (R\$)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monetization_on),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _qtdeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantidade em Estoque',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
              ),

              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_photo_alternate, color: Colors.red),
                label: const Text(
                  'Adicionar Foto',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              BotaoPrimario(
                texto: 'Registrar Produto',
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}