import 'package:flutter/material.dart';
import 'package:achei_barato/telas/editar_mercado.dart';
import 'package:achei_barato/telas/editar_usuario.dart';
import 'package:achei_barato/telas/login.dart';

class MenuLateral extends StatelessWidget {
  final String nome;
  final bool isUsuario;
  final int id;
  final ValueChanged<String>? aoAlterarPerfil;

  const MenuLateral({
    super.key,
    required this.nome,
    required this.id,
    this.isUsuario = true,
    this.aoAlterarPerfil,
  });

  Future<void> _abrirPerfil(BuildContext context) async {
    final navigator = Navigator.of(context);
    navigator.pop();

    final novoNome = await navigator.push<String>(
      MaterialPageRoute(
        builder: (_) => isUsuario
            ? EditarUsuario(idUsuario: id)
            : EditarMercado(idMercado: id),
      ),
    );

    if (novoNome != null) aoAlterarPerfil?.call(novoNome);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.red),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(
                    isUsuario ? Icons.person : Icons.store,
                    color: Colors.red,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Olá, $nome!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Perfil'),
            onTap: () => _abrirPerfil(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Configurações'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Ajuda'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sair', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => Login(isUsuario: isUsuario)),
                (_) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
