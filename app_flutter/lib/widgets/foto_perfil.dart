import 'package:flutter/material.dart';

class FotoPerfil extends StatelessWidget {
  final String? urlAtual;
  final IconData iconePadrao;

  const FotoPerfil({
    super.key,
    required this.urlAtual,
    required this.iconePadrao,
  });

  void _avisarEmDesenvolvimento(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Upload de foto será integrado em uma etapa específica.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final temFoto = urlAtual != null && urlAtual!.isNotEmpty;

    return Column(
      children: [
        GestureDetector(
          onTap: () => _avisarEmDesenvolvimento(context),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: temFoto ? NetworkImage(urlAtual!) : null,
            child: temFoto
                ? null
                : Icon(iconePadrao, size: 50, color: Colors.grey),
          ),
        ),
        TextButton.icon(
          onPressed: () => _avisarEmDesenvolvimento(context),
          icon: const Icon(Icons.photo_camera, color: Colors.red),
          label: const Text(
            'Alterar foto',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}
