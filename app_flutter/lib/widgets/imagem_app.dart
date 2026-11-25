import 'package:flutter/material.dart';
import 'package:achei_barato/config/api_config.dart';

class ImagemApp extends StatelessWidget {
  final List<dynamic> caminhos;
  final IconData iconePadrao;
  final double tamanhoIcone;
  final BoxFit fit;

  const ImagemApp({
    super.key,
    required this.caminhos,
    this.iconePadrao = Icons.image,
    this.tamanhoIcone = 30,
    this.fit = BoxFit.cover,
  });

  factory ImagemApp.produto(
    Map<String, dynamic> produto, {
    double tamanhoIcone = 30,
    BoxFit fit = BoxFit.cover,
  }) {
    return ImagemApp(
      caminhos: [produto['ds_foto_produto'], produto['ds_imagem_padrao']],
      tamanhoIcone: tamanhoIcone,
      fit: fit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final validos = caminhos
        .map((c) => (c ?? '').toString().trim())
        .where((c) => c.isNotEmpty)
        .toList();

    return SizedBox.expand(child: _construir(validos, 0));
  }

  Widget _construir(List<String> validos, int indice) {
    if (indice >= validos.length) {
      return Container(
        color: Colors.grey.shade200,
        child: Icon(iconePadrao, color: Colors.grey, size: tamanhoIcone),
      );
    }

    final caminho = validos[indice];
    Widget proxima(BuildContext _, Object _, StackTrace? _) =>
        _construir(validos, indice + 1);

    if (caminho.startsWith('asset:')) {
      return Image.asset(
        'assets/${caminho.substring('asset:'.length)}',
        fit: fit,
        errorBuilder: proxima,
      );
    }

    return Image.network(
      ApiConfig.urlArquivo(caminho),
      fit: fit,
      errorBuilder: proxima,
      loadingBuilder: (_, imagem, progresso) => progresso == null
          ? imagem
          : Container(
              color: Colors.grey.shade200,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
    );
  }
}
