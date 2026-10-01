import 'package:flutter/material.dart';

class FaixaHorario {
  TimeOfDay abertura;
  TimeOfDay fechamento;

  FaixaHorario({required this.abertura, required this.fechamento});
}

class EditorHorarios extends StatelessWidget {
  final Map<int, List<FaixaHorario>> horarios;
  final VoidCallback onAlterado;

  const EditorHorarios({
    super.key,
    required this.horarios,
    required this.onAlterado,
  });

  // nu_dia_semana: 0 = domingo ... 6 = sábado (mesma convenção do banco).
  static const Map<int, String> diasSemana = {
    1: 'Segunda',
    2: 'Terça',
    3: 'Quarta',
    4: 'Quinta',
    5: 'Sexta',
    6: 'Sábado',
    0: 'Domingo',
  };

  static Map<int, List<FaixaHorario>> lerDaApi(dynamic lista) {
    final horarios = <int, List<FaixaHorario>>{};
    if (lista is! List) return horarios;

    for (final item in lista.whereType<Map>()) {
      final dia = int.tryParse(item['nu_dia_semana'].toString());
      final abertura = _lerHora(item['hr_abertura']);
      final fechamento = _lerHora(item['hr_fechamento']);

      if (dia == null || abertura == null || fechamento == null) continue;

      horarios
          .putIfAbsent(dia, () => [])
          .add(FaixaHorario(abertura: abertura, fechamento: fechamento));
    }

    return horarios;
  }

  static List<Map<String, dynamic>> paraApi(
    Map<int, List<FaixaHorario>> horarios,
  ) {
    return [
      for (final dia in horarios.entries)
        for (final faixa in dia.value)
          {
            'nu_dia_semana': dia.key,
            'hr_abertura': formatar(faixa.abertura),
            'hr_fechamento': formatar(faixa.fechamento),
          },
    ];
  }

  static String? validar(Map<int, List<FaixaHorario>> horarios) {
    for (final dia in diasSemana.entries) {
      for (final faixa in horarios[dia.key] ?? <FaixaHorario>[]) {
        if (_minutos(faixa.fechamento) <= _minutos(faixa.abertura)) {
          return '${dia.value}: o fechamento deve ser depois da abertura.';
        }
      }
    }
    return null;
  }

  static String formatar(TimeOfDay hora) =>
      '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';

  static TimeOfDay? _lerHora(dynamic valor) {
    final partes = (valor ?? '').toString().split(':');
    if (partes.length < 2) return null;

    final hora = int.tryParse(partes[0]);
    final minuto = int.tryParse(partes[1]);
    if (hora == null || minuto == null) return null;

    return TimeOfDay(hour: hora, minute: minuto);
  }

  static int _minutos(TimeOfDay hora) => hora.hour * 60 + hora.minute;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: diasSemana.entries
          .map((dia) => _buildDia(context, dia.key, dia.value))
          .toList(),
    );
  }

  Widget _buildDia(BuildContext context, int dia, String nome) {
    final faixas = horarios[dia] ?? [];
    final aberto = faixas.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  nome,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                aberto ? 'Aberto' : 'Fechado',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Switch(
                value: aberto,
                activeThumbColor: Colors.green,
                onChanged: (valor) {
                  horarios[dia] = valor
                      ? [
                          FaixaHorario(
                            abertura: const TimeOfDay(hour: 8, minute: 0),
                            fechamento: const TimeOfDay(hour: 18, minute: 0),
                          ),
                        ]
                      : [];
                  onAlterado();
                },
              ),
            ],
          ),
          if (aberto) ...[
            for (var i = 0; i < faixas.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    _botaoHora(context, faixas[i].abertura, (hora) {
                      faixas[i].abertura = hora;
                      onAlterado();
                    }),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('às'),
                    ),
                    _botaoHora(context, faixas[i].fechamento, (hora) {
                      faixas[i].fechamento = hora;
                      onAlterado();
                    }),
                    if (faixas.length > 1)
                      IconButton(
                        tooltip: 'Remover horário',
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          faixas.removeAt(i);
                          onAlterado();
                        },
                      ),
                  ],
                ),
              ),
            TextButton.icon(
              onPressed: () {
                final ultima = faixas.last.fechamento;
                faixas.add(
                  FaixaHorario(
                    abertura: ultima,
                    fechamento: TimeOfDay(
                      hour: ultima.hour + 4 > 23 ? 23 : ultima.hour + 4,
                      minute: ultima.hour + 4 > 23 ? 59 : ultima.minute,
                    ),
                  ),
                );
                onAlterado();
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Adicionar outro horário'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _botaoHora(
    BuildContext context,
    TimeOfDay hora,
    ValueChanged<TimeOfDay> onEscolher,
  ) {
    return OutlinedButton(
      onPressed: () async {
        final escolhida = await showTimePicker(
          context: context,
          initialTime: hora,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
        if (escolhida != null) onEscolher(escolhida);
      },
      child: Text(formatar(hora)),
    );
  }
}
