import 'package:flutter/material.dart';
import 'package:achei_barato/telas/buscar.dart';
import 'package:achei_barato/telas/favoritos.dart';
import 'package:achei_barato/telas/home_usuario.dart';

class BottomNavUsuarios extends StatelessWidget {
  final int indiceAtual;
  final int idUsuario;
  final String nomeUsuario;

  const BottomNavUsuarios({
    super.key,
    required this.indiceAtual,
    required this.idUsuario,
    required this.nomeUsuario,
  });

  void _aoTocar(BuildContext context, int indice) {
    if (indice == indiceAtual) return;

    switch (indice) {
      case 0:
        _trocarTela(
          context,
          HomeUsuario(idUsuario: idUsuario, nomeUsuario: nomeUsuario),
        );
        break;
      case 1:
        _trocarTela(
          context,
          Buscar(idUsuario: idUsuario, nomeUsuario: nomeUsuario),
        );
        break;
      case 2:
        _trocarTela(
          context,
          Favoritos(idUsuario: idUsuario, nomeUsuario: nomeUsuario),
        );
        break;
      case 3:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Pedidos será uma funcionalidade futura do Achei Barato.',
            ),
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tela ainda não implementada.')),
        );
    }
  }

  void _trocarTela(BuildContext context, Widget tela) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => tela,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: indiceAtual,
      selectedItemColor: Colors.red,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      onTap: (i) => _aoTocar(context, i),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Início',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_outline),
          activeIcon: Icon(Icons.favorite),
          label: 'Favoritos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart_outlined),
          activeIcon: Icon(Icons.shopping_cart),
          label: 'Pedidos',
        ),
      ],
    );
  }
}
