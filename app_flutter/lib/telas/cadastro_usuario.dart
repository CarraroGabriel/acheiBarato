import 'package:flutter/material.dart';
import 'package:achei_barato/services/api_service.dart';
import 'package:achei_barato/telas/login.dart';
import 'package:achei_barato/widgets/botao_primario.dart';
import 'package:achei_barato/widgets/tela_base.dart';

class CadastroUsuario extends StatefulWidget {
  const CadastroUsuario({super.key});

  @override
  State<CadastroUsuario> createState() => _CadastroUsuarioState();
}

class _CadastroUsuarioState extends State<CadastroUsuario> {
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _nascimentoController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _carregando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _nascimentoController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDate: DateTime(2000),
    );

    if (data == null) return;

    final ano = data.year.toString().padLeft(4, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final dia = data.day.toString().padLeft(2, '0');
    _nascimentoController.text = '$ano-$mes-$dia';
  }

  Future<void> _cadastrar() async {
    if (_senhaController.text != _confirmarSenhaController.text) {
      _mostrarMensagem('As senhas não coincidem.');
      return;
    }

    setState(() => _carregando = true);

    try {
      await ApiService.post('usuarios', {
        'nu_cpf': _cpfController.text,
        'nm_usuario': _nomeController.text.trim(),
        'ds_email': _emailController.text.trim(),
        'dt_nascimento': _nascimentoController.text,
        'ds_senha': _senhaController.text,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário cadastrado com sucesso.')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const Login(isUsuario: true),
        ),
      );
    } on ApiException catch (e) {
      _mostrarMensagem(e.mensagem);
    } catch (_) {
      _mostrarMensagem('Não foi possível conectar ao servidor.');
    } finally {
      if (mounted) setState(() => _carregando = false);
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
    return TelaBase(
      children: [
        const Text(
          'Faça seu Cadastro',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nomeController,
          decoration: const InputDecoration(
            labelText: 'Nome e Sobrenome',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _cpfController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'CPF',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.fingerprint),
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
          controller: _nascimentoController,
          readOnly: true,
          onTap: _selecionarData,
          decoration: const InputDecoration(
            labelText: 'Data de Nascimento',
            hintText: 'AAAA-MM-DD',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.calendar_today),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _senhaController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Senha',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmarSenhaController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Confirme a Senha',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock),
          ),
        ),
        const SizedBox(height: 16),
        if (_carregando)
          const CircularProgressIndicator()
        else
          BotaoPrimario(
            texto: 'Cadastrar-se',
            onPressed: _cadastrar,
          ),
      ],
    );
  }
}
