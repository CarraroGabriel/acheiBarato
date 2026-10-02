import 'package:flutter/material.dart';
import 'package:achei_barato/services/api_service.dart';
import 'package:achei_barato/telas/login.dart';
import 'package:achei_barato/widgets/app_bar.dart';
import 'package:achei_barato/widgets/botao_excluir_conta.dart';
import 'package:achei_barato/widgets/botao_primario.dart';
import 'package:achei_barato/widgets/editor_horarios.dart';
import 'package:achei_barato/widgets/foto_perfil.dart';

class EditarMercado extends StatefulWidget {
  final int idMercado;

  const EditarMercado({super.key, required this.idMercado});

  @override
  State<EditarMercado> createState() => _EditarMercadoState();
}

class _EditarMercadoState extends State<EditarMercado> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _cepController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _taxaController = TextEditingController();

  bool _temMotoboy = false;
  String? _fotoUrl;

  // Dia da semana (0 = domingo) -> faixas de funcionamento. Dia sem faixas = fechado.
  Map<int, List<FaixaHorario>> _horarios = {};
  bool _carregando = true;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarMercado();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _cepController.dispose();
    _enderecoController.dispose();
    _taxaController.dispose();
    super.dispose();
  }

  Future<void> _carregarMercado() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resposta = await ApiService.get('mercados/${widget.idMercado}');
      final mercado = Map<String, dynamic>.from(resposta['dados'] as Map);

      if (!mounted) return;

      setState(() {
        _nomeController.text = (mercado['nm_mercado'] ?? '').toString();
        _emailController.text = (mercado['ds_email'] ?? '').toString();
        _cepController.text = (mercado['nu_cep'] ?? '').toString().padLeft(
          8,
          '0',
        );
        _enderecoController.text = (mercado['nm_endereco'] ?? '').toString();
        _temMotoboy = _toBool(mercado['fl_motoboy']);
        final taxa = double.tryParse(
          (mercado['nu_taxa_entrega'] ?? '').toString(),
        );
        _taxaController.text = taxa == null
            ? ''
            : taxa.toStringAsFixed(2).replaceAll('.', ',');
        _fotoUrl = (mercado['ds_foto_mercado'] ?? '').toString();
        _horarios = EditorHorarios.lerDaApi(mercado['horarios']);
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
    final nome = _nomeController.text.trim();

    if (nome.isEmpty ||
        _emailController.text.trim().isEmpty ||
        _cepController.text.trim().isEmpty ||
        _enderecoController.text.trim().isEmpty) {
      _mostrarMensagem('Preencha todos os campos.');
      return;
    }

    final taxa = double.tryParse(
      _taxaController.text.trim().replaceAll(',', '.'),
    );
    if (_temMotoboy && (taxa == null || taxa < 0)) {
      _mostrarMensagem(
        'Informe a taxa de entrega (use 0 para entrega grátis).',
      );
      return;
    }

    final erroHorarios = EditorHorarios.validar(_horarios);
    if (erroHorarios != null) {
      _mostrarMensagem(erroHorarios);
      return;
    }

    setState(() => _salvando = true);

    try {
      await ApiService.put('mercados/${widget.idMercado}/perfil', {
        'nm_mercado': nome,
        'ds_email': _emailController.text.trim(),
        'nu_cep': _cepController.text.trim(),
        'nm_endereco': _enderecoController.text.trim(),
        'fl_motoboy': _temMotoboy,
        'nu_taxa_entrega': _temMotoboy ? taxa : 0,
        'horarios': EditorHorarios.paraApi(_horarios),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso.')),
      );
      Navigator.pop(context, nome);
    } on ApiException catch (e) {
      _mostrarMensagem(e.mensagem);
    } catch (_) {
      _mostrarMensagem('Não foi possível conectar ao servidor.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _excluirConta() async {
    setState(() => _salvando = true);

    try {
      await ApiService.delete('mercados/${widget.idMercado}');

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Conta excluída.')));
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Login(isUsuario: false)),
        (_) => false,
      );
    } on ApiException catch (e) {
      _mostrarMensagem(e.mensagem);
      if (mounted) setState(() => _salvando = false);
    } catch (_) {
      _mostrarMensagem('Não foi possível conectar ao servidor.');
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
                onPressed: _carregarMercado,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Perfil do Mercado',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            FotoPerfil(urlAtual: _fotoUrl, iconePadrao: Icons.store),
            const SizedBox(height: 16),
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do Mercado',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cepController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'CEP',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _enderecoController,
              decoration: const InputDecoration(
                labelText: 'Endereço',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.map),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _temMotoboy,
              onChanged: (valor) => setState(() => _temMotoboy = valor),
              activeThumbColor: Colors.green,
              secondary: Icon(
                Icons.delivery_dining,
                color: _temMotoboy ? Colors.green : Colors.grey,
              ),
              title: const Text('Tele-entrega (motoboy)'),
            ),
            if (_temMotoboy) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _taxaController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Taxa de entrega (R\$)',
                  helperText: 'Use 0 para entrega grátis.',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monetization_on),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.schedule, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Text(
                  'Horário de funcionamento',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            EditorHorarios(
              horarios: _horarios,
              onAlterado: () => setState(() {}),
            ),
            const SizedBox(height: 16),
            if (_salvando)
              const Center(child: CircularProgressIndicator())
            else ...[
              BotaoPrimario(texto: 'Salvar Alterações', onPressed: _salvar),
              const SizedBox(height: 32),
              BotaoExcluirConta(
                mensagem:
                    'O mercado, todos os produtos cadastrados nele, os horários '
                    'e as avaliações serão removidos. Esta ação não pode ser desfeita.',
                onConfirmar: _excluirConta,
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _toBool(dynamic valor) {
    if (valor is bool) return valor;
    return valor.toString().toLowerCase() == 'true' || valor.toString() == '1';
  }
}
