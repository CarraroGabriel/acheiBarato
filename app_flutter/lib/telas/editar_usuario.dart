import 'package:flutter/material.dart';
import 'package:achei_barato/services/api_service.dart';
import 'package:achei_barato/telas/login.dart';
import 'package:achei_barato/widgets/app_bar.dart';
import 'package:achei_barato/widgets/botao_excluir_conta.dart';
import 'package:achei_barato/widgets/botao_primario.dart';

class EditarUsuario extends StatefulWidget {
  final int idUsuario;

  const EditarUsuario({super.key, required this.idUsuario});

  @override
  State<EditarUsuario> createState() => _EditarUsuarioState();
}

class _EditarUsuarioState extends State<EditarUsuario> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();

  bool _carregando = true;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarUsuario();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _carregarUsuario() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resposta = await ApiService.get('usuarios/${widget.idUsuario}');
      final usuario = Map<String, dynamic>.from(resposta['dados'] as Map);

      if (!mounted) return;

      setState(() {
        _nomeController.text = (usuario['nm_usuario'] ?? '').toString();
        _emailController.text = (usuario['ds_email'] ?? '').toString();
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
    final email = _emailController.text.trim();

    if (nome.isEmpty || email.isEmpty) {
      _mostrarMensagem('Preencha o nome e o e-mail.');
      return;
    }

    setState(() => _salvando = true);

    try {
      await ApiService.put('usuarios/${widget.idUsuario}/perfil', {
        'nm_usuario': nome,
        'ds_email': email,
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
      await ApiService.delete('usuarios/${widget.idUsuario}');

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Conta excluída.')));
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Login()),
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
                onPressed: _carregarUsuario,
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
              'Meu Perfil',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
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
            const SizedBox(height: 24),
            if (_salvando)
              const Center(child: CircularProgressIndicator())
            else ...[
              BotaoPrimario(texto: 'Salvar Alterações', onPressed: _salvar),
              const SizedBox(height: 32),
              BotaoExcluirConta(
                mensagem:
                    'Sua conta, seus favoritos e suas avaliações serão removidos. '
                    'Esta ação não pode ser desfeita.',
                onConfirmar: _excluirConta,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
