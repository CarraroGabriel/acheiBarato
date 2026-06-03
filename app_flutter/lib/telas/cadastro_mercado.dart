import 'package:flutter/material.dart';
import 'package:achei_barato/telas/login.dart';
import 'package:achei_barato/widgets/botao_primario.dart';
import 'package:achei_barato/widgets/tela_base.dart';

class CadastroMercado extends StatelessWidget {
  const CadastroMercado({super.key});

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
            labelText: 'Nome do Mercado',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(
            labelText: 'CNPJ',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
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
            labelText: 'CEP',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
        ),
        const SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Endereço',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.map),
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
                builder: (context) => const Login(isUsuario: false),
              ),
            );
          },
        ),
      ],
    );
  }
}