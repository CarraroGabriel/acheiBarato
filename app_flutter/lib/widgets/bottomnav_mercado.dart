import 'package:flutter/material.dart';
import 'package:achei_barato/telas/home_mercado.dart';
import 'package:achei_barato/telas/produtos_mercado.dart';

class BottomNavMercado extends StatelessWidget {
  final int indiceAtual;
  final int idMercado;
  final String nomeMercado;

  const BottomNavMercado({
    super.key,
    required this.indiceAtual,
    required this.idMercado,
    required this.nomeMercado,
  });

  static void abrirInicio(
    BuildContext context, {
    required int idMercado,
    required String nomeMercado,
  }) {
    _trocarTela(
      context,
      HomeMercado(idMercado: idMercado, nomeMercado: nomeMercado),
    );
  }

  static void abrirProdutos(
    BuildContext context, {
    required int idMercado,
    required String nomeMercado,
    FiltroProdutos filtro = FiltroProdutos.todos,
  }) {
    _trocarTela(
      context,
      ProdutosMercado(
        idMercado: idMercado,
        nomeMercado: nomeMercado,
        filtroInicial: filtro,
      ),
    );
  }

  static void _trocarTela(BuildContext context, Widget tela) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => tela,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _aoTocar(BuildContext context, int indice) {
    if (indice == indiceAtual) return;

    if (indice == 0) {
      abrirInicio(context, idMercado: idMercado, nomeMercado: nomeMercado);
    } else {
      abrirProdutos(context, idMercado: idMercado, nomeMercado: nomeMercado);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: indiceAtual,
      selectedItemColor: Colors.red,
      unselectedItemColor: Colors.grey,
      onTap: (i) => _aoTocar(context, i),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          activeIcon: Icon(Icons.inventory_2),
          label: 'Produtos',
        ),
      ],
    );
  }
}
