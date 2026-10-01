import 'package:flutter/material.dart';
import 'package:achei_barato/telas/login.dart';

class MenuLateral extends StatelessWidget {
  final String nome;
  final bool isUsuario;

  const MenuLateral({super.key, required this.nome, this.isUsuario = true});

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
