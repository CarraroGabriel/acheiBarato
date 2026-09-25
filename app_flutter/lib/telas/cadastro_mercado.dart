import 'package:flutter/material.dart';
import 'package:achei_barato/services/api_service.dart';
import 'package:achei_barato/telas/login.dart';
import 'package:achei_barato/widgets/botao_primario.dart';
import 'package:achei_barato/widgets/tela_base.dart';

class CadastroMercado extends StatefulWidget {
  const CadastroMercado({super.key});

  @override
  State<CadastroMercado> createState() => _CadastroMercadoState();
}

class _CadastroMercadoState extends State<CadastroMercado> {
  final _nomeController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _emailController = TextEditingController();
  final _cepController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _carregando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _cnpjController.dispose();
    _emailController.dispose();
    _cepController.dispose();
    _enderecoController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (_senhaController.text != _confirmarSenhaController.text) {
      _mostrarMensagem('As senhas não coincidem.');
      return;
    }

    setState(() => _carregando = true);

    try {
      await ApiService.post('mercados', {
        'nu_cnpj': _cnpjController.text,
        'nm_mercado': _nomeController.text.trim(),
        'ds_email': _emailController.text.trim(),
        'nu_cep': _cepController.text,
        'nm_endereco': _enderecoController.text.trim(),
        'ds_senha': _senhaController.text,

        // Esses campos existem no ER, mas ainda não possuem campos na tela.
        'fl_motoboy': false,
        'ds_foto_mercado': '',
        'nu_latitude': 0,
        'nu_longitude': 0,
        'nu_avg_nota': 0,
        'nul_avaliacoes': 0,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mercado cadastrado com sucesso.')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const Login(isUsuario: false),
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
            labelText: 'Nome do Mercado',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _cnpjController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'CNPJ',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
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
