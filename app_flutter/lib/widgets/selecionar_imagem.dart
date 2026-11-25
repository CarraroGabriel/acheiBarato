import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SelecionarImagem {
  static Future<XFile?> escolher(BuildContext context) async {
    final origem = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (contextoSheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Colors.red),
              title: const Text('Tirar foto'),
              onTap: () => Navigator.pop(contextoSheet, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.red),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(contextoSheet, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (origem == null) return null;

    try {
      return await ImagePicker().pickImage(
        source: origem,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              origem == ImageSource.camera
                  ? 'Não foi possível abrir a câmera.'
                  : 'Não foi possível abrir a galeria.',
            ),
          ),
        );
      }
      return null;
    }
  }
}
