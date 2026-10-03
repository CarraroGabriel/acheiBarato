import 'package:flutter/material.dart';
import 'package:achei_barato/services/api_service.dart';
import 'package:achei_barato/telas/cadastro_mercado.dart';
import 'package:achei_barato/telas/cadastro_usuario.dart';
import 'package:achei_barato/telas/home_mercado.dart';
import 'package:achei_barato/telas/home_usuario.dart';
import 'package:achei_barato/widgets/botao_primario.dart';
import 'package:achei_barato/widgets/tela_base.dart';

class Login extends StatefulWidget {
  final bool isUsuario;

  const Login({super.key, this.isUsuario = true});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  late bool _isUsuario;
  final _identificadorController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _isUsuario = widget.isUsuario;
  }

  @override
  void dispose() {
    _identificadorController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    final identificador = _identificadorController.text.trim();
    final senha = _senhaController.text;

    if (identificador.isEmpty || senha.isEmpty) {
      _mostrarMensagem('Preencha o identificador e a senha.');
      return;
    }

    setState(() => _carregando = true);

    try {
      final resposta = await ApiService.post('login', {
        'tipo': _isUsuario ? 'usuario' : 'mercado',
        'identificador': identificador,
        'ds_senha': senha,
      });

      if (!mounted) return;

      final dados = Map<String, dynamic>.from(resposta['dados'] as Map);

      if (_isUsuario) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => HomeUsuario(
              idUsuario: _toInt(dados['id_usuario']),
              nomeUsuario: (dados['nm_usuario'] ?? 'Usuário').toString(),
            ),
          ),
          (_) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => HomeMercado(
              idMercado: _toInt(dados['id_mercado']),
              nomeMercado: (dados['nm_mercado'] ?? 'Mercado').toString(),
            ),
          ),
          (_) => false,
        );
      }
    } on ApiException catch (e) {
      _mostrarMensagem(e.mensagem);
    } catch (_) {
      _mostrarMensagem('Não foi possível conectar ao servidor.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  int _toInt(dynamic valor) => int.tryParse(valor.toString()) ?? 0;

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  void _trocarTipo(bool usuario) {
    setState(() {
      _isUsuario = usuario;
      _identificadorController.clear();
      _senhaController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      exibirBotaoVoltar: false,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleButton(
                  label: 'Usuário',
                  icon: Icons.person,
                  isSelected: _isUsuario,
                  onTap: () => _trocarTipo(true),
                ),
                _buildToggleButton(
                  label: 'Mercado',
                  icon: Icons.store,
                  isSelected: !_isUsuario,
                  onTap: () => _trocarTipo(false),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Faça seu Login',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _identificadorController,
                keyboardType: _isUsuario
                    ? TextInputType.emailAddress
                    : TextInputType.number,
                decoration: InputDecoration(
                  labelText: _isUsuario ? 'Email' : 'CNPJ',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(_isUsuario ? Icons.email : Icons.business),
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
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_carregando)
          const CircularProgressIndicator()
        else
          BotaoPrimario(
            texto: 'Entrar',
            onPressed: _entrar,
            paddingHorizontal: 150,
          ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            _mostrarMensagem('Recuperação de senha ainda não implementada.');
          },
          style: TextButton.styleFrom(foregroundColor: Colors.black),
          child: const Text('Esqueceu a senha?'),
        ),
        const SizedBox(height: 16),
        const Text('Não possui login?'),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CadastroUsuario()),
                );
              },
              child: const Text(
                'Cadastre-se como cliente',
                style: TextStyle(fontSize: 12),
              ),
            ),
            const Text('ou'),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CadastroMercado()),
                );
              },
              child: const Text(
                'Cadastre-se como mercado',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
