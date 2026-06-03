import 'package:flutter/material.dart';

class BotaoPrimario extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;
  final double paddingHorizontal;

  const BotaoPrimario({
    super.key,
    required this.texto,
    required this.onPressed,
    this.paddingHorizontal = 100,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: paddingHorizontal,
          vertical: 15,
        ),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      child: Text(texto),
    );
  }
}