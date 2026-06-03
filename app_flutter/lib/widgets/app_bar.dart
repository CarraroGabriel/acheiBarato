import 'package:flutter/material.dart';

class AcheiBaratoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool exibirBotaoVoltar;

  const AcheiBaratoAppBar({
    super.key,
    this.exibirBotaoVoltar = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: exibirBotaoVoltar
          ? IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      )
          : null,
      title: const Text('Achei Barato'),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: Colors.red,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}