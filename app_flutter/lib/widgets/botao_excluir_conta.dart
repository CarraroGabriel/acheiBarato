import 'package:flutter/material.dart';

class BotaoExcluirConta extends StatelessWidget {
  final String mensagem;
  final Future<void> Function() onConfirmar;

  const BotaoExcluirConta({
    super.key,
    required this.mensagem,
    required this.onConfirmar,
  });

  Future<void> _confirmar(BuildContext context) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir conta?'),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmou == true) await onConfirmar();
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _confirmar(context),
      icon: const Icon(Icons.delete_forever, color: Colors.red),
      label: const Text('Excluir conta', style: TextStyle(color: Colors.red)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: Colors.red),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
