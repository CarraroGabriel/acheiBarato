import 'package:flutter/material.dart';
import 'package:achei_barato/telas/login.dart';
import 'package:achei_barato/widgets/botao_primario.dart';
import 'package:achei_barato/widgets/tela_base.dart';

class CadastroUsuario extends StatelessWidget {
  const CadastroUsuario({super.key});

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      children: [
        const Text(
          'Faça seu Cadastro',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Nome e Sobrenome',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(
            labelText: 'CPF',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.fingerprint),
          ),
        ),
        const SizedBox(height: 16),
        const TextField(
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
        ),
        const SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Data de Nascimento',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.calendar_today),
          ),
        ),
        const SizedBox(height: 16),
        const TextField(
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Senha',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock),
          ),
        ),
        const SizedBox(height: 16),
        const TextField(
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Confirme a Senha',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock),
          ),
        ),
        const SizedBox(height: 16),
        BotaoPrimario(
          texto: 'Cadastrar-se',
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const Login(isUsuario: true),
              ),
            );
          },
        ),
      ],
    );
  }
}