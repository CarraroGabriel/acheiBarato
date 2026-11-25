import 'package:flutter/material.dart';

class AcheiBaratoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool exibirBotaoVoltar;
  final bool exibirMenu;
  final List<Widget> acoes;

  const AcheiBaratoAppBar({
    super.key,
    this.exibirBotaoVoltar = true,
    this.exibirMenu        = false,
    this.acoes             = const [],
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: exibirMenu
          ? Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      )
          : exibirBotaoVoltar
          ? IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      )
          : null,

      title: const Text('Achei Barato'),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      centerTitle: true,
      backgroundColor: Colors.red,
      actions: acoes,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}