import 'package:flutter/material.dart';
import 'package:achei_barato/services/notificacao_service.dart';

class SinoNotificacoes extends StatelessWidget {
  const SinoNotificacoes({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificacaoService.naoLidas,
      builder: (_, quantidade, _) => IconButton(
        tooltip: 'Notificações',
        onPressed: NotificacaoService.abrirTela,
        icon: Badge(
          isLabelVisible: quantidade > 0,
          label: Text(quantidade > 99 ? '99+' : '$quantidade'),
          backgroundColor: Colors.amber,
          textColor: Colors.black,
          child: const Icon(Icons.notifications_outlined, color: Colors.white),
        ),
      ),
    );
  }
}
