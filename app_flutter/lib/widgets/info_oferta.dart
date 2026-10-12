import 'package:flutter/material.dart';

// Distância do mercado: ícone vermelho e texto preto (padrão do app).
class TextoDistancia extends StatelessWidget {
  final String texto;
  final double tamanhoFonte;

  const TextoDistancia(this.texto, {super.key, this.tamanhoFonte = 13});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on, size: tamanhoFonte + 3, color: Colors.red),
        const SizedBox(width: 3),
        Text(
          texto,
          style: TextStyle(fontSize: tamanhoFonte, color: Colors.black87),
        ),
      ],
    );
  }
}

// "Atualizado hoje, 14h" a partir do dt_atualizacao da oferta.
class TextoAtualizacao extends StatelessWidget {
  final dynamic data;
  final double tamanhoFonte;

  const TextoAtualizacao(this.data, {super.key, this.tamanhoFonte = 13});

  // "hoje, 14h", "ontem, 18h30", "10/10, 9h" ou "10/10/2025".
  // Registros antigos (só data, sem hora) aparecem sem o horário.
  static String? formatar(dynamic valor) {
    final data = DateTime.tryParse('${valor ?? ''}')?.toLocal();
    if (data == null) return null;

    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final diasAtras = hoje
        .difference(DateTime(data.year, data.month, data.day))
        .inDays;

    String doisDigitos(int v) => v.toString().padLeft(2, '0');
    final semHora = data.hour == 0 && data.minute == 0;
    final hora = data.minute == 0
        ? '${data.hour}h'
        : '${data.hour}h${doisDigitos(data.minute)}';

    final String quando;
    if (diasAtras == 0) {
      quando = 'hoje';
    } else if (diasAtras == 1) {
      quando = 'ontem';
    } else if (data.year == agora.year) {
      quando = '${doisDigitos(data.day)}/${doisDigitos(data.month)}';
    } else {
      return '${doisDigitos(data.day)}/${doisDigitos(data.month)}/${data.year}';
    }

    return semHora ? quando : '$quando, $hora';
  }

  @override
  Widget build(BuildContext context) {
    final texto = formatar(data);
    if (texto == null) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.schedule,
          size: tamanhoFonte + 3,
          color: Colors.grey.shade700,
        ),
        const SizedBox(width: 3),
        Text(
          'Atualizado $texto',
          style: TextStyle(fontSize: tamanhoFonte, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}
