import 'package:flutter/material.dart';
import 'package:achei_barato/widgets/app_bar.dart';

class TelaBase extends StatelessWidget {
  final List<Widget> children;
  final bool exibirBotaoVoltar;

  const TelaBase({
    super.key,
    required this.children,
    this.exibirBotaoVoltar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AcheiBaratoAppBar(exibirBotaoVoltar: exibirBotaoVoltar),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}