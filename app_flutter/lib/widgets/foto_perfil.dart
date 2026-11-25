import 'package:flutter/material.dart';
import 'package:achei_barato/widgets/imagem_app.dart';

class FotoPerfil extends StatelessWidget {
  final String? caminho;
  final IconData iconePadrao;
  final bool enviando;
  final VoidCallback? onAlterar;

  const FotoPerfil({
    super.key,
    required this.caminho,
    required this.iconePadrao,
    this.enviando = false,
    this.onAlterar,
  });

  @override
  Widget build(BuildContext context) {
    final podeAlterar = onAlterar != null && !enviando;

    return Column(
      children: [
        GestureDetector(
          onTap: podeAlterar ? onAlterar : null,
          child: SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              children: [
                ClipOval(
                  child: ImagemApp(
                    caminhos: [caminho],
                    iconePadrao: iconePadrao,
                    tamanhoIcone: 50,
                  ),
                ),
                if (enviando)
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (onAlterar != null)
          TextButton.icon(
            onPressed: podeAlterar ? onAlterar : null,
            icon: const Icon(Icons.photo_camera, color: Colors.red),
            label: Text(
              enviando ? 'Enviando foto...' : 'Alterar foto',
              style: const TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }
}
