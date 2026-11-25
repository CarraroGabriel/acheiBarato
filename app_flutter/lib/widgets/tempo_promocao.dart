import 'dart:async';

import 'package:flutter/material.dart';

class TempoPromocao extends StatefulWidget {
  final dynamic segundosRestantes;
  final double tamanhoFonte;

  const TempoPromocao({
    super.key,
    required this.segundosRestantes,
    this.tamanhoFonte = 11,
  });

  @override
  State<TempoPromocao> createState() => _TempoPromocaoState();
}

class _TempoPromocaoState extends State<TempoPromocao> {
  DateTime? _fim;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  @override
  void didUpdateWidget(TempoPromocao antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.segundosRestantes != widget.segundosRestantes) _iniciar();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _iniciar() {
    _timer?.cancel();
    final segundos = int.tryParse((widget.segundosRestantes ?? '').toString());
    _fim = segundos == null
        ? null
        : DateTime.now().add(Duration(seconds: segundos));

    if (_fim != null) {
      _timer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fim == null) return const SizedBox.shrink();

    final restante = _fim!.difference(DateTime.now());
    final ultimaHora = restante.inMinutes < 60;
    final encerrada = restante.inSeconds <= 0;

    final String texto;
    if (encerrada) {
      texto = 'Promoção encerrada';
      _timer?.cancel();
    } else if (restante.inDays >= 1) {
      texto =
          'Termina em ${restante.inDays} ${restante.inDays == 1 ? 'dia' : 'dias'}';
    } else if (!ultimaHora) {
      final minutos = restante.inMinutes % 60;
      texto =
          'Termina em ${restante.inHours}h ${minutos.toString().padLeft(2, '0')}min';
    } else {
      final minutos = (restante.inSeconds / 60).ceil();
      texto = 'Termina em ${minutos}min';
    }

    final cor = encerrada
        ? Colors.grey
        : ultimaHora
        ? Colors.red
        : Colors.red.shade700;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined, size: widget.tamanhoFonte + 2, color: cor),
        const SizedBox(width: 3),
        Text(
          texto,
          style: TextStyle(
            fontSize: widget.tamanhoFonte,
            color: cor,
            fontWeight: ultimaHora && !encerrada
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
